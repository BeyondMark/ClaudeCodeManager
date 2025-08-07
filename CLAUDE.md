# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Development
```bash
# 启动后端服务器
cd backend && python main.py

# 启动前端开发服务器  
cd frontend && npm run dev

# 安装后端依赖
cd backend && pip install -r requirements.txt

# 安装前端依赖
cd frontend && npm install

# 运行特定测试
cd backend && python -m pytest tests/api_config/ -v

# 检查代码质量
cd backend && python -m flake8 modules/
cd backend && python -m mypy modules/
cd frontend && npm run lint
```

### API服务
```bash
# 启动API服务 (http://localhost:8000)
cd backend && python main.py

# 启动前端界面 (http://localhost:5173)
cd frontend && npm run dev

# 查看API文档
# Swagger: http://localhost:8000/docs
# ReDoc: http://localhost:8000/redoc

# 测试API健康状态
curl http://localhost:8000/health
```

## Architecture

这是一个Claude Code API配置管理系统，采用前后端分离架构：

### 后端架构 (`backend/`)
- **FastAPI应用** (`main.py`): 应用入口，路由注册，CORS配置
- **模块化设计** (`modules/`): 功能模块独立封装
- **数据持久化** (`data/`): JSON文件存储，原子性写入
- **线程安全**: 配置操作使用锁机制确保并发安全

### 前端架构 (`frontend/`)
- **Vue 3 + TypeScript**: 现代化前端框架，类型安全
- **Element Plus**: 企业级UI组件库
- **Pinia**: 轻量级状态管理
- **Axios**: HTTP客户端，API集成
- **Vite**: 快速构建工具

### API配置模块 (`backend/modules/api_config/`)
- **models.py**: Pydantic数据模型，包含完整的请求/响应模型定义
- **manager.py**: 核心业务逻辑，负责配置CRUD和Claude Code集成
- **routes.py**: FastAPI路由定义，8个REST端点实现

### 前端组件模块 (`frontend/src/`)
- **components/**: Vue组件库（ConfigCard, ConfigForm, StatusBar）
- **stores/**: Pinia状态管理（配置数据、操作状态）
- **services/**: API服务层（HTTP请求封装）
- **types/**: TypeScript类型定义
- **views/**: 页面组件（Dashboard主控制台）

### 关键设计模式
- **依赖注入**: `get_api_config_manager()` 提供管理器实例
- **原子性操作**: 配置文件写入使用临时文件 + 重命名机制
- **Claude集成**: 自动同步激活配置到 `~/.claude/settings.json`
- **错误处理**: 分层异常处理，HTTP状态码规范

### 数据流
1. API请求 → FastAPI路由 → 依赖注入 → ApiConfigManager
2. 业务逻辑 → 文件操作（带锁） → Claude设置同步
3. 响应模型验证 → JSON序列化 → 客户端

### 配置管理生命周期
- **创建**: 验证唯一性 → 生成UUID → 首个配置自动激活
- **激活**: 状态更新 → Claude配置同步 → 原子性保存
- **删除**: 检查激活状态 → 自动切换 → 数据清理

### 文件组织
- **配置数据**: `data/api_configs.json` (本地JSON存储)
- **Claude集成**: `~/.claude/settings.json` (自动同步)
- **备份机制**: 时间戳备份文件，防止数据丢失

### 重要约定
- 所有API密钥在响应中显示为 "sk-***" 保护隐私
- 配置名称必须唯一，创建时自动验证
- 激活配置的更新会同步到Claude Code
- 线程安全通过 `threading.Lock()` 实现
- 配置文件写入采用原子性操作防止数据损坏