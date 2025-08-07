<template>
  <el-card 
    class="config-card" 
    :class="{ 'active-card': config.is_active }"
    shadow="hover"
  >
    <template #header>
      <div class="card-header">
        <div class="config-name">
          <el-icon v-if="config.is_active" class="active-icon" color="#67c23a">
            <Check />
          </el-icon>
          <span class="name">{{ config.name }}</span>
        </div>
        <div class="card-actions">
          <el-button 
            v-if="!config.is_active" 
            type="primary" 
            size="small"
            @click="handleActivate"
            :loading="loading"
          >
            激活
          </el-button>
          <el-button 
            type="info" 
            size="small"
            @click="handleEdit"
          >
            编辑
          </el-button>
          <el-button 
            type="danger" 
            size="small"
            @click="handleDelete"
            :loading="loading"
          >
            删除
          </el-button>
        </div>
      </div>
    </template>

    <div class="config-content">
      <div class="config-item">
        <span class="label">API密钥:</span>
        <span class="value masked">{{ maskedApiKey }}</span>
      </div>
      <div class="config-item">
        <span class="label">服务地址:</span>
        <span class="value">{{ config.base_url }}</span>
      </div>
      <div class="config-item">
        <span class="label">创建时间:</span>
        <span class="value">{{ formatDate(config.created_at) }}</span>
      </div>
      <div class="config-item">
        <span class="label">状态:</span>
        <el-tag :type="config.is_active ? 'success' : 'info'" size="small">
          {{ config.is_active ? '激活中' : '待用' }}
        </el-tag>
      </div>
    </div>
  </el-card>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { ElCard, ElIcon, ElButton, ElTag } from 'element-plus'
import { Check } from '@element-plus/icons-vue'
import type { ApiConfigProfile } from '../types/api'

interface Props {
  config: ApiConfigProfile
}

interface Emits {
  (e: 'activate', profileId: string): void
  (e: 'edit', config: ApiConfigProfile): void
  (e: 'delete', profileId: string): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

const loading = ref(false)

// 计算属性
const maskedApiKey = computed(() => {
  const key = props.config.api_key
  if (key.length <= 10) return key
  return `${key.substring(0, 7)}...${key.substring(key.length - 4)}`
})

// 方法
const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleString('zh-CN')
}

const handleActivate = async () => {
  loading.value = true
  try {
    emit('activate', props.config.id)
  } finally {
    loading.value = false
  }
}

const handleEdit = () => {
  emit('edit', props.config)
}

const handleDelete = () => {
  emit('delete', props.config.id)
}
</script>

<style scoped>
.config-card {
  margin-bottom: 20px;
  background: var(--bg-primary);
  border: 1px solid var(--border-light);
  border-radius: var(--radius-xl);
  box-shadow: var(--shadow-sm);
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;
}

.config-card:hover {
  box-shadow: var(--shadow-lg);
  transform: translateY(-4px);
}

.active-card {
  border-color: var(--success-color);
  box-shadow: 0 8px 25px 0 rgba(16, 185, 129, 0.15);
  background: linear-gradient(135deg, var(--bg-primary) 0%, rgba(16, 185, 129, 0.02) 100%);
}

.active-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 3px;
  background: linear-gradient(90deg, var(--success-color), #34d399);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 24px;
  background: rgba(var(--bg-secondary), 0.5);
  backdrop-filter: blur(8px);
  border-bottom: 1px solid var(--border-light);
}

.config-name {
  display: flex;
  align-items: center;
  gap: 12px;
}

.active-icon {
  font-size: 20px;
  padding: 4px;
  background: var(--success-color);
  color: white;
  border-radius: 50%;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0% { box-shadow: 0 0 0 0 rgba(16, 185, 129, 0.7); }
  70% { box-shadow: 0 0 0 10px rgba(16, 185, 129, 0); }
  100% { box-shadow: 0 0 0 0 rgba(16, 185, 129, 0); }
}

.name {
  font-weight: 700;
  font-size: 18px;
  color: var(--text-primary);
  letter-spacing: -0.025em;
}

.card-actions {
  display: flex;
  gap: 8px;
}

.card-actions .el-button {
  padding: 8px 16px;
  font-weight: 600;
  border-radius: var(--radius-md);
  transition: all 0.3s ease;
  font-size: 13px;
}

.card-actions .el-button:hover {
  transform: translateY(-1px);
  box-shadow: var(--shadow-md);
}

.card-actions .el-button--primary {
  background: var(--primary-gradient);
  border: none;
}

.card-actions .el-button--info {
  background: linear-gradient(135deg, var(--info-color), #60a5fa);
  border: none;
  color: white;
}

.card-actions .el-button--danger {
  background: linear-gradient(135deg, var(--danger-color), #f87171);
  border: none;
}

.config-content {
  padding: 24px;
}

.config-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  padding: 12px 16px;
  background: var(--bg-secondary);
  border-radius: var(--radius-md);
  transition: all 0.3s ease;
}

.config-item:hover {
  background: var(--bg-tertiary);
  transform: translateX(4px);
}

.config-item:last-child {
  margin-bottom: 0;
}

.label {
  font-weight: 600;
  color: var(--text-secondary);
  min-width: 90px;
  font-size: 14px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.value {
  color: var(--text-primary);
  flex: 1;
  text-align: right;
  font-weight: 500;
  font-size: 14px;
}

.value.masked {
  font-family: 'JetBrains Mono', 'Courier New', monospace;
  color: var(--text-muted);
  background: var(--bg-tertiary);
  padding: 4px 8px;
  border-radius: var(--radius-sm);
  font-size: 12px;
  letter-spacing: 0.05em;
}

.config-item .el-tag {
  font-weight: 600;
  padding: 4px 12px;
  border-radius: var(--radius-md);
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.025em;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .card-header {
    flex-direction: column;
    gap: 16px;
    padding: 16px;
  }
  
  .card-actions {
    width: 100%;
    justify-content: center;
    flex-wrap: wrap;
  }
  
  .card-actions .el-button {
    flex: 1;
    min-width: 80px;
  }
  
  .config-content {
    padding: 16px;
  }
  
  .config-item {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
    padding: 12px;
  }
  
  .label {
    min-width: unset;
  }
  
  .value {
    text-align: left;
    width: 100%;
  }
  
  .value.masked {
    width: fit-content;
  }
}

@media (max-width: 480px) {
  .config-card {
    margin-bottom: 16px;
  }
  
  .card-header {
    padding: 12px;
  }
  
  .name {
    font-size: 16px;
  }
  
  .config-content {
    padding: 12px;
  }
  
  .config-item {
    margin-bottom: 12px;
    padding: 10px;
  }
  
  .label {
    font-size: 12px;
  }
  
  .value {
    font-size: 13px;
  }
}
</style>