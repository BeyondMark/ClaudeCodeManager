import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { 
  ApiConfigProfile, 
  CreateApiConfigRequest, 
  UpdateApiConfigRequest,
  CurrentApiConfigResponse 
} from '../types/api'
import ApiConfigService from '../services/apiConfig'
import { ElMessage, ElMessageBox } from 'element-plus'

interface ApiError {
  response?: {
    data?: {
      detail?: string
    }
  }
  message?: string
}

export const useConfigStore = defineStore('config', () => {
  // 状态
  const profiles = ref<ApiConfigProfile[]>([])
  const currentConfig = ref<CurrentApiConfigResponse | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  // 计算属性
  const activeProfile = computed(() => 
    profiles.value.find(profile => profile.is_active) || null
  )

  const profileCount = computed(() => profiles.value.length)

  const hasProfiles = computed(() => profiles.value.length > 0)

  // 工具函数
  const setLoading = (state: boolean) => {
    loading.value = state
  }

  const setError = (message: string | null) => {
    error.value = message
    if (message) {
      ElMessage.error(message)
    }
  }

  const showSuccess = (message: string) => {
    ElMessage.success(message)
  }

  // 操作方法
  const fetchProfiles = async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await ApiConfigService.getProfiles()
      profiles.value = response.profiles
    } catch (err: unknown) {
      const error = err as ApiError
      setError(`获取配置列表失败: ${error.response?.data?.detail || error.message || '未知错误'}`)
    } finally {
      setLoading(false)
    }
  }

  const fetchCurrentConfig = async () => {
    try {
      const response = await ApiConfigService.getCurrentConfig()
      currentConfig.value = response
    } catch (err: unknown) {
      const error = err as ApiError
      console.warn('获取当前配置失败:', error.message || '未知错误')
    }
  }

  const createProfile = async (data: CreateApiConfigRequest) => {
    try {
      setLoading(true)
      setError(null)
      const newProfile = await ApiConfigService.createProfile(data)
      profiles.value.push(newProfile)
      showSuccess(`配置 "${newProfile.name}" 创建成功`)
      
      // 如果这是第一个配置，自动激活
      if (profiles.value.length === 1) {
        await activateProfile(newProfile.id)
      }
      
      return newProfile
    } catch (err: unknown) {
      const error = err as ApiError
      setError(`创建配置失败: ${error.response?.data?.detail || error.message || '未知错误'}`)
      throw err
    } finally {
      setLoading(false)
    }
  }

  const updateProfile = async (profileId: string, data: UpdateApiConfigRequest) => {
    try {
      setLoading(true)
      setError(null)
      await ApiConfigService.updateProfile(profileId, data)
      
      // 更新本地状态
      const index = profiles.value.findIndex(p => p.id === profileId)
      if (index !== -1) {
        profiles.value[index] = { ...profiles.value[index], ...data }
      }
      
      showSuccess('配置更新成功')
    } catch (err: unknown) {
      const error = err as ApiError
      setError(`更新配置失败: ${error.response?.data?.detail || error.message || '未知错误'}`)
      throw err
    } finally {
      setLoading(false)
    }
  }

  const deleteProfile = async (profileId: string) => {
    try {
      const profile = profiles.value.find(p => p.id === profileId)
      if (!profile) return

      // 确认删除
      await ElMessageBox.confirm(
        `确定要删除配置 "${profile.name}" 吗？`,
        '删除确认',
        {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'warning'
        }
      )

      setLoading(true)
      setError(null)
      await ApiConfigService.deleteProfile(profileId)
      
      // 从本地状态中移除
      profiles.value = profiles.value.filter(p => p.id !== profileId)
      showSuccess('配置删除成功')
      
      // 如果删除的是激活配置，自动激活其他配置
      if (profile.is_active && profiles.value.length > 0) {
        await activateProfile(profiles.value[0].id)
      }
    } catch (err: unknown) {
      if (err !== 'cancel') {
        const error = err as ApiError
        setError(`删除配置失败: ${error.response?.data?.detail || error.message || '未知错误'}`)
      }
    } finally {
      setLoading(false)
    }
  }

  const activateProfile = async (profileId: string) => {
    try {
      setLoading(true)
      setError(null)
      const response = await ApiConfigService.activateProfile(profileId)
      
      // 更新本地状态
      profiles.value.forEach(profile => {
        profile.is_active = profile.id === profileId
      })
      
      // 更新当前配置
      await fetchCurrentConfig()
      
      showSuccess(response.message)
    } catch (err: unknown) {
      const error = err as ApiError
      setError(`激活配置失败: ${error.response?.data?.detail || error.message || '未知错误'}`)
      throw err
    } finally {
      setLoading(false)
    }
  }

  const testConnection = async (config: CreateApiConfigRequest): Promise<boolean> => {
    try {
      setLoading(true)
      const result = await ApiConfigService.testConnection(config)
      if (result) {
        showSuccess('连接测试成功')
      } else {
        setError('连接测试失败')
      }
      return result
    } catch (err: unknown) {
      const error = err as ApiError
      setError(`连接测试失败: ${error.message || '未知错误'}`)
      return false
    } finally {
      setLoading(false)
    }
  }

  const backupConfig = async () => {
    try {
      setLoading(true)
      setError(null)
      await ApiConfigService.backupConfig()
      showSuccess('配置备份成功')
    } catch (err: unknown) {
      const error = err as ApiError
      setError(`备份失败: ${error.response?.data?.detail || error.message || '未知错误'}`)
    } finally {
      setLoading(false)
    }
  }

  // 初始化数据
  const initialize = async () => {
    await Promise.all([
      fetchProfiles(),
      fetchCurrentConfig()
    ])
  }

  return {
    // 状态
    profiles,
    currentConfig,
    loading,
    error,
    
    // 计算属性
    activeProfile,
    profileCount,
    hasProfiles,
    
    // 方法
    fetchProfiles,
    fetchCurrentConfig,
    createProfile,
    updateProfile,
    deleteProfile,
    activateProfile,
    testConnection,
    backupConfig,
    initialize
  }
})