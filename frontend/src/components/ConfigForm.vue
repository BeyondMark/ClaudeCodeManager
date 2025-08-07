<template>
  <el-dialog
    v-model="visible"
    :title="isEditing ? '编辑配置' : '新增配置'"
    width="500px"
    :before-close="handleClose"
    destroy-on-close
  >
    <el-form
      ref="formRef"
      :model="formData"
      :rules="rules"
      label-width="100px"
      label-position="left"
    >
      <el-form-item label="配置名称" prop="name">
        <el-input
          v-model="formData.name"
          placeholder="请输入配置名称"
          clearable
        />
      </el-form-item>

      <el-form-item label="API密钥" prop="api_key">
        <el-input
          v-model="formData.api_key"
          type="password"
          placeholder="请输入API密钥"
          show-password
          clearable
        />
      </el-form-item>

      <el-form-item label="服务地址" prop="base_url">
        <el-input
          v-model="formData.base_url"
          placeholder="请输入API服务地址"
          clearable
        />
        <div class="form-tips">
          <el-text type="info" size="small">
            常用地址: https://api.anthropic.com
          </el-text>
        </div>
      </el-form-item>

      <el-form-item>
        <div class="form-actions">
          <el-button @click="handleTestConnection" :loading="testing">
            测试连接
          </el-button>
          <div class="action-buttons">
            <el-button @click="handleClose">取消</el-button>
            <el-button type="primary" @click="handleSubmit" :loading="submitting">
              {{ isEditing ? '更新' : '创建' }}
            </el-button>
          </div>
        </div>
      </el-form-item>
    </el-form>
  </el-dialog>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch } from 'vue'
import type { FormInstance, FormRules } from 'element-plus'
import { ElDialog, ElForm, ElFormItem, ElInput, ElButton, ElText, ElMessage } from 'element-plus'
import type { ApiConfigProfile, CreateApiConfigRequest, UpdateApiConfigRequest } from '../types/api'
import { useConfigStore } from '../stores/config'

interface Props {
  modelValue: boolean
  editingConfig?: ApiConfigProfile | null
}

interface Emits {
  (e: 'update:modelValue', value: boolean): void
  (e: 'success'): void
}

const props = withDefaults(defineProps<Props>(), {
  editingConfig: null
})

const emit = defineEmits<Emits>()
const configStore = useConfigStore()

// 响应式数据
const formRef = ref<FormInstance>()
const submitting = ref(false)
const testing = ref(false)

const formData = reactive<CreateApiConfigRequest>({
  name: '',
  api_key: '',
  base_url: 'https://api.anthropic.com'
})

// 计算属性
const visible = computed({
  get: () => props.modelValue,
  set: (value: boolean) => emit('update:modelValue', value)
})

const isEditing = computed(() => !!props.editingConfig)

// 表单验证规则
const rules: FormRules = {
  name: [
    { required: true, message: '请输入配置名称', trigger: 'blur' },
    { min: 1, max: 50, message: '名称长度在1到50个字符', trigger: 'blur' }
  ],
  api_key: [
    { required: true, message: '请输入API密钥', trigger: 'blur' },
    { min: 10, message: 'API密钥长度至少10个字符', trigger: 'blur' }
  ],
  base_url: [
    { required: true, message: '请输入服务地址', trigger: 'blur' },
    { 
      pattern: /^https?:\/\/.+/, 
      message: '请输入有效的URL地址', 
      trigger: 'blur' 
    }
  ]
}

// 方法
const resetForm = () => {
  formData.name = ''
  formData.api_key = ''
  formData.base_url = 'https://api.anthropic.com'
  formRef.value?.clearValidate()
}

// 监听编辑配置变化
watch(
  () => props.editingConfig,
  (newConfig) => {
    if (newConfig) {
      formData.name = newConfig.name
      formData.api_key = newConfig.api_key
      formData.base_url = newConfig.base_url
    } else {
      resetForm()
    }
  },
  { immediate: true }
)

const handleClose = () => {
  visible.value = false
  resetForm()
}

const handleTestConnection = async () => {
  // 先验证表单
  try {
    await formRef.value?.validate()
  } catch {
    ElMessage.warning('请先完善配置信息')
    return
  }

  testing.value = true
  try {
    await configStore.testConnection(formData)
  } finally {
    testing.value = false
  }
}

const handleSubmit = async () => {
  try {
    await formRef.value?.validate()
  } catch {
    return
  }

  submitting.value = true
  try {
    if (isEditing.value && props.editingConfig) {
      // 更新配置
      const updateData: UpdateApiConfigRequest = { ...formData }
      await configStore.updateProfile(props.editingConfig.id, updateData)
    } else {
      // 创建配置
      await configStore.createProfile(formData)
    }
    
    emit('success')
    handleClose()
  } catch {
    // 错误已在store中处理
  } finally {
    submitting.value = false
  }
}
</script>

<style scoped>
.form-tips {
  margin-top: 4px;
}

.form-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
}

.action-buttons {
  display: flex;
  gap: 12px;
}

:deep(.el-dialog) {
  border-radius: 12px;
}

:deep(.el-dialog__header) {
  border-bottom: 1px solid #ebeef5;
  padding-bottom: 12px;
}

:deep(.el-form-item__label) {
  font-weight: 500;
}
</style>