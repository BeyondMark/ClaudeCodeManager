import axios from 'axios'
import type { AxiosResponse } from 'axios'
import type {
  ApiConfigProfile,
  CreateApiConfigRequest,
  UpdateApiConfigRequest,
  ApiConfigListResponse,
  ApplyConfigResponse,
  CurrentApiConfigResponse,
  StatusResponse
} from '../types/api'

// 动态获取API基础URL
const getApiBaseUrl = () => {
  // 获取当前访问的主机名（localhost 或 局域网IP）
  const hostname = window.location.hostname
  return `http://${hostname}:50000/api/v1/api-config`
}

// 配置axios默认值
const api = axios.create({
  baseURL: getApiBaseUrl(),
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json'
  }
})

// 响应拦截器
api.interceptors.response.use(
  (response: AxiosResponse) => response,
  (error) => {
    console.error('API请求错误:', error.response?.data || error.message)
    return Promise.reject(error)
  }
)

export class ApiConfigService {
  /**
   * 获取所有API配置
   */
  static async getProfiles(): Promise<ApiConfigListResponse> {
    const response = await api.get<ApiConfigListResponse>('/profiles')
    return response.data
  }

  /**
   * 创建新的API配置
   */
  static async createProfile(data: CreateApiConfigRequest): Promise<ApiConfigProfile> {
    const response = await api.post<ApiConfigProfile>('/profiles', data)
    return response.data
  }

  /**
   * 更新API配置
   */
  static async updateProfile(
    profileId: string, 
    data: UpdateApiConfigRequest
  ): Promise<{ success: boolean; message: string }> {
    const response = await api.put(`/profiles/${profileId}`, data)
    return response.data
  }

  /**
   * 删除API配置
   */
  static async deleteProfile(
    profileId: string
  ): Promise<{ success: boolean; message: string }> {
    const response = await api.delete(`/profiles/${profileId}`)
    return response.data
  }

  /**
   * 激活API配置
   */
  static async activateProfile(profileId: string): Promise<ApplyConfigResponse> {
    const response = await api.post<ApplyConfigResponse>(`/profiles/${profileId}/apply`)
    return response.data
  }

  /**
   * 获取当前配置
   */
  static async getCurrentConfig(): Promise<CurrentApiConfigResponse> {
    const response = await api.get<CurrentApiConfigResponse>('/current')
    return response.data
  }

  /**
   * 获取服务状态
   */
  static async getStatus(): Promise<StatusResponse> {
    const response = await api.get<StatusResponse>('/status')
    return response.data
  }

  /**
   * 备份配置
   */
  static async backupConfig(): Promise<{ success: boolean; message: string }> {
    const response = await api.post('/backup')
    return response.data
  }

  /**
   * 测试API配置连接
   */
  static async testConnection(config: CreateApiConfigRequest): Promise<boolean> {
    try {
      // 这里可以添加测试连接的逻辑
      const testApi = axios.create({
        baseURL: config.base_url,
        timeout: 5000,
        headers: {
          'Authorization': `Bearer ${config.api_key}`
        }
      })
      
      await testApi.get('/') // 简单的连接测试
      return true
    } catch (error) {
      console.error('连接测试失败:', error)
      return false
    }
  }
}

export default ApiConfigService