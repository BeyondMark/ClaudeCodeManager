# 端口更改说明文档

## 📋 更改概览

本文档记录了 ClaudeCodeManager 项目的端口配置更改详情。

### 端口更改
- **后端服务**: 8000 → **50000**
- **前端服务**: 5173 → **50001**

更改日期: 2025-08-08

---

## 🔄 更改详情

### 1. 后端配置更改

**文件**: `/backend/main.py`
```python
# 修改前
uvicorn.run(
    "main:app",
    host="0.0.0.0",
    port=8000,  # 旧端口
    reload=True,
    log_level="info"
)

# 修改后  
uvicorn.run(
    "main:app",
    host="0.0.0.0",
    port=50000,  # 新端口
    reload=True,
    log_level="info"
)
```

### 2. 前端配置更改

**文件**: `/frontend/vite.config.ts`
```typescript
// 修改前
export default defineConfig({
  server: {
    host: '0.0.0.0',
    port: 5173  // 旧端口
  }
})

// 修改后
export default defineConfig({
  server: {
    host: '0.0.0.0',
    port: 50001  // 新端口
  }
})
```

**文件**: `/frontend/src/services/apiConfig.ts`
```typescript
// 修改前
const api = axios.create({
  baseURL: 'http://localhost:8000/api/v1/api-config',  // 旧端口
  timeout: 10000,
  headers: { 'Content-Type': 'application/json' }
})

// 修改后
const api = axios.create({
  baseURL: 'http://localhost:50000/api/v1/api-config',  // 新端口
  timeout: 10000,
  headers: { 'Content-Type': 'application/json' }
})
```

---

## 📝 文档更新

以下文档已同步更新端口信息：

### 1. 主项目文档
- ✅ **README.md** - 主项目说明
- ✅ **CLAUDE.md** - Claude Code集成说明  
- ✅ **frontend/README.md** - 前端项目说明

### 2. 启动脚本
- ✅ **start.sh** - Linux/macOS启动脚本
- ✅ **start.bat** - Windows启动脚本
- ✅ **dev.sh** - 开发环境管理脚本

### 3. 配置文件示例
所有文档中的环境变量配置示例已更新：

```bash
# 后端环境变量
API_HOST=0.0.0.0
API_PORT=50000

# 前端环境变量  
VITE_API_BASE_URL=http://localhost:50000

# CORS配置
ALLOWED_ORIGINS=http://localhost:50001,http://127.0.0.1:50001

# Nginx代理配置
location /api {
    proxy_pass http://backend:50000;
}
```

---

## 🌐 新的服务地址

更改后的服务访问地址：

| 服务 | 旧地址 | 新地址 |
|------|--------|--------|
| **前端界面** | http://localhost:5173 | **http://localhost:50001** |
| **后端API** | http://localhost:8000 | **http://localhost:50000** |
| **API文档 (Swagger)** | http://localhost:8000/docs | **http://localhost:50000/docs** |
| **API文档 (ReDoc)** | http://localhost:8000/redoc | **http://localhost:50000/redoc** |
| **健康检查** | http://localhost:8000/health | **http://localhost:50000/health** |

---

## 🚀 启动验证

### 快速启动
```bash
# Linux/macOS
./start.sh

# Windows  
start.bat
```

### 手动启动验证
```bash
# 1. 启动后端
cd backend
python main.py
# 应该显示: Uvicorn running on http://0.0.0.0:50000

# 2. 启动前端  
cd frontend
npm run dev
# 应该显示: Local: http://localhost:50001/

# 3. 验证服务
curl http://localhost:50000/health
curl http://localhost:50000/api/v1/api-config/status
```

### 浏览器访问
- 前端应用: http://localhost:50001
- API文档: http://localhost:50000/docs

---

## 🔧 故障排除

### 端口冲突处理

如果新端口被占用，可以使用以下命令检查和释放：

```bash
# Linux/macOS
# 检查端口占用
lsof -i :50000
lsof -i :50001

# 释放端口
sudo kill -9 $(lsof -t -i:50000)
sudo kill -9 $(lsof -t -i:50001)

# Windows
# 检查端口占用
netstat -ano | findstr :50000
netstat -ano | findstr :50001

# 释放端口 (使用PID)
taskkill /F /PID <PID>
```

### 防火墙配置

如果使用防火墙，请确保新端口被允许：

```bash
# Linux (ufw)
sudo ufw allow 50000
sudo ufw allow 50001

# Linux (firewalld)  
sudo firewall-cmd --permanent --add-port=50000/tcp
sudo firewall-cmd --permanent --add-port=50001/tcp
sudo firewall-cmd --reload

# Windows防火墙
# 通过Windows防火墙设置界面添加入站规则
```

### 环境变量检查

确认所有环境变量已更新：

```bash
# 检查前端构建时的API地址
cd frontend
npm run build
# 检查dist目录中是否包含正确的API地址

# 检查后端启动配置
cd backend
python -c "
import os
from main import app
print(f'Backend will run on port: 50000')
"
```

---

## 📖 相关说明

### 为什么更改端口？

1. **避免冲突**: 避免与其他开发服务的端口冲突
2. **统一管理**: 使用50000+段便于管理和识别
3. **开发体验**: 提供更好的开发环境隔离

### 向后兼容性

⚠️ **重要提醒**: 此更改不向后兼容，所有现有配置都需要更新到新端口。

### 生产环境注意事项

在生产环境部署时，请确保：
1. 反向代理配置已更新（如Nginx、Apache）
2. 防火墙规则包含新端口
3. 监控系统已更新端口配置
4. 负载均衡器配置已调整

---

## ✅ 验证清单

部署后请验证以下项目：

- [ ] 后端服务在50000端口正常启动
- [ ] 前端服务在50001端口正常启动  
- [ ] API健康检查通过: `curl http://localhost:50000/health`
- [ ] 前端可以正常访问后端API
- [ ] Swagger文档可以正常访问: http://localhost:50000/docs
- [ ] 所有功能测试通过
- [ ] 启动脚本工作正常
- [ ] 开发环境正常运行

---

**最后更新**: 2025-08-08  
**更改人员**: Claude Code Assistant  
**影响范围**: 开发和部署环境