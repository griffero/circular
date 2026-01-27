<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAppStore } from '@/stores/app'
import { useAuthStore } from '@/stores/auth'
import { api } from '@/api/client'
import Avatar from '@/components/ui/Avatar.vue'
import Badge from '@/components/ui/Badge.vue'
import type { Issue, User } from '@/types'
import {
  ChevronLeft,
  Filter,
  LayoutGrid,
  Star,
  Circle,
  CheckCircle2,
  XCircle,
  Clock,
  AlertCircle
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const appStore = useAppStore()
const authStore = useAuthStore()

const userId = computed(() => route.params.userId as string)
const user = ref<User | null>(null)
const loading = ref(true)
const activeTab = ref<'assigned' | 'created'>('assigned')

// Issues
const assignedIssues = ref<Issue[]>([])
const createdIssues = ref<Issue[]>([])
const issuesLoading = ref(false)

// Fetch user details
async function fetchUser() {
  loading.value = true
  try {
    const data = await api.get<{ user: User }>(`/api/v1/users/${userId.value}`)
    user.value = data.user
  } catch (err) {
    console.error('Failed to fetch user:', err)
  } finally {
    loading.value = false
  }
}

// Fetch assigned issues
async function fetchAssignedIssues() {
  issuesLoading.value = true
  try {
    const data = await api.get<{ issues: Issue[] }>(`/api/v1/issues?assignee_id=${userId.value}`)
    assignedIssues.value = data.issues
  } catch (err) {
    console.error('Failed to fetch assigned issues:', err)
  } finally {
    issuesLoading.value = false
  }
}

// Fetch created issues
async function fetchCreatedIssues() {
  issuesLoading.value = true
  try {
    const data = await api.get<{ issues: Issue[] }>(`/api/v1/issues?creator_id=${userId.value}`)
    createdIssues.value = data.issues
  } catch (err) {
    console.error('Failed to fetch created issues:', err)
  } finally {
    issuesLoading.value = false
  }
}

// Group issues by status
const groupedIssues = computed(() => {
  const issues = activeTab.value === 'assigned' ? assignedIssues.value : createdIssues.value
  
  const groups: Record<string, Issue[]> = {
    'In Progress': [],
    'In Review': [],
    'Todo': [],
    'Backlog': [],
    'Done': [],
    'Canceled': []
  }
  
  issues.forEach(issue => {
    const status = issue.status || 'Backlog'
    if (status === 'in_progress' || status === 'started') {
      groups['In Progress'].push(issue)
    } else if (status === 'in_review') {
      groups['In Review'].push(issue)
    } else if (status === 'todo' || status === 'unstarted') {
      groups['Todo'].push(issue)
    } else if (status === 'backlog' || status === 'triage') {
      groups['Backlog'].push(issue)
    } else if (status === 'done' || status === 'completed') {
      groups['Done'].push(issue)
    } else if (status === 'canceled' || status === 'cancelled') {
      groups['Canceled'].push(issue)
    } else {
      groups['Backlog'].push(issue)
    }
  })
  
  return groups
})

function getStatusIcon(status: string) {
  switch (status) {
    case 'In Progress':
      return { icon: Clock, class: 'text-yellow-500' }
    case 'In Review':
      return { icon: AlertCircle, class: 'text-blue-500' }
    case 'Todo':
      return { icon: Circle, class: 'text-gray-400' }
    case 'Backlog':
      return { icon: Circle, class: 'text-gray-500' }
    case 'Done':
      return { icon: CheckCircle2, class: 'text-green-500' }
    case 'Canceled':
      return { icon: XCircle, class: 'text-gray-400' }
    default:
      return { icon: Circle, class: 'text-gray-400' }
  }
}

function getPriorityLabel(priority: number | null) {
  switch (priority) {
    case 1: return 'Urgent'
    case 2: return 'High'
    case 3: return 'Medium'
    case 4: return 'Low'
    default: return 'No priority'
  }
}

function getPriorityClass(priority: number | null) {
  switch (priority) {
    case 1: return 'text-red-500'
    case 2: return 'text-orange-500'
    case 3: return 'text-yellow-500'
    case 4: return 'text-blue-500'
    default: return 'text-gray-400'
  }
}

function goToIssue(issue: Issue) {
  router.push(`/issue/${issue.id}`)
}

function formatDate(dateStr: string | null): string {
  if (!dateStr) return ''
  const date = new Date(dateStr)
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
}

// Computed for current user profile
const isCurrentUser = computed(() => {
  return authStore.user?.id === userId.value
})

onMounted(() => {
  fetchUser()
  fetchAssignedIssues()
})

watch(activeTab, (newTab) => {
  if (newTab === 'created' && createdIssues.value.length === 0) {
    fetchCreatedIssues()
  }
})

watch(userId, () => {
  fetchUser()
  fetchAssignedIssues()
  createdIssues.value = []
  activeTab.value = 'assigned'
})
</script>

<template>
  <div class="h-full flex flex-col bg-[#0d0d0d]">
    <!-- Header -->
    <div class="flex items-center justify-between px-4 py-3 border-b border-[#1f1f1f]">
      <div class="flex items-center gap-4">
        <!-- User info -->
        <div v-if="user" class="flex items-center gap-3">
          <Avatar :name="user.name" :src="user.avatarUrl" size="lg" />
          <div>
            <h1 class="text-lg font-semibold text-white flex items-center gap-2">
              {{ user.displayName || user.name }}
              <span v-if="isCurrentUser" class="text-xs text-gray-500 px-1.5 py-0.5 bg-gray-800 rounded">You</span>
            </h1>
            <p class="text-sm text-gray-500">{{ user.email }}</p>
          </div>
        </div>
        <div v-else class="animate-pulse flex items-center gap-3">
          <div class="w-12 h-12 bg-gray-800 rounded-full"></div>
          <div>
            <div class="h-5 w-32 bg-gray-800 rounded mb-1"></div>
            <div class="h-4 w-40 bg-gray-800 rounded"></div>
          </div>
        </div>
      </div>
      
      <div class="flex items-center gap-2">
        <button class="flex items-center gap-2 px-3 py-1.5 text-sm text-gray-400 hover:text-white hover:bg-[#1a1a1a] rounded transition-colors">
          <Star class="w-4 h-4" />
        </button>
      </div>
    </div>

    <!-- Tabs -->
    <div class="flex items-center gap-1 px-4 py-2 border-b border-[#1f1f1f]">
      <button
        @click="activeTab = 'assigned'"
        :class="[
          'px-3 py-1.5 text-sm rounded-md transition-colors',
          activeTab === 'assigned'
            ? 'bg-[#1a1a1a] text-white'
            : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
        ]"
      >
        Assigned
      </button>
      <button
        @click="activeTab = 'created'"
        :class="[
          'px-3 py-1.5 text-sm rounded-md transition-colors',
          activeTab === 'created'
            ? 'bg-[#1a1a1a] text-white'
            : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
        ]"
      >
        Created
      </button>
      
      <div class="flex-1"></div>
      
      <button class="flex items-center gap-2 px-3 py-1.5 text-sm text-gray-400 hover:text-white hover:bg-[#1a1a1a] rounded transition-colors">
        <Filter class="w-4 h-4" />
        Filter
      </button>
      <button class="flex items-center gap-2 px-3 py-1.5 text-sm text-gray-400 hover:text-white hover:bg-[#1a1a1a] rounded transition-colors">
        <LayoutGrid class="w-4 h-4" />
        Display
      </button>
    </div>

    <!-- Content -->
    <div class="flex-1 overflow-y-auto">
      <div v-if="issuesLoading" class="flex items-center justify-center py-12">
        <div class="animate-spin rounded-full h-8 w-8 border-2 border-indigo-600 border-t-transparent"></div>
      </div>
      
      <div v-else class="divide-y divide-[#1f1f1f]">
        <template v-for="(issues, status) in groupedIssues" :key="status">
          <div v-if="issues.length > 0" class="py-1">
            <!-- Status header -->
            <div class="flex items-center gap-2 px-4 py-2 text-sm">
              <component
                :is="getStatusIcon(status).icon"
                :class="['w-4 h-4', getStatusIcon(status).class]"
              />
              <span class="text-gray-400">{{ status }}</span>
              <span class="text-gray-600">{{ issues.length }}</span>
            </div>
            
            <!-- Issues list -->
            <div>
              <div
                v-for="issue in issues"
                :key="issue.id"
                @click="goToIssue(issue)"
                class="flex items-center gap-3 px-4 py-2 hover:bg-[#151515] cursor-pointer group"
              >
                <!-- Priority indicator -->
                <div class="w-6 flex justify-center">
                  <span 
                    v-if="issue.priority && issue.priority <= 2"
                    class="text-xs"
                    :class="getPriorityClass(issue.priority)"
                  >
                    !!!
                  </span>
                </div>
                
                <!-- Status icon -->
                <component
                  :is="getStatusIcon(status).icon"
                  :class="['w-4 h-4 flex-shrink-0', getStatusIcon(status).class]"
                />
                
                <!-- Issue identifier -->
                <span class="text-xs text-gray-500 flex-shrink-0 w-20">
                  {{ issue.identifier }}
                </span>
                
                <!-- Issue title -->
                <span class="flex-1 text-sm text-gray-200 truncate">
                  {{ issue.title }}
                </span>
                
                <!-- Labels -->
                <div v-if="issue.labels && issue.labels.length > 0" class="flex items-center gap-1">
                  <span
                    v-for="label in issue.labels.slice(0, 2)"
                    :key="label.id"
                    class="px-1.5 py-0.5 text-xs rounded"
                    :style="{ backgroundColor: label.color + '20', color: label.color }"
                  >
                    {{ label.name }}
                  </span>
                </div>
                
                <!-- Project -->
                <span v-if="issue.project" class="text-xs text-gray-500 flex-shrink-0">
                  {{ issue.project.name }}
                </span>
                
                <!-- Due date -->
                <span v-if="issue.dueDate" class="text-xs text-gray-500 flex-shrink-0 w-16 text-right">
                  {{ formatDate(issue.dueDate) }}
                </span>
              </div>
            </div>
          </div>
        </template>
        
        <!-- Empty state -->
        <div 
          v-if="Object.values(groupedIssues).every(g => g.length === 0)"
          class="flex flex-col items-center justify-center py-16 text-gray-500"
        >
          <Circle class="w-12 h-12 mb-4 text-gray-600" />
          <p>No {{ activeTab }} issues</p>
        </div>
      </div>
    </div>
  </div>
</template>
