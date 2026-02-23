<script setup lang="ts">
import { computed, ref, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAppStore } from '@/stores/app'
import { useIssuesStore } from '@/stores/issues'
import { useEmojiStore } from '@/stores/emoji'
import { useUiStore } from '@/stores/ui'
import EmojiIcon from '@/components/ui/EmojiIcon.vue'
import IssueListItem from '@/components/issues/IssueListItem.vue'
import Dropdown from '@/components/ui/Dropdown.vue'
import DropdownItem from '@/components/ui/DropdownItem.vue'
import {
  Plus,
  Filter,
  MoreHorizontal,
  Calendar,
  Target,
  Inbox,
  Circle,
  Clock,
  CheckCircle2,
  X,
  Copy,
  Settings,
  Star
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const appStore = useAppStore()
const issuesStore = useIssuesStore()
const emojiStore = useEmojiStore()
const uiStore = useUiStore()

const loading = ref(true)

const projects = computed(() => appStore.projects)
const currentProject = computed(() => {
  const projectSlug = route.params.projectSlug as string
  return projects.value.find(p => p.slug === projectSlug)
})

// Filters
const statusFilter = ref<string | null>(null)
const priorityFilter = ref<number | null>(null)

// Status options
const statusOptions = [
  { value: 'backlog', label: 'Backlog', icon: Circle, color: 'text-gray-400' },
  { value: 'unstarted', label: 'Todo', icon: Circle, color: 'text-gray-400' },
  { value: 'started', label: 'In Progress', icon: Clock, color: 'text-yellow-500' },
  { value: 'completed', label: 'Done', icon: CheckCircle2, color: 'text-green-500' },
]

// Priority options
const priorityOptions = [
  { value: 1, label: 'Urgent', color: 'bg-red-500' },
  { value: 2, label: 'High', color: 'bg-orange-500' },
  { value: 3, label: 'Medium', color: 'bg-yellow-500' },
  { value: 4, label: 'Low', color: 'bg-blue-500' },
  { value: 0, label: 'No priority', color: 'bg-gray-500' },
]

// Get project issues
const projectIssues = computed(() => {
  if (!currentProject.value) return []
  return issuesStore.issues.filter(i => i.projectId === currentProject.value?.id)
})

// Filtered issues
const filteredIssues = computed(() => {
  let issues = projectIssues.value

  // Status filter
  if (statusFilter.value) {
    issues = issues.filter(i => {
      const state = i.workflowState
      return state?.stateType === statusFilter.value
    })
  }

  // Priority filter
  if (priorityFilter.value !== null) {
    issues = issues.filter(i => i.priority === priorityFilter.value)
  }

  return issues
})

const hasActiveFilters = computed(() => statusFilter.value !== null || priorityFilter.value !== null)
const activeFiltersCount = computed(() => {
  let count = 0
  if (statusFilter.value) count++
  if (priorityFilter.value !== null) count++
  return count
})

function clearFilters() {
  statusFilter.value = null
  priorityFilter.value = null
}

// Check if has emoji
function hasEmoji(icon?: string | null): boolean {
  return emojiStore.isRenderableEmoji(icon)
}

function getStatusBadge(state?: string) {
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

// Load issues
async function loadIssues() {
  if (!currentProject.value) return
  
  loading.value = true
  try {
    await issuesStore.fetchIssues({ projectId: currentProject.value.id })
  } finally {
    loading.value = false
  }
}

// Create issue
function handleAddIssue() {
  uiStore.openCreateIssueModal()
}

onMounted(() => {
  loadIssues()
})

// Reload when project changes
watch(() => route.params.projectSlug, () => {
  loadIssues()
})
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
          
          <!-- Filter dropdown -->
          <Dropdown align="right">
            <template #trigger>
              <button 
                :class="[
                  'flex items-center gap-1.5 px-3 py-1.5 text-sm rounded transition-colors',
                  hasActiveFilters
                    ? 'bg-indigo-500/20 text-indigo-400 border border-indigo-500/30'
                    : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
                ]"
              >
                <Filter class="h-4 w-4" />
                Filter
                <span v-if="hasActiveFilters" class="text-[11px] bg-indigo-500/30 px-1.5 rounded">
                  {{ activeFiltersCount }}
                </span>
              </button>
            </template>
            
            <div class="p-2 min-w-[200px]">
              <div class="text-[11px] font-medium text-gray-500 uppercase tracking-wider px-2 mb-1">Status</div>
              <DropdownItem 
                v-for="status in statusOptions" 
                :key="status.value"
                @click="statusFilter = statusFilter === status.value ? null : status.value"
              >
                <div class="flex items-center justify-between w-full">
                  <div class="flex items-center gap-2">
                    <component :is="status.icon" :class="['w-4 h-4', status.color]" />
                    <span>{{ status.label }}</span>
                  </div>
                  <CheckCircle2 v-if="statusFilter === status.value" class="w-4 h-4 text-indigo-400" />
                </div>
              </DropdownItem>
              
              <div class="border-t border-[#2a2a2a] my-2"></div>
              
              <div class="text-[11px] font-medium text-gray-500 uppercase tracking-wider px-2 mb-1">Priority</div>
              <DropdownItem 
                v-for="priority in priorityOptions" 
                :key="priority.value"
                @click="priorityFilter = priorityFilter === priority.value ? null : priority.value"
              >
                <div class="flex items-center justify-between w-full">
                  <div class="flex items-center gap-2">
                    <span :class="['w-2 h-2 rounded-full', priority.color]"></span>
                    <span>{{ priority.label }}</span>
                  </div>
                  <CheckCircle2 v-if="priorityFilter === priority.value" class="w-4 h-4 text-indigo-400" />
                </div>
              </DropdownItem>
              
              <template v-if="hasActiveFilters">
                <div class="border-t border-[#2a2a2a] my-2"></div>
                <DropdownItem @click="clearFilters" class="text-red-400">
                  <X class="w-4 h-4" />
                  Clear filters
                </DropdownItem>
              </template>
            </div>
          </Dropdown>
          
          <button 
            @click="handleAddIssue"
            class="flex items-center gap-1.5 px-3 py-1.5 text-sm bg-indigo-600 hover:bg-indigo-700 text-white rounded transition-colors"
          >
            <Plus class="h-4 w-4" />
            Add issue
          </button>
          <Dropdown align="right">
            <template #trigger>
              <button class="p-1.5 hover:bg-[#1a1a1a] rounded text-gray-500 hover:text-white transition-colors">
                <MoreHorizontal class="h-4 w-4" />
              </button>
            </template>
            <div class="py-1 min-w-[160px]">
              <DropdownItem @click="navigator.clipboard.writeText(window.location.href)">
                <Copy class="w-4 h-4" />
                Copy link
              </DropdownItem>
              <DropdownItem>
                <Star class="w-4 h-4" />
                Add to favorites
              </DropdownItem>
              <DropdownItem @click="router.push('/settings/teams')">
                <Settings class="w-4 h-4" />
                Project settings
              </DropdownItem>
            </div>
          </Dropdown>
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
        <div class="flex items-center gap-1.5">
          {{ filteredIssues.length }} issue{{ filteredIssues.length === 1 ? '' : 's' }}
        </div>
      </div>
    </div>

    <!-- Active filter pills -->
    <div v-if="hasActiveFilters" class="flex items-center gap-2 px-4 py-2 border-b border-[#1f1f1f]">
      <button
        v-if="statusFilter"
        @click="statusFilter = null"
        class="flex items-center gap-1.5 px-2 py-1 bg-[#1a1a1a] hover:bg-[#252525] rounded text-[12px] text-gray-300 transition-colors"
      >
        Status: {{ statusOptions.find(s => s.value === statusFilter)?.label }}
        <X class="w-3 h-3" />
      </button>
      <button
        v-if="priorityFilter !== null"
        @click="priorityFilter = null"
        class="flex items-center gap-1.5 px-2 py-1 bg-[#1a1a1a] hover:bg-[#252525] rounded text-[12px] text-gray-300 transition-colors"
      >
        Priority: {{ priorityOptions.find(p => p.value === priorityFilter)?.label }}
        <X class="w-3 h-3" />
      </button>
      <button
        @click="clearFilters"
        class="text-[12px] text-gray-500 hover:text-white transition-colors"
      >
        Clear all
      </button>
    </div>

    <!-- Content -->
    <div class="flex-1 overflow-auto">
      <div v-if="loading" class="flex items-center justify-center py-16">
        <div class="animate-spin rounded-full h-8 w-8 border-2 border-indigo-500 border-t-transparent"></div>
      </div>

      <div v-else-if="filteredIssues.length === 0" class="flex flex-col items-center justify-center py-16">
        <div class="w-16 h-16 rounded-full bg-[#1a1a1a] flex items-center justify-center mb-4">
          <Inbox class="h-8 w-8 text-gray-500" />
        </div>
        <h3 class="text-lg font-medium text-white mb-1">
          {{ hasActiveFilters ? 'No matching issues' : 'No issues in this project' }}
        </h3>
        <p class="text-sm text-gray-500 text-center max-w-sm mb-4">
          {{ hasActiveFilters 
            ? 'Try adjusting your filters to see more results.' 
            : 'Add issues to this project to track progress and organize work.'
          }}
        </p>
        <button 
          v-if="hasActiveFilters"
          @click="clearFilters"
          class="px-4 py-2 text-sm text-indigo-400 hover:text-indigo-300 transition-colors"
        >
          Clear filters
        </button>
        <button 
          v-else
          @click="handleAddIssue"
          class="flex items-center gap-1.5 px-4 py-2 text-sm bg-indigo-600 hover:bg-indigo-700 text-white rounded transition-colors"
        >
          <Plus class="h-4 w-4" />
          Add issue
        </button>
      </div>

      <div v-else class="divide-y divide-[#1f1f1f]">
        <IssueListItem
          v-for="issue in filteredIssues"
          :key="issue.id"
          :issue="issue"
        />
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
