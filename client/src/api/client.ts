import type { ApiError } from '@/types'

const BASE_URL = import.meta.env.VITE_API_URL || ''

interface RequestOptions extends Omit<RequestInit, 'body'> {
  body?: unknown
  skipAuthRedirect?: boolean // Skip automatic redirect on 401
}

class ApiClient {
  private baseUrl: string

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl
  }

  private async request<T>(endpoint: string, options: RequestOptions = {}): Promise<T> {
    const { body, headers: customHeaders, skipAuthRedirect, ...rest } = options

    const headers: HeadersInit = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...customHeaders,
    }

    const config: RequestInit = {
      ...rest,
      headers,
      credentials: 'include', // Include cookies for session auth
    }

    if (body) {
      config.body = JSON.stringify(body)
    }

    const url = endpoint.startsWith('http') ? endpoint : `${this.baseUrl}${endpoint}`
    const response = await fetch(url, config)

    // Handle 401 Unauthorized - redirect to login
    if (response.status === 401 && !skipAuthRedirect) {
      // Only redirect if we're not already on an auth page
      const isAuthPage = window.location.pathname.startsWith('/login') || 
                         window.location.pathname.startsWith('/auth')
      if (!isAuthPage) {
        window.location.href = '/login'
        throw new Error('Session expired')
      }
    }

    // Handle no content response
    if (response.status === 204) {
      return {} as T
    }

    const data = await response.json()

    if (!response.ok) {
      const error = data as ApiError
      throw new Error(error.error || error.errors?.join(', ') || error.message || 'Request failed')
    }

    return data as T
  }

  async get<T>(endpoint: string, options?: RequestOptions): Promise<T> {
    return this.request<T>(endpoint, { ...options, method: 'GET' })
  }

  async post<T>(endpoint: string, body?: unknown, options?: RequestOptions): Promise<T> {
    return this.request<T>(endpoint, { ...options, method: 'POST', body })
  }

  async put<T>(endpoint: string, body?: unknown, options?: RequestOptions): Promise<T> {
    return this.request<T>(endpoint, { ...options, method: 'PUT', body })
  }

  async patch<T>(endpoint: string, body?: unknown, options?: RequestOptions): Promise<T> {
    return this.request<T>(endpoint, { ...options, method: 'PATCH', body })
  }

  async delete<T>(endpoint: string, options?: RequestOptions): Promise<T> {
    return this.request<T>(endpoint, { ...options, method: 'DELETE' })
  }
}

export const api = new ApiClient(BASE_URL)
export default api
