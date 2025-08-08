from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn
from modules.api_config.routes import router as api_config_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    # 启动时初始化
    print("🚀 ClaudeCodeManager 启动中...")
    yield
    # 关闭时清理
    print("🛑 ClaudeCodeManager 正在关闭...")

# 创建FastAPI应用
app = FastAPI(
    title="ClaudeCodeManager",
    description="ClaudeCode API配置管理系统",
    version="1.0.0",
    lifespan=lifespan
)

# CORS配置
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 开发环境，生产环境需要限制
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 注册路由模块
app.include_router(api_config_router)

@app.get("/", summary="根路径")
async def root():
    """系统根路径，返回服务基本信息"""
    return {
        "service": "ClaudeCodeManager",
        "version": "1.0.0",
        "description": "ClaudeCode API配置管理系统",
        "status": "running",
        "endpoints": {
            "api_docs": "/docs",
            "api_config": "/api/v1/api-config"
        }
    }

@app.get("/health", summary="健康检查")
async def health_check():
    """服务健康检查接口"""
    return {"status": "healthy", "timestamp": "2025-08-07"}

if __name__ == "__main__":
    print("🔧 正在启动 ClaudeCodeManager...")
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=50000,
        reload=True,
        log_level="info"
    )