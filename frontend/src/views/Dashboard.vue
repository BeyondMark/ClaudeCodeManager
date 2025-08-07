<template>
  <div class="dashboard">
    <!-- 状态栏 -->
    <StatusBar />

    <!-- 主内容区 -->
    <div class="main-content">
      <div class="content-header">
        <h1 class="page-title">
          <el-icon class="title-icon">
            <Setting />
          </el-icon>
          Claude Code 配置管理
        </h1>
        <div class="header-actions">
          <el-button 
            type="info" 
            @click="handleBackup"
            :loading="configStore.loading"
          >
            <el-icon><Download /></el-icon>
            备份配置
          </el-button>
          <el-button 
            type="primary" 
            @click="showCreateForm = true"
          >
            <el-icon><Plus /></el-icon>
            新增配置
          </el-button>
        </div>
      </div>

      <!-- 配置列表 -->
      <div class="config-grid" v-loading="configStore.loading">
        <template v-if="configStore.hasProfiles">
          <ConfigCard
            v-for="config in configStore.profiles"
            :key="config.id"
            :config="config"
            @activate="handleActivate"
            @edit="handleEdit"
            @delete="handleDelete"
          />
        </template>
        
        <!-- 空状态 -->
        <div v-else class="empty-state">
          <el-empty 
            description="暂无配置"
            :image-size="120"
          >
            <el-button 
              type="primary" 
              @click="showCreateForm = true"
            >
              创建第一个配置
            </el-button>
          </el-empty>
        </div>
      </div>
    </div>

    <!-- 配置表单对话框 -->
    <ConfigForm
      v-model="showCreateForm"
      :editing-config="editingConfig"
      @success="handleFormSuccess"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { 
  ElIcon, 
  ElButton, 
  ElEmpty,
  ElMessage
} from 'element-plus'
import {
  Setting,
  Plus,
  Download
} from '@element-plus/icons-vue'
import { useConfigStore } from '../stores/config'
import StatusBar from '../components/StatusBar.vue'
import ConfigCard from '../components/ConfigCard.vue'
import ConfigForm from '../components/ConfigForm.vue'
import type { ApiConfigProfile } from '../types/api'

const configStore = useConfigStore()

// 响应式数据
const showCreateForm = ref(false)
const editingConfig = ref<ApiConfigProfile | null>(null)

// 方法
const handleActivate = async (profileId: string) => {
  try {
    await configStore.activateProfile(profileId)
  } catch {
    // 错误已在store中处理
  }
}

const handleEdit = (config: ApiConfigProfile) => {
  editingConfig.value = config
  showCreateForm.value = true
}

const handleDelete = async (profileId: string) => {
  try {
    await configStore.deleteProfile(profileId)
  } catch {
    // 错误已在store中处理
  }
}

const handleBackup = async () => {
  try {
    await configStore.backupConfig()
  } catch {
    // 错误已在store中处理
  }
}

const handleFormSuccess = () => {
  editingConfig.value = null
  // 刷新列表
  configStore.fetchProfiles()
}

// 组件挂载时初始化数据
onMounted(async () => {
  try {
    await configStore.initialize()
  } catch {
    ElMessage.error('初始化失败，请检查后端服务是否启动')
  }
})
</script>

<style scoped>
.dashboard {
  min-height: 100vh;
  height: 100%;
  width: 100%;
  background: var(--bg-gradient);
  display: flex;
  flex-direction: column;
}

.main-content {
  flex: 1;
  padding: 32px;
  width: 100%;
  max-width: none; /* 移除最大宽度限制，实现真正的全屏 */
  margin: 0;
  box-sizing: border-box;
}

.content-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 32px;
  padding: 24px;
  background: var(--bg-primary);
  border-radius: var(--radius-xl);
  box-shadow: var(--shadow-sm);
  border: 1px solid var(--border-light);
}

.page-title {
  display: flex;
  align-items: center;
  gap: 16px;
  margin: 0;
  color: var(--text-primary);
  font-size: 28px;
  font-weight: 700;
  background: var(--primary-gradient);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.title-icon {
  font-size: 32px;
  color: var(--primary-color);
  filter: drop-shadow(0 2px 4px rgba(99, 102, 241, 0.3));
}

.header-actions {
  display: flex;
  gap: 16px;
}

.header-actions .el-button {
  padding: 12px 24px;
  font-weight: 600;
  font-size: 14px;
  box-shadow: var(--shadow-sm);
  transition: all 0.3s ease;
}

.header-actions .el-button:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-md);
}

.config-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(420px, 1fr));
  gap: 24px;
  min-height: 400px;
  width: 100%; /* 确保网格占满全宽 */
}

.empty-state {
  grid-column: 1 / -1;
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 500px;
  background: var(--bg-primary);
  border-radius: var(--radius-xl);
  box-shadow: var(--shadow-sm);
  border: 1px solid var(--border-light);
  position: relative;
  overflow: hidden;
}

.empty-state::before {
  content: '';
  position: absolute;
  top: -50%;
  left: -50%;
  width: 200%;
  height: 200%;
  background: radial-gradient(circle, var(--primary-color) 0%, transparent 70%);
  opacity: 0.03;
  animation: float 6s ease-in-out infinite;
}

@keyframes float {
  0%, 100% { transform: translateY(0px) rotate(0deg); }
  50% { transform: translateY(-20px) rotate(180deg); }
}

.empty-state :deep(.el-empty) {
  padding: 40px;
}

.empty-state :deep(.el-empty__image) {
  width: 200px;
  height: 200px;
  margin-bottom: 24px;
}

.empty-state :deep(.el-empty__description) {
  font-size: 18px;
  font-weight: 500;
  color: var(--text-secondary);
  margin-bottom: 32px;
}

.empty-state :deep(.el-button) {
  padding: 16px 32px;
  font-size: 16px;
  font-weight: 600;
  border-radius: var(--radius-lg);
  background: var(--primary-gradient);
  border: none;
  box-shadow: var(--shadow-md);
  transition: all 0.3s ease;
}

.empty-state :deep(.el-button:hover) {
  transform: translateY(-3px);
  box-shadow: var(--shadow-lg);
}

/* 响应式设计 */
/* 大屏幕优化 */
@media (min-width: 1400px) {
  .config-grid {
    grid-template-columns: repeat(auto-fill, minmax(450px, 1fr));
    gap: 32px;
  }
  
  .main-content {
    padding: 48px;
  }
  
  .content-header {
    padding: 32px;
    margin-bottom: 48px;
  }
}

@media (max-width: 1400px) {
  .config-grid {
    grid-template-columns: repeat(auto-fill, minmax(380px, 1fr));
    gap: 20px;
  }
}

@media (max-width: 1024px) {
  .main-content {
    padding: 24px;
  }
  
  .content-header {
    padding: 20px;
    margin-bottom: 24px;
  }
  
  .page-title {
    font-size: 24px;
  }
  
  .title-icon {
    font-size: 28px;
  }
  
  .config-grid {
    grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
    gap: 16px;
  }
}

@media (max-width: 768px) {
  .main-content {
    padding: 16px;
  }
  
  .content-header {
    flex-direction: column;
    gap: 20px;
    align-items: stretch;
    padding: 16px;
  }
  
  .page-title {
    justify-content: center;
    font-size: 22px;
  }
  
  .title-icon {
    font-size: 26px;
  }
  
  .header-actions {
    justify-content: center;
    gap: 12px;
  }
  
  .config-grid {
    grid-template-columns: 1fr;
    gap: 12px;
  }
  
  .empty-state {
    min-height: 400px;
  }
}

@media (max-width: 480px) {
  .main-content {
    padding: 12px;
  }
  
  .content-header {
    padding: 12px;
  }
  
  .page-title {
    font-size: 20px;
  }
  
  .header-actions {
    flex-direction: column;
    gap: 8px;
  }
  
  .header-actions .el-button {
    width: 100%;
    padding: 10px 20px;
  }
  
  .empty-state :deep(.el-empty__image) {
    width: 150px;
    height: 150px;
  }
  
  .empty-state :deep(.el-empty__description) {
    font-size: 16px;
  }
  
  .empty-state :deep(.el-button) {
    padding: 14px 28px;
    font-size: 14px;
  }
}
</style>