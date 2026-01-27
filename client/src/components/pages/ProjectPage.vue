<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAppStore } from '@/stores/app'
import { useEmojiStore } from '@/stores/emoji'
import EmojiIcon from '@/components/ui/EmojiIcon.vue'
import {
  Plus,
  Filter,
  MoreHorizontal,
  Calendar,
  Target,
  Inbox
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const appStore = useAppStore()
const emojiStore = useEmojiStore()

const projects = computed(() => appStore.projects)
const currentProject = computed(() => {
  const projectSlug = route.params.projectSlug as string
  return projects.value.find(p => p.slug === projectSlug)
})

// Placeholder issues
const issues = ref<unknown[]>([])
const loading = ref(false)

// Check if has emoji
function hasEmoji(icon?: string | null): boolean {
  if (!icon) return false
  if (emojiStore.getEmojiUrl(icon)) return true
  const stripped = icon.replace(/^:|:$/g, '')
  return /^[\p{Emoji}\u200d]+$/u.test(stripped) && stripped.length <= 8
}

function getStatusBadge(state: string) {
  switch (state) {
    case 'started':
      return { class: 'bg-green-500/20 text-green-400', label: 'Active' }
    case 'planned':
      return { class: 'bg-blue-500/20 text-blue-400', label: 'Planned' }
    case 'paused':
      return { class: 'bg-yellow-500/20 text-yellow-400', label: 'Paused' }
    case 'completed':
      return { class: 'bg-emerald-500/20 text-emerald-400', label: 'Completed' }
    case 'canceled':
      return { class: 'bg-red-500/20 text-red-400', label: 'Canceled' }
    default:
      return { class: 'bg-gray-500/20 text-gray-400', label: 'Backlog' }
  }
}
</script>

<template>
  <div v-if="currentProject" class="flex flex-col h-full bg-[#0d0d0d]">
    <!-- Project header -->
    <div class="px-4 py-3 border-b border-[#1f1f1f]">
      <div class="flex items-center justify-between mb-3">
        <div class="flex items-center gap-3">
          <div 
            class="w-10 h-10 rounded-lg flex items-center justify-center"
            :style="hasEmoji(currentProject.icon) ? {} : { backgroundColor: currentProject.color || '#6366f1' }"
          >
            <EmojiIcon 
              :name="currentProject.icon" 
              :fallback="currentProject.name.charAt(0)" 
              size="lg"
            />
          </div>
          <div>
            <h1 class="text-lg font-semibold text-white">
              {{ currentProject.name }}
            </h1>
            <p v-if="currentProject.description" class="text-sm text-gray-500">
              {{ currentProject.description }}
            </p>
          </div>
        </div>
        <div class="flex items-center gap-2">
          <span 
            class="text-xs px-2 py-1 rounded"
            :class="getStatusBadge(currentProject.state).class"
          >
            {{ getStatusBadge(currentProject.state).label }}
          </span>
          <button class="flex items-center gap-1.5 px-3 py-1.5 text-sm text-gray-400 hover:text-white hover:bg-[#1a1a1a] rounded transition-colors">
            <Filter class="h-4 w-4" />
            Filter
          </button>
          <button class="flex items-center gap-1.5 px-3 py-1.5 text-sm bg-indigo-600 hover:bg-indigo-700 text-white rounded transition-colors">
            <Plus class="h-4 w-4" />
            Add issue
          </button>
          <button class="p-1.5 hover:bg-[#1a1a1a] rounded text-gray-500 hover:text-white transition-colors">
            <MoreHorizontal class="h-4 w-4" />
          </button>
        </div>
      </div>

      <!-- Project meta -->
      <div class="flex items-center gap-6 text-sm text-gray-500">
        <div v-if="currentProject.startDate" class="flex items-center gap-1.5">
          <Calendar class="h-4 w-4" />
          Started {{ currentProject.startDate }}
        </div>
        <div v-if="currentProject.targetDate" class="flex items-center gap-1.5">
          <Target class="h-4 w-4" />
          Target {{ currentProject.targetDate }}
        </div>
      </div>
    </div>

    <!-- Content -->
    <div class="flex-1 overflow-auto p-6">
      <div v-if="loading" class="flex items-center justify-center py-16">
        <div class="animate-spin rounded-full h-8 w-8 border-2 border-indigo-500 border-t-transparent"></div>
      </div>

      <div v-else-if="issues.length === 0" class="flex flex-col items-center justify-center py-16">
        <div class="w-16 h-16 rounded-full bg-[#1a1a1a] flex items-center justify-center mb-4">
          <Inbox class="h-8 w-8 text-gray-500" />
        </div>
        <h3 class="text-lg font-medium text-white mb-1">
          No issues in this project
        </h3>
        <p class="text-sm text-gray-500 text-center max-w-sm mb-4">
          Add issues to this project to track progress and organize work.
        </p>
        <button class="flex items-center gap-1.5 px-4 py-2 text-sm bg-indigo-600 hover:bg-indigo-700 text-white rounded transition-colors">
          <Plus class="h-4 w-4" />
          Add issue
        </button>
      </div>

      <div v-else>
        <!-- Issue list will go here -->
      </div>
    </div>
  </div>

  <div v-else class="flex items-center justify-center h-full bg-[#0d0d0d]">
    <div class="text-center">
      <p class="text-gray-500">Project not found</p>
      <button 
        @click="router.push('/')"
        class="mt-4 px-4 py-2 text-sm text-gray-400 hover:text-white hover:bg-[#1a1a1a] rounded transition-colors"
      >
        Go back home
      </button>
    </div>
  </div>
</template>
