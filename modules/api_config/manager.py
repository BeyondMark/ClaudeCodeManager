import threading
import json
from pathlib import Path
from typing import List, Optional, Dict
from datetime import datetime
import shutil
import uuid
from .models import ApiConfigProfile, CreateApiConfigRequest, UpdateApiConfigRequest

class ApiConfigManager:
    def __init__(self, 
                 config_file: str = "./data/api_configs.json",
                 claude_settings_path: str = "~/.claude/settings.json"):
        self.config_file = Path(config_file)
        self.claude_settings_path = Path(claude_settings_path).expanduser()
        self._lock = threading.Lock()
        self._ensure_data_dir()
        self._ensure_config_file()
    
    def _ensure_data_dir(self):
        """确保数据目录存在"""
        self.config_file.parent.mkdir(parents=True, exist_ok=True)
    
    def _ensure_config_file(self):
        """确保配置文件存在"""
        if not self.config_file.exists():
            initial_data = {
                "api_profiles": [],
                "metadata": {
                    "last_updated": datetime.utcnow().isoformat(),
                    "version": "1.0"
                }
            }
            self._write_config_data(initial_data)
    
    def _read_config_data(self) -> dict:
        """读取配置文件数据"""
        try:
            with open(self.config_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        except (json.JSONDecodeError, FileNotFoundError):
            return {
                "api_profiles": [],
                "metadata": {
                    "last_updated": datetime.utcnow().isoformat(),
                    "version": "1.0"
                }
            }
    
    def _write_config_data(self, data: dict) -> bool:
        """写入配置文件数据"""
        try:
            # 更新元数据
            data["metadata"]["last_updated"] = datetime.utcnow().isoformat()
            
            # 原子性写入
            temp_file = self.config_file.with_suffix('.tmp')
            with open(temp_file, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            
            # 移动到目标文件
            temp_file.replace(self.config_file)
            return True
        except Exception as e:
            print(f"写入配置文件失败: {e}")
            import traceback
            traceback.print_exc()
            return False
    
    def backup_config(self) -> bool:
        """备份配置文件"""
        try:
            backup_path = self.config_file.with_suffix(f'.bak.{int(datetime.utcnow().timestamp())}')
            shutil.copy2(self.config_file, backup_path)
            return True
        except Exception:
            return False
    
    # === API配置库管理 ===
    
    def get_all_profiles(self) -> List[ApiConfigProfile]:
        """获取所有API配置项"""
        with self._lock:
            data = self._read_config_data()
            profiles = []
            for profile_data in data.get("api_profiles", []):
                try:
                    profiles.append(ApiConfigProfile(**profile_data))
                except Exception:
                    continue  # 跳过无效的配置项
            return profiles
    
    def add_profile(self, profile_data: CreateApiConfigRequest) -> ApiConfigProfile:
        """添加新的API配置"""
        with self._lock:
            # 创建新配置项
            new_profile = ApiConfigProfile(
                name=profile_data.name,
                api_key=profile_data.api_key,
                base_url=profile_data.base_url,
                is_active=False
            )
            
            # 读取现有数据
            data = self._read_config_data()
            
            # 检查名称是否重复
            existing_names = [p.get("name") for p in data.get("api_profiles", [])]
            if new_profile.name in existing_names:
                raise ValueError(f"配置名称 '{new_profile.name}' 已存在")
            
            # 添加到配置列表
            profile_dict = new_profile.model_dump()
            # 确保datetime被序列化为字符串
            profile_dict["created_at"] = new_profile.created_at.isoformat()
            data.setdefault("api_profiles", []).append(profile_dict)
            
            # 如果是第一个配置，自动激活
            if len(data["api_profiles"]) == 1:
                new_profile.is_active = True
                data["api_profiles"][0]["is_active"] = True
                self._apply_profile_to_claude(new_profile)
            
            # 保存数据
            if self._write_config_data(data):
                return new_profile
            else:
                raise Exception("保存配置失败")
    
    def update_profile(self, profile_id: str, updates: UpdateApiConfigRequest) -> bool:
        """更新API配置项"""
        with self._lock:
            data = self._read_config_data()
            profiles = data.get("api_profiles", [])
            
            # 查找目标配置
            target_index = None
            for i, profile in enumerate(profiles):
                if profile.get("id") == profile_id:
                    target_index = i
                    break
            
            if target_index is None:
                return False
            
            # 应用更新
            target_profile = profiles[target_index]
            if updates.name is not None:
                target_profile["name"] = updates.name
            if updates.api_key is not None:
                target_profile["api_key"] = updates.api_key
            if updates.base_url is not None:
                target_profile["base_url"] = updates.base_url
            
            # 如果是当前激活配置，同时更新Claude设置
            if target_profile.get("is_active"):
                updated_profile = ApiConfigProfile(**target_profile)
                self._apply_profile_to_claude(updated_profile)
            
            return self._write_config_data(data)
    
    def delete_profile(self, profile_id: str) -> bool:
        """删除API配置项"""
        with self._lock:
            data = self._read_config_data()
            profiles = data.get("api_profiles", [])
            
            # 查找并删除目标配置
            original_count = len(profiles)
            was_active = False
            
            profiles_to_keep = []
            for profile in profiles:
                if profile.get("id") == profile_id:
                    was_active = profile.get("is_active", False)
                else:
                    profiles_to_keep.append(profile)
            
            if len(profiles_to_keep) == original_count:
                return False  # 没找到要删除的配置
            
            data["api_profiles"] = profiles_to_keep
            
            # 如果删除的是激活配置，需要处理
            if was_active and profiles_to_keep:
                # 激活第一个可用配置
                profiles_to_keep[0]["is_active"] = True
                first_profile = ApiConfigProfile(**profiles_to_keep[0])
                self._apply_profile_to_claude(first_profile)
            
            return self._write_config_data(data)
    
    # === 配置应用 ===
    
    def activate_profile(self, profile_id: str) -> bool:
        """激活指定API配置"""
        with self._lock:
            data = self._read_config_data()
            profiles = data.get("api_profiles", [])
            
            # 查找目标配置
            target_profile = None
            for profile in profiles:
                if profile.get("id") == profile_id:
                    target_profile = profile
                    break
            
            if not target_profile:
                return False
            
            # 更新激活状态
            for profile in profiles:
                profile["is_active"] = (profile.get("id") == profile_id)
            
            # 应用到Claude Code
            active_profile = ApiConfigProfile(**target_profile)
            success = self._apply_profile_to_claude(active_profile)
            
            if success:
                return self._write_config_data(data)
            else:
                return False
    
    def get_active_profile(self) -> Optional[ApiConfigProfile]:
        """获取当前激活的配置"""
        profiles = self.get_all_profiles()
        for profile in profiles:
            if profile.is_active:
                return profile
        return None
    
    def get_active_profile_id(self) -> Optional[str]:
        """获取当前激活配置ID"""
        active = self.get_active_profile()
        return active.id if active else None
    
    def _apply_profile_to_claude(self, profile: ApiConfigProfile) -> bool:
        """将配置应用到Claude Code的settings.json"""
        try:
            # 读取Claude设置文件
            if not self.claude_settings_path.exists():
                # 如果不存在，创建基本结构
                claude_config = {
                    "env": {},
                    "permissions": {"allow": [], "deny": []}
                }
            else:
                with open(self.claude_settings_path, 'r', encoding='utf-8') as f:
                    claude_config = json.load(f)
            
            # 更新环境变量
            if "env" not in claude_config:
                claude_config["env"] = {}
            
            claude_config["env"]["ANTHROPIC_API_KEY"] = profile.api_key
            claude_config["env"]["ANTHROPIC_BASE_URL"] = profile.base_url
            
            # 更新apiKeyHelper
            claude_config["apiKeyHelper"] = f"echo '{profile.api_key}'"
            
            # 原子性写入
            temp_file = self.claude_settings_path.with_suffix('.tmp')
            with open(temp_file, 'w', encoding='utf-8') as f:
                json.dump(claude_config, f, ensure_ascii=False, indent=2)
            
            temp_file.replace(self.claude_settings_path)
            return True
            
        except Exception:
            return False
    
    def get_current_claude_config(self) -> dict:
        """获取Claude Code当前使用的配置"""
        try:
            with open(self.claude_settings_path, 'r', encoding='utf-8') as f:
                claude_config = json.load(f)
                
            env = claude_config.get("env", {})
            return {
                "api_key": env.get("ANTHROPIC_API_KEY", ""),
                "base_url": env.get("ANTHROPIC_BASE_URL", ""),
                "source": "Claude Code settings.json"
            }
        except Exception:
            return {
                "api_key": "",
                "base_url": "",
                "source": "配置文件读取失败"
            }