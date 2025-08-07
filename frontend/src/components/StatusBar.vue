<template>
  <div class="status-bar">
    <div class="status-left">
      <div class="current-config">
        <el-icon class="status-icon">
          <Connection />
        </el-icon>
        <span class="label">当前配置:</span>
        <el-tag 
          v-if="configStore.activeProfile" 
          type="success" 
          size="small"
        >
          {{ configStore.activeProfile.name }}
        </el-tag>
        <el-tag v-else type="warning" size="small">
          未激活
        </el-tag>
      </div>
    </div>

    <div class="status-center">
      <div class="quick-switcher">
        <span class="label">快捷切换:</span>
        <el-select
          :model-value="configStore.activeProfile?.id || ''"
          @change="handleQuickSwitch"
          placeholder="选择配置"
          size="small"
          style="width: 160px"
          :loading="configStore.loading"
        >
          <el-option
            v-for="config in configStore.profiles"
            :key="config.id"
            :label="config.name"
            :value="config.id"
          />
        </el-select>
      </div>
    </div>

    <div class="status-right">
      <div class="service-status">
        <el-icon class="status-icon" :color="serviceStatusColor">
          <CircleCheck v-if="isServiceHealthy" />
          <CircleClose v-else />
        </el-icon>
        <span class="label">服务状态:</span>
        <el-tag :type="isServiceHealthy ? 'success' : 'danger'" size="small">
          {{ serviceStatusText }}
        </el-tag>
      </div>
      
      <div class="config-count">
        <el-icon class="status-icon">
          <DataBoard />
        </el-icon>
        <span class="count-text">{{ configStore.profileCount }} 个配置</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted } from 'vue'
import { 
  ElIcon, 
  ElTag, 
  ElSelect, 
  ElOption 
} from 'element-plus'
import {
  Connection,
  CircleCheck,
  CircleClose,
  DataBoard
} from '@element-plus/icons-vue'
import { useConfigStore } from '../stores/config'

const configStore = useConfigStore()

// 服务状态检查
const isServiceHealthy = computed(() => {
  // 这里可以添加更复杂的健康检查逻辑
  return !configStore.error && configStore.profiles.length >= 0
})

const serviceStatusColor = computed(() => 
  isServiceHealthy.value ? '#67c23a' : '#f56c6c'
)

const serviceStatusText = computed(() => 
  isServiceHealthy.value ? '正常' : '异常'
)

// 方法
const handleQuickSwitch = async (profileId: string) => {
  if (profileId && profileId !== configStore.activeProfile?.id) {
    try {
      await configStore.activateProfile(profileId)
    } catch {
      // 错误已在store中处理
    }
  }
}

// 定期刷新状态
let statusInterval: number | null = null

onMounted(() => {
  // 每30秒刷新一次状态
  statusInterval = window.setInterval(() => {
    configStore.fetchCurrentConfig()
  }, 30000)
})

onUnmounted(() => {
  if (statusInterval) {
    clearInterval(statusInterval)
  }
})
</script>

<style scoped>
.status-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 24px;
  background: var(--bg-primary);
  border: 1px solid var(--border-light);
  border-radius: var(--radius-xl) var(--radius-xl) 0 0;
  box-shadow: var(--shadow-sm);
  backdrop-filter: blur(8px);
  position: sticky;
  top: 0;
  z-index: 100;
}

.status-left,
.status-center,
.status-right {
  display: flex;
  align-items: center;
  gap: 20px;
}

.current-config,
.quick-switcher,
.service-status,
.config-count {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 12px;
  background: var(--bg-secondary);
  border-radius: var(--radius-md);
  transition: all 0.3s ease;
}

.current-config:hover,
.service-status:hover,
.config-count:hover {
  background: var(--bg-tertiary);
  transform: translateY(-1px);
}

.status-icon {
  font-size: 18px;
  opacity: 0.8;
}

.label {
  font-weight: 600;
  color: var(--text-primary);
  font-size: 14px;
}

.count-text {
  color: var(--text-secondary);
  font-size: 14px;
  font-weight: 500;
}

.quick-switcher {
  min-width: 200px;
}

.quick-switcher :deep(.el-select) {
  border-radius: var(--radius-md);
}

/* 特殊效果 */
.current-config {
  position: relative;
  overflow: hidden;
}

.current-config::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 2px;
  background: var(--primary-gradient);
  border-radius: var(--radius-md) var(--radius-md) 0 0;
}

@media (max-width: 1200px) {
  .status-bar {
    flex-wrap: wrap;
    gap: 12px;
  }
  
  .status-left,
  .status-center,
  .status-right {
    gap: 12px;
  }
}

@media (max-width: 768px) {
  .status-bar {
    flex-direction: column;
    gap: 12px;
    padding: 16px;
  }
  
  .status-left,
  .status-center,
  .status-right {
    width: 100%;
    justify-content: center;
    flex-wrap: wrap;
  }
  
  .quick-switcher {
    width: 100%;
    min-width: unset;
  }
  
  .quick-switcher :deep(.el-select) {
    width: 100% !important;
  }
}

@media (max-width: 480px) {
  .current-config,
  .quick-switcher,
  .service-status,
  .config-count {
    padding: 6px 10px;
    font-size: 12px;
  }
  
  .label {
    font-size: 12px;
  }
  
  .status-icon {
    font-size: 16px;
  }
}
</style>