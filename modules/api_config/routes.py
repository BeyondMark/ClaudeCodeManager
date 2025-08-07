from fastapi import APIRouter, HTTPException, Depends
from typing import List
from .manager import ApiConfigManager
from .models import (
    ApiConfigProfile, 
    CreateApiConfigRequest, 
    UpdateApiConfigRequest,
    ApiConfigListResponse,
    ApplyConfigResponse,
    CurrentApiConfigResponse,
    StatusResponse
)

router = APIRouter(prefix="/api/v1/api-config", tags=["API Configuration"])

def get_api_config_manager() -> ApiConfigManager:
    """依赖注入：获取配置管理器实例"""
    return ApiConfigManager()

@router.get("/profiles", response_model=ApiConfigListResponse, summary="获取所有API配置")
async def get_api_profiles(manager: ApiConfigManager = Depends(get_api_config_manager)):
    """获取所有API配置项列表"""
    try:
        profiles = manager.get_all_profiles()
        active_id = manager.get_active_profile_id()
        
        return ApiConfigListResponse(
            profiles=profiles,
            active_profile_id=active_id,
            total_count=len(profiles)
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取配置列表失败: {str(e)}")

@router.post("/profiles", response_model=ApiConfigProfile, summary="创建新API配置")
async def create_api_profile(
    request: CreateApiConfigRequest,
    manager: ApiConfigManager = Depends(get_api_config_manager)
):
    """创建新的API配置项"""
    try:
        profile = manager.add_profile(request)
        return profile
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        import traceback
        error_details = traceback.format_exc()
        print(f"创建配置时出错: {error_details}")
        raise HTTPException(status_code=500, detail=f"创建配置失败: {str(e)}")

@router.put("/profiles/{profile_id}", response_model=dict, summary="更新API配置")
async def update_api_profile(
    profile_id: str,
    request: UpdateApiConfigRequest,
    manager: ApiConfigManager = Depends(get_api_config_manager)
):
    """更新指定的API配置项"""
    try:
        success = manager.update_profile(profile_id, request)
        if not success:
            raise HTTPException(status_code=404, detail="配置项不存在")
        
        return {"success": True, "message": "配置更新成功"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"更新配置失败: {str(e)}")

@router.delete("/profiles/{profile_id}", response_model=dict, summary="删除API配置")
async def delete_api_profile(
    profile_id: str,
    manager: ApiConfigManager = Depends(get_api_config_manager)
):
    """删除指定的API配置项"""
    try:
        success = manager.delete_profile(profile_id)
        if not success:
            raise HTTPException(status_code=404, detail="配置项不存在")
        
        return {"success": True, "message": "配置删除成功"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"删除配置失败: {str(e)}")

@router.post("/profiles/{profile_id}/apply", response_model=ApplyConfigResponse, summary="激活API配置")
async def apply_api_profile(
    profile_id: str,
    manager: ApiConfigManager = Depends(get_api_config_manager)
):
    """激活指定的API配置，将其应用到Claude Code"""
    try:
        # 获取配置详情
        profiles = manager.get_all_profiles()
        target_profile = None
        for profile in profiles:
            if profile.id == profile_id:
                target_profile = profile
                break
        
        if not target_profile:
            raise HTTPException(status_code=404, detail="配置项不存在")
        
        # 激活配置
        success = manager.activate_profile(profile_id)
        if not success:
            raise HTTPException(status_code=500, detail="激活配置失败")
        
        return ApplyConfigResponse(
            success=True,
            message=f"配置 '{target_profile.name}' 已成功激活并应用到Claude Code",
            applied_profile=target_profile
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"激活配置失败: {str(e)}")

@router.get("/current", response_model=CurrentApiConfigResponse, summary="获取当前配置")
async def get_current_api_config(manager: ApiConfigManager = Depends(get_api_config_manager)):
    """获取当前Claude Code正在使用的API配置"""
    try:
        # 获取当前激活的配置项
        active_profile = manager.get_active_profile()
        
        # 获取Claude设置文件中的实际配置
        claude_config = manager.get_current_claude_config()
        
        return CurrentApiConfigResponse(
            api_key=claude_config["api_key"],
            base_url=claude_config["base_url"],
            profile_name=active_profile.name if active_profile else None,
            profile_id=active_profile.id if active_profile else None,
            source=claude_config["source"]
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取当前配置失败: {str(e)}")

@router.get("/status", response_model=StatusResponse, summary="获取服务状态")
async def get_service_status(manager: ApiConfigManager = Depends(get_api_config_manager)):
    """获取API配置服务状态"""
    try:
        profiles = manager.get_all_profiles()
        active_id = manager.get_active_profile_id()
        
        return StatusResponse(
            status="running",
            api_config_count=len(profiles),
            active_profile_id=active_id,
            claude_settings_exists=manager.claude_settings_path.exists()
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取状态失败: {str(e)}")

@router.post("/backup", response_model=dict, summary="备份配置")
async def backup_config(manager: ApiConfigManager = Depends(get_api_config_manager)):
    """备份当前API配置数据"""
    try:
        success = manager.backup_config()
        if not success:
            raise HTTPException(status_code=500, detail="备份失败")
        
        return {"success": True, "message": "配置备份成功"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"备份失败: {str(e)}")