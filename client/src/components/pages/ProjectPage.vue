<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAppStore } from '@/stores/app'
import Button from '@/components/ui/Button.vue'
import Badge from '@/components/ui/Badge.vue'
import EmojiIcon from '@/components/ui/EmojiIcon.vue'
import {
  FolderKanban,
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

const projects = computed(() => appStore.projects)
const currentProject = computed(() => {
  const projectSlug = route.params.projectSlug as string
  return projects.value.find(p => p.slug === projectSlug)
})

// Placeholder issues
const issues = ref<unknown[]>([])
const loading = ref(false)

function getStatusBadge(status: string) {
  switch (status) {
    case 'in_progress':
      return { variant: 'success' as const, label: 'Active' }
    case 'backlog':
      return { variant: 'secondary' as const, label: 'Backlog' }
    case 'todo':
      return { variant: 'warning' as const, label: 'Todo' }
    case 'done':
      return { variant: 'primary' as const, label: 'Completed' }
    case 'canceled':
      return { variant: 'danger' as const, label: 'Canceled' }
    default:
      return { variant: 'secondary' as const, label: status }
  }
}
</script>

<template>
  <div v-if="currentProject" class="flex flex-col h-full">
    <!-- Project header -->
    <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900">
      <div class="flex items-center justify-between mb-4">
        <div class="flex items-center gap-3">
          <div 
            class="w-10 h-10 rounded-lg flex items-center justify-center"
            :style="{ backgroundColor: currentProject.color || '#6b7280' }"
          >
            <EmojiIcon 
              :name="currentProject.icon" 
              :fallback="currentProject.name.charAt(0)" 
              size="lg"
            />
          </div>
          <div>
            <h1 class="text-xl font-semibold text-gray-900 dark:text-gray-100">
              {{ currentProject.name }}
            </h1>
            <p v-if="currentProject.description" class="text-sm text-gray-500">
              {{ currentProject.description }}
            </p>
          </div>
        </div>
        <div class="flex items-center gap-2">
          <Badge :variant="getStatusBadge(currentProject.status).variant">
            {{ getStatusBadge(currentProject.status).label }}
          </Badge>
          <Button variant="ghost" size="sm">
            <Filter class="h-4 w-4" />
            Filter
          </Button>
          <Button size="sm">
            <Plus class="h-4 w-4" />
            Add issue
          </Button>
          <button class="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-md">
            <MoreHorizontal class="h-4 w-4 text-gray-500" />
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
        <div class="animate-spin rounded-full h-8 w-8 border-2 border-primary-600 border-t-transparent"></div>
      </div>

      <div v-else-if="issues.length === 0" class="flex flex-col items-center justify-center py-16">
        <div class="w-16 h-16 rounded-full bg-gray-100 dark:bg-gray-800 flex items-center justify-center mb-4">
          <Inbox class="h-8 w-8 text-gray-400" />
        </div>
        <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100 mb-1">
          No issues in this project
        </h3>
        <p class="text-sm text-gray-500 text-center max-w-sm mb-4">
          Add issues to this project to track progress and organize work.
        </p>
        <Button>
          <Plus class="h-4 w-4" />
          Add issue
        </Button>
      </div>

      <div v-else>
        <!-- Issue list will go here -->
      </div>
    </div>
  </div>

  <div v-else class="flex items-center justify-center h-full">
    <div class="text-center">
      <p class="text-gray-500">Project not found</p>
      <Button variant="ghost" class="mt-4" @click="router.push('/')">
        Go back home
      </Button>
    </div>
  </div>
</template>
