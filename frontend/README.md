# ClaudeCodeManager - Frontend

Vue 3 + TypeScript + Element Plus 前端应用，用于管理Claude Code API配置。

## 📋 功能特性

### 🎨 用户界面
- **现代化设计**: Element Plus企业级UI组件库
- **响应式布局**: 支持桌面和移动端设备
- **暗色主题**: 支持明暗主题切换（Element Plus内置）
- **国际化支持**: 预留多语言支持接口

### ⚡ 核心功能
- **配置管理**: CRUD操作，支持创建、编辑、删除API配置
- **一键切换**: 顶部选择器快速切换激活配置
- **实时状态**: 配置激活状态实时显示和更新
- **安全显示**: API密钥自动脱敏显示
- **错误处理**: 友好的错误提示和加载状态

### 🔧 技术特性
- **类型安全**: 完整的TypeScript类型定义
- **状态管理**: Pinia响应式状态管理
- **HTTP客户端**: Axios封装的API服务层
- **开发热更新**: Vite提供的快速开发体验

## 🚀 快速开始

### 系统要求
- **Node.js**: ^20.19.0 || >=22.12.0
- **npm**: 9.0+ 或 **pnpm**: 8.0+

### 安装依赖
```bash
npm install
# 或
pnpm install
```

### 开发命令
```bash
# 启动开发服务器 (http://localhost:5173)
npm run dev

# 构建生产版本
npm run build

# 预览生产构建
npm run preview

# 类型检查
npm run type-check

# 代码检查和修复
npm run lint

# 代码格式化
npm run format
```

## 🏗️ 项目结构

```
frontend/
├── src/
│   ├── components/          # 可复用组件
│   │   ├── ConfigCard.vue   # 配置卡片组件
│   │   ├── ConfigForm.vue   # 配置表单组件
│   │   └── StatusBar.vue    # 状态栏组件
│   ├── stores/              # Pinia状态管理
│   │   └── config.ts        # 配置管理Store
│   ├── services/            # API服务层
│   │   └── api.ts           # HTTP客户端封装
│   ├── types/               # TypeScript类型定义
│   │   └── index.ts         # API数据类型
│   ├── views/               # 页面组件
│   │   └── Dashboard.vue    # 主控制面板
│   ├── App.vue              # 根组件
│   ├── main.ts              # 应用入口
│   └── style.css            # 全局样式
├── public/                  # 静态资源
├── index.html               # HTML模板
├── package.json             # 项目配置
├── tsconfig.json            # TypeScript配置
├── vite.config.ts           # Vite构建配置
└── README.md                # 本文档
```

## 🔧 开发配置

### IDE 推荐设置
- **VSCode** + **Volar** 插件（禁用 Vetur）
- **TypeScript** 语言服务支持
- **Vue 3** 语法高亮和智能提示

### VSCode 推荐插件
```json
{
  "recommendations": [
    "Vue.volar",
    "Vue.vscode-typescript-vue-plugin",
    "bradlc.vscode-tailwindcss",
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint"
  ]
}
```

### 环境变量配置
```bash
# .env.development
VITE_API_BASE_URL=http://localhost:8000

# .env.production  
VITE_API_BASE_URL=https://your-api-domain.com
```

## 📦 技术栈详情

### 核心依赖
- **Vue 3.5.18**: 组合式API，更好的TypeScript支持
- **TypeScript 5.8.0**: 类型安全和开发体验
- **Element Plus 2.10.5**: 企业级UI组件库
- **Pinia 3.0.3**: Vue 3官方状态管理
- **Axios 1.11.0**: HTTP客户端
- **Vue Router 4.5.1**: 路由管理

### 开发工具
- **Vite 7.0.6**: 快速构建工具，支持HMR
- **Vue TSC 3.0.4**: Vue单文件组件类型检查
- **ESLint 9.31.0**: 代码质量检查
- **Prettier 3.6.2**: 代码格式化
- **npm-run-all2**: 并行执行多个npm脚本

