import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { User, AuthResponse } from '@/types'
import { api } from '@/api/client'

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const loading = ref(false)
  const initialized = ref(false)

  const isAuthenticated = computed(() => !!user.value)
  const isOwner = computed(() => user.value?.role === 'owner')
  const isAdmin = computed(() => ['owner', 'admin'].includes(user.value?.role || ''))

  function setAuthData(data: AuthResponse) {
    user.value = data.user
    initialized.value = true
  }

  // Send magic link to email
  async function sendMagicLink(email: string) {
    loading.value = true
    try {
      const data = await api.post<{ message: string }>('/api/v1/auth/magic-link', { email })
      return data
    } finally {
      loading.value = false
    }
  }

  // Verify magic link token and log in
  async function verifyMagicLink(token: string) {
    loading.value = true
    try {
      const data = await api.post<AuthResponse>('/api/v1/auth/verify-magic-link', { token })
      setAuthData(data)
      return data
    } finally {
      loading.value = false
    }
  }

  // Token login (one-time) and log in
  async function tokenLogin(token: string) {
    loading.value = true
    try {
      const data = await api.post<AuthResponse>('/api/v1/auth/token-login', { token })
      setAuthData(data)
      return data
    } finally {
      loading.value = false
    }
  }

  async function logout() {
    try {
      await api.delete('/api/v1/auth/logout')
    } catch {
      // Ignore errors on logout
    } finally {
      user.value = null
      initialized.value = false
    }
  }

  async function fetchCurrentUser() {
    loading.value = true
    try {
      const data = await api.get<AuthResponse>('/api/v1/auth/me')
      setAuthData(data)
      return data
    } catch {
      initialized.value = true
      return null
    } finally {
      loading.value = false
    }
  }

  return {
    // State
    user,
    loading,
    initialized,

    // Computed
    isAuthenticated,
    isOwner,
    isAdmin,

    // Actions
    setAuthData,
    sendMagicLink,
    verifyMagicLink,
    tokenLogin,
    logout,
    fetchCurrentUser,
  }
})
