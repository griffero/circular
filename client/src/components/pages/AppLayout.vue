<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useAppStore } from '@/stores/app'
import { useEmojiStore } from '@/stores/emoji'
import Sidebar from '@/components/layout/Sidebar.vue'
import Topbar from '@/components/layout/Topbar.vue'

const route = useRoute()
const appStore = useAppStore()
const emojiStore = useEmojiStore()

const loading = ref(true)

// Pages that have their own header (don't show Topbar)
const pagesWithOwnHeader = [
  'home',
  'projects', 
  'initiatives',
  'inbox', 
  'my-issues',
  'views',
  'team', 'team-triage', 'team-issues', 'team-active', 'team-backlog', 'team-board', 'team-cycles', 'team-cycles-current', 'team-cycles-upcoming', 'team-projects', 'team-views',
  'project',
  'issue',
  'view',
  'user-profile'
]
const showTopbar = computed(() => !pagesWithOwnHeader.includes(route.name as string))

function withTimeout<T>(promise: Promise<T>, ms: number, label: string): Promise<T> {
  return Promise.race([
    promise,
    new Promise<T>((_, reject) =>
      setTimeout(() => reject(new Error(`Timed out loading ${label}`)), ms)
    ),
  ])
}

onMounted(async () => {
  try {
    // Load critical app data first so the shell can render quickly.
    // Use timeouts to avoid getting stuck forever in shell loading state.
    const startupResults = await Promise.allSettled([
      withTimeout(appStore.fetchTeams(), 10000, 'teams'),
      withTimeout(appStore.fetchProjects(), 10000, 'projects'),
      withTimeout(emojiStore.fetchEmojis(), 10000, 'emojis'),
    ])
    for (const result of startupResults) {
      if (result.status === 'rejected') {
        console.error('Startup data load failed:', result.reason)
      }
    }

    appStore.fetchProjectUpdates().catch((err) => {
      console.error('Failed to load project updates:', err)
    })
  } catch (err) {
    console.error('Failed to load app data:', err)
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div
    v-if="loading"
    data-testid="app-shell-loading"
    class="h-screen bg-[var(--linear-bg)] flex items-center justify-center"
  >
    <div class="animate-spin rounded-full h-8 w-8 border-2 border-[var(--linear-accent)] border-t-transparent"></div>
  </div>

  <div
    v-else
    data-testid="app-shell-ready"
    class="h-screen bg-[var(--linear-bg)] flex overflow-hidden"
  >
    <!-- Sidebar -->
    <div class="hidden md:block h-full">
      <Sidebar />
    </div>

    <!-- Main content -->
    <div class="flex-1 flex flex-col min-w-0 overflow-hidden">
      <Topbar v-if="showTopbar" />
      <main class="flex-1 overflow-auto bg-[var(--linear-bg)] min-h-0">
        <router-view />
      </main>
    </div>
  </div>
</template>