### 构建优化
- **代码分割**: Vite自动进行路由级别的代码分割
- **Tree Shaking**: 自动移除未使用的代码
- **按需引入**: Element Plus组件按需加载
- **类型检查**: 构建时进行完整的类型验证

## 🎯 开发指南

### 组件开发规范
```vue
<template>
  <!-- 使用Element Plus组件 -->
  <el-card class="config-card">
    <template #header>
      <span>{{ config.name }}</span>
    </template>
    <!-- 组件内容 -->
  </el-card>
</template>

<script setup lang="ts">
// TypeScript setup 语法
import { ref, computed } from 'vue'
import type { ApiConfigProfile } from '@/types'

// Props定义
interface Props {
  config: ApiConfigProfile
}
const props = defineProps<Props>()

// 响应式数据
const isLoading = ref(false)

// 计算属性
const maskedApiKey = computed(() => 
  props.config.api_key.replace(/^sk-.*/, 'sk-***')
)
</script>
```

### 状态管理模式
```typescript
// stores/config.ts
export const useConfigStore = defineStore('config', {
  state: () => ({
    profiles: [] as ApiConfigProfile[],
    activeProfileId: null as string | null,
    loading: false
  }),
  
  getters: {
    activeProfile: (state) => 
      state.profiles.find(p => p.id === state.activeProfileId)
  },
  
  actions: {
    async fetchProfiles() {
      this.loading = true
      try {
        const data = await apiService.getProfiles()
        this.profiles = data.profiles
        this.activeProfileId = data.active_profile_id
      } finally {
        this.loading = false
      }
    }
  }
})
```

### API服务封装
```typescript
// services/api.ts
import axios from 'axios'

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
  timeout: 10000
})

export const apiService = {
  async getProfiles(): Promise<ApiConfigListResponse> {
    const response = await apiClient.get('/api/v1/api-config/profiles')
    return response.data
  },
  
  async createProfile(data: CreateApiConfigRequest): Promise<ApiConfigProfile> {
    const response = await apiClient.post('/api/v1/api-config/profiles', data)
    return response.data
  }
}
```

## 🔍 调试指南

### Vue DevTools
1. 安装 **Vue DevTools** 浏览器扩展
2. 开发模式下自动启用组件调试
3. 查看组件状态、Props、Events等

### 开发者工具集成
- **Vite Plugin Vue DevTools**: 8.0.0版本提供增强的调试体验
- **浏览器开发者工具**: Network面板查看API请求
- **VSCode调试**: 支持断点调试和热更新

### 常见问题排查
```bash
# 清除缓存
rm -rf node_modules .vite
npm install

# 类型检查
npm run type-check

# 依赖版本检查
npm outdated

# 构建分析
npm run build -- --analyze
```

## 🚀 部署配置

### 生产构建
```bash
# 构建生产版本
npm run build

# 构建产物位置: dist/
# 静态文件服务器: 任何支持SPA的服务器
```

### 部署选项
- **Nginx**: 配置history模式路由
- **Apache**: 启用mod_rewrite
- **CDN**: 静态资源CDN加速
- **Docker**: 容器化部署

### Nginx配置示例
```nginx
server {
    listen 80;
    server_name your-domain.com;
    root /var/www/dist;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    location /api {
        proxy_pass http://backend:8000;
    }
}
```

## 📖 参考资源

- [Vue 3 官方文档](https://vuejs.org/)
- [TypeScript 官方文档](https://www.typescriptlang.org/)
- [Element Plus 组件库](https://element-plus.org/)
- [Pinia 状态管理](https://pinia.vuejs.org/)
- [Vite 构建工具](https://vitejs.dev/)

## 🤝 贡献指南

1. **Fork** 本仓库
2. 创建功能分支: `git checkout -b feature/amazing-feature`
3. 提交更改: `git commit -m 'Add some amazing feature'`
4. 推送分支: `git push origin feature/amazing-feature`
5. 提交 **Pull Request**

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](../LICENSE) 文件了解详情。
