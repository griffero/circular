<script setup lang="ts">
import { onMounted, computed } from 'vue'
import { useAppStore } from '@/stores/app'
import Sidebar from '@/components/layout/Sidebar.vue'
import Topbar from '@/components/layout/Topbar.vue'

const appStore = useAppStore()

const loading = computed(() => appStore.loading)

onMounted(async () => {
  // Load app data (auth is already handled by router guard)
  await Promise.all([
    appStore.fetchTeams(),
    appStore.fetchProjects()
  ])
})
</script>

<template>
  <div v-if="loading" class="h-screen bg-[#0d0d0d] flex items-center justify-center">
    <div class="animate-spin rounded-full h-8 w-8 border-2 border-indigo-500 border-t-transparent"></div>
  </div>

  <div v-else class="h-screen bg-[#0d0d0d] flex overflow-hidden">
    <!-- Sidebar -->
    <Sidebar />

    <!-- Main content -->
    <div class="flex-1 flex flex-col min-w-0 overflow-hidden">
      <Topbar />
      <main class="flex-1 overflow-auto bg-[#0d0d0d]">
        <router-view />
      </main>
    </div>
  </div>
</template>
