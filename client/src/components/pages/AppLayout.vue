<script setup lang="ts">
import { onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useAppStore } from '@/stores/app'
import Sidebar from '@/components/layout/Sidebar.vue'
import Topbar from '@/components/layout/Topbar.vue'

const router = useRouter()
const authStore = useAuthStore()
const appStore = useAppStore()

const loading = computed(() => authStore.loading || !authStore.initialized)

onMounted(async () => {
  // Fetch user if not initialized
  if (!authStore.initialized) {
    await authStore.fetchCurrentUser()
  }

  // Redirect to login if not authenticated
  if (!authStore.isAuthenticated) {
    router.replace('/login')
    return
  }

  // Load app data
  await Promise.all([
    appStore.fetchTeams(),
    appStore.fetchProjects()
  ])
})
</script>

<template>
  <div v-if="loading" class="min-h-screen bg-[#0d0d0d] flex items-center justify-center">
    <div class="animate-spin rounded-full h-8 w-8 border-2 border-indigo-500 border-t-transparent"></div>
  </div>

  <div v-else class="min-h-screen bg-[#0d0d0d] flex">
    <!-- Sidebar -->
    <Sidebar />

    <!-- Main content -->
    <div class="flex-1 flex flex-col min-w-0">
      <Topbar />
      <main class="flex-1 overflow-auto bg-[#0d0d0d]">
        <router-view />
      </main>
    </div>
  </div>
</template>
