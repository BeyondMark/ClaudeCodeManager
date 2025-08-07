from pydantic import BaseModel, Field, ConfigDict
from typing import List, Optional
from datetime import datetime
import uuid

class ApiConfigProfile(BaseModel):
    model_config = ConfigDict(json_encoders={datetime: lambda v: v.isoformat()})
    
    id: str = Field(default_factory=lambda: str(uuid.uuid4()), description="配置唯一标识")
    name: str = Field(..., min_length=1, max_length=50, description="API配置名称")
    api_key: str = Field(..., min_length=10, description="Anthropic API密钥")
    base_url: str = Field(..., pattern=r"https?://.*", description="API服务器地址")
    created_at: datetime = Field(default_factory=datetime.utcnow, description="创建时间")
    is_active: bool = Field(default=False, description="是否为当前激活配置")

class CreateApiConfigRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=50, description="配置名称")
    api_key: str = Field(..., min_length=10, description="API密钥")
    base_url: str = Field(..., pattern=r"https?://.*", description="API服务器地址")

class UpdateApiConfigRequest(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=50, description="配置名称")
    api_key: Optional[str] = Field(None, min_length=10, description="API密钥")
    base_url: Optional[str] = Field(None, pattern=r"https?://.*", description="API服务器地址")

class ApiConfigListResponse(BaseModel):
    profiles: List[ApiConfigProfile] = Field(..., description="配置项列表")
    active_profile_id: Optional[str] = Field(None, description="当前激活配置ID")
    total_count: int = Field(..., description="总配置数量")

class ApplyConfigResponse(BaseModel):
    success: bool = Field(..., description="操作是否成功")
    message: str = Field(..., description="操作结果消息")
    applied_profile: ApiConfigProfile = Field(..., description="已应用的配置")

class CurrentApiConfigResponse(BaseModel):
    api_key: str = Field(..., description="当前API密钥")
    base_url: str = Field(..., description="当前API服务器地址")
    profile_name: Optional[str] = Field(None, description="配置名称")
    profile_id: Optional[str] = Field(None, description="配置ID")
    source: str = Field(default="Claude Code settings.json", description="配置来源")

class StatusResponse(BaseModel):
    status: str = Field(default="running", description="服务状态")
    api_config_count: int = Field(..., description="API配置数量")
    active_profile_id: Optional[str] = Field(None, description="当前激活配置ID")
    claude_settings_exists: bool = Field(..., description="Claude设置文件是否存在")