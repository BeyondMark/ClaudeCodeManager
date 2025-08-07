// API类型定义
export interface ApiConfigProfile {
  id: string
  name: string
  api_key: string
  base_url: string
  created_at: string
  is_active: boolean
}

export interface CreateApiConfigRequest {
  name: string
  api_key: string
  base_url: string
}

export interface UpdateApiConfigRequest {
  name?: string
  api_key?: string
  base_url?: string
}

export interface ApiConfigListResponse {
  profiles: ApiConfigProfile[]
  active_profile_id: string | null
  total_count: number
}

export interface ApplyConfigResponse {
  success: boolean
  message: string
  applied_profile: ApiConfigProfile
}

export interface CurrentApiConfigResponse {
  api_key: string
  base_url: string
  profile_name: string | null
  profile_id: string | null
  source: string
}

export interface StatusResponse {
  status: string
  api_config_count: number
  active_profile_id: string | null
  claude_settings_exists: boolean
}

export interface ApiResponse<T = unknown> {
  data?: T
  success?: boolean
  message?: string
  error?: string
}