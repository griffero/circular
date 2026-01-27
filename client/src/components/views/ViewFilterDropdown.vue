<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useAppStore } from '@/stores/app'
import { useIssuesStore, type IssueFilters } from '@/stores/issues'
import { useAuthStore } from '@/stores/auth'
import { cn } from '@/utils/cn'
import {
  Users,
  Circle,
  CircleDot,
  Clock,
  CheckCircle2,
  XCircle,
  BarChart3,
  Tag,
  FolderKanban,
  Calendar,
  ChevronRight,
  Search,
  AlertTriangle,
  ArrowUp,
  ArrowRight,
  ArrowDown,
  Minus,
  User,
  UserX,
  Layers
} from 'lucide-vue-next'

const props = defineProps<{
  filters: IssueFilters
}>()

const emit = defineEmits<{
  (e: 'update:filters', filters: IssueFilters): void
  (e: 'close'): void
}>()

const appStore = useAppStore()
const issuesStore = useIssuesStore()
const authStore = useAuthStore()

const activeSubmenu = ref<string | null>(null)
const searchQuery = ref('')

// Data
const teams = computed(() => appStore.teams)
const projects = computed(() => appStore.projects)
const users = computed(() => appStore.users)
const labels = computed(() => issuesStore.labels)
const workflowStates = computed(() => issuesStore.workflowStates)
const currentUser = computed(() => authStore.user)

// Fetch data on mount
onMounted(async () => {
  if (appStore.users.length === 0) {
    await appStore.fetchUsers()
  }
  if (issuesStore.labels.length === 0) {
    await issuesStore.fetchLabels()
  }
})

// Filter menu items (only logical ones that exist in our system)
const filterMenuItems = [
  { id: 'team', label: 'Team', icon: Users },
  { id: 'status', label: 'Status', icon: Circle },
  { id: 'assignee', label: 'Assignee', icon: User },
  { id: 'creator', label: 'Creator', icon: User },
  { id: 'priority', label: 'Priority', icon: BarChart3 },
  { id: 'labels', label: 'Labels', icon: Tag },
  { id: 'project', label: 'Project', icon: FolderKanban },
  { id: 'dates', label: 'Dates', icon: Calendar },
]

// Status options
const statusOptions = [
  { value: 'backlog', label: 'Backlog', icon: CircleDot, color: 'text-gray-400' },
  { value: 'todo', label: 'Todo', icon: Circle, color: 'text-gray-500' },
  { value: 'in_progress', label: 'In Progress', icon: Clock, color: 'text-yellow-500' },
  { value: 'in_review', label: 'In Review', icon: Clock, color: 'text-blue-500' },
  { value: 'done', label: 'Done', icon: CheckCircle2, color: 'text-green-500' },
  { value: 'canceled', label: 'Canceled', icon: XCircle, color: 'text-gray-400' },
]

// Priority options
const priorityOptions = [
  { value: 0, label: 'No priority', icon: Minus, color: 'text-gray-400' },
  { value: 1, label: 'Urgent', icon: AlertTriangle, color: 'text-red-500' },
  { value: 2, label: 'High', icon: ArrowUp, color: 'text-orange-500' },
  { value: 3, label: 'Medium', icon: ArrowRight, color: 'text-yellow-500' },
  { value: 4, label: 'Low', icon: ArrowDown, color: 'text-blue-500' },
]

// Filtered items based on search
const filteredUsers = computed(() => {
  if (!searchQuery.value) return users.value
  const query = searchQuery.value.toLowerCase()
  return users.value.filter(u => 
    u.name.toLowerCase().includes(query) || 
    u.email.toLowerCase().includes(query)
  )
})

const filteredLabels = computed(() => {
  if (!searchQuery.value) return labels.value
  const query = searchQuery.value.toLowerCase()
  return labels.value.filter(l => l.name.toLowerCase().includes(query))
})

const filteredTeams = computed(() => {
  if (!searchQuery.value) return teams.value
  const query = searchQuery.value.toLowerCase()
  return teams.value.filter(t => t.name.toLowerCase().includes(query))
})

const filteredProjects = computed(() => {
  if (!searchQuery.value) return projects.value
  const query = searchQuery.value.toLowerCase()
  return projects.value.filter(p => p.name.toLowerCase().includes(query))
})

// Actions
function openSubmenu(id: string) {
  activeSubmenu.value = id
  searchQuery.value = ''
}

function closeSubmenu() {
  activeSubmenu.value = null
  searchQuery.value = ''
}

function selectFilter(key: keyof IssueFilters, value: unknown) {
  emit('update:filters', { ...props.filters, [key]: value })
  closeSubmenu()
}

function getInitials(name: string): string {
  return name
    .split(' ')
    .map(n => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)
}

function getUserColor(name: string): string {
  const colors = ['#6366f1', '#8b5cf6', '#ec4899', '#f43f5e', '#f97316', '#eab308', '#22c55e', '#14b8a6', '#06b6d4', '#3b82f6']
  let hash = 0
  for (let i = 0; i < name.length; i++) {
    hash = name.charCodeAt(i) + ((hash << 5) - hash)
  }
  return colors[Math.abs(hash) % colors.length]
}
</script>

<template>
  <div class="w-[220px] bg-[#1a1a1a] border border-[#2a2a2a] rounded-lg shadow-xl overflow-hidden">
    <!-- Main menu -->
    <div v-if="!activeSubmenu" class="py-1">
      <!-- Search -->
      <div class="px-2 py-1.5">
        <div class="relative">
          <Search class="absolute left-2 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-gray-500" />
          <input
            type="text"
            placeholder="Add Filter..."
            class="w-full bg-transparent text-[13px] text-white placeholder-gray-500 pl-7 pr-2 py-1 focus:outline-none"
          />
          <span class="absolute right-2 top-1/2 -translate-y-1/2 text-[10px] text-gray-600 bg-[#2a2a2a] px-1 rounded">F</span>
        </div>
      </div>

      <div class="border-t border-[#2a2a2a] my-1" />

      <!-- Filter options -->
      <div class="max-h-[400px] overflow-y-auto">
        <button
          v-for="item in filterMenuItems"
          :key="item.id"
          @click="openSubmenu(item.id)"
          class="w-full flex items-center justify-between px-3 py-1.5 text-[13px] text-gray-300 hover:bg-[#2a2a2a] transition-colors"
        >
          <div class="flex items-center gap-2">
            <component :is="item.icon" class="w-4 h-4 text-gray-500" />
            <span>{{ item.label }}</span>
          </div>
          <ChevronRight class="w-3.5 h-3.5 text-gray-500" />
        </button>
      </div>
    </div>

    <!-- Team submenu -->
    <div v-else-if="activeSubmenu === 'team'" class="py-1">
      <div class="px-2 py-1.5">
        <div class="relative">
          <Search class="absolute left-2 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-gray-500" />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Filter..."
            class="w-full bg-transparent text-[13px] text-white placeholder-gray-500 pl-7 pr-2 py-1 focus:outline-none"
            autofocus
          />
        </div>
      </div>

      <div class="border-t border-[#2a2a2a] my-1" />

      <div class="max-h-[300px] overflow-y-auto">
        <button
          v-for="team in filteredTeams"
          :key="team.id"
          @click="selectFilter('teamId', team.id)"
          :class="cn(
            'w-full flex items-center gap-2 px-3 py-1.5 text-[13px] transition-colors',
            filters.teamId === team.id ? 'bg-[#2a2a2a] text-white' : 'text-gray-300 hover:bg-[#2a2a2a]'
          )"
        >
          <div 
            class="w-5 h-5 rounded flex items-center justify-center text-[10px] font-medium text-white"
            :style="{ backgroundColor: team.color || '#6366f1' }"
          >
            {{ team.icon || team.key.substring(0, 2).toUpperCase() }}
          </div>
          <span>{{ team.name }}</span>
        </button>
      </div>

      <div class="border-t border-[#2a2a2a] mt-1 pt-1">
        <button
          @click="closeSubmenu"
          class="w-full px-3 py-1.5 text-[13px] text-gray-400 hover:text-white hover:bg-[#2a2a2a] text-left transition-colors"
        >
          ← Back
        </button>
      </div>
    </div>

    <!-- Status submenu -->
    <div v-else-if="activeSubmenu === 'status'" class="py-1">
      <div class="px-2 py-1.5">
        <div class="relative">
          <Search class="absolute left-2 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-gray-500" />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Filter..."
            class="w-full bg-transparent text-[13px] text-white placeholder-gray-500 pl-7 pr-2 py-1 focus:outline-none"
            autofocus
          />
        </div>
      </div>

      <div class="border-t border-[#2a2a2a] my-1" />

      <div class="max-h-[300px] overflow-y-auto">
        <button
          v-for="status in statusOptions"
          :key="status.value"
          @click="selectFilter('status', status.value)"
          :class="cn(
            'w-full flex items-center gap-2 px-3 py-1.5 text-[13px] transition-colors',
            filters.status === status.value ? 'bg-[#2a2a2a] text-white' : 'text-gray-300 hover:bg-[#2a2a2a]'
          )"
        >
          <component :is="status.icon" :class="cn('w-4 h-4', status.color)" />
          <span>{{ status.label }}</span>
        </button>
      </div>

      <div class="border-t border-[#2a2a2a] mt-1 pt-1">
        <button
          @click="closeSubmenu"
          class="w-full px-3 py-1.5 text-[13px] text-gray-400 hover:text-white hover:bg-[#2a2a2a] text-left transition-colors"
        >
          ← Back
        </button>
      </div>
    </div>

    <!-- Assignee submenu -->
    <div v-else-if="activeSubmenu === 'assignee'" class="py-1">
      <div class="px-2 py-1.5">
        <div class="relative">
          <Search class="absolute left-2 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-gray-500" />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Filter..."
            class="w-full bg-transparent text-[13px] text-white placeholder-gray-500 pl-7 pr-2 py-1 focus:outline-none"
            autofocus
          />
        </div>
      </div>

      <div class="border-t border-[#2a2a2a] my-1" />

      <div class="max-h-[300px] overflow-y-auto">
        <!-- Special options -->
        <button
          @click="selectFilter('assigneeId', 'unassigned')"
          :class="cn(
            'w-full flex items-center gap-2 px-3 py-1.5 text-[13px] transition-colors',
            filters.assigneeId === 'unassigned' ? 'bg-[#2a2a2a] text-white' : 'text-gray-300 hover:bg-[#2a2a2a]'
          )"
        >
          <UserX class="w-4 h-4 text-gray-400" />
          <span>No assignee</span>
        </button>

        <button
          v-if="currentUser"
          @click="selectFilter('assigneeId', currentUser.id)"
          :class="cn(
            'w-full flex items-center gap-2 px-3 py-1.5 text-[13px] transition-colors',
            filters.assigneeId === currentUser.id ? 'bg-[#2a2a2a] text-white' : 'text-gray-300 hover:bg-[#2a2a2a]'
          )"
        >
          <User class="w-4 h-4 text-gray-400" />
          <span>Current user</span>
        </button>

        <div class="border-t border-[#2a2a2a] my-1" />

        <!-- User list -->
        <button
          v-for="user in filteredUsers"
          :key="user.id"
          @click="selectFilter('assigneeId', user.id)"
          :class="cn(
            'w-full flex items-center gap-2 px-3 py-1.5 text-[13px] transition-colors',
            filters.assigneeId === user.id ? 'bg-[#2a2a2a] text-white' : 'text-gray-300 hover:bg-[#2a2a2a]'
          )"
        >
          <div 
            v-if="user.avatarUrl"
            class="w-5 h-5 rounded-full bg-cover bg-center"
            :style="{ backgroundImage: `url(${user.avatarUrl})` }"
          />
          <div 
            v-else
            class="w-5 h-5 rounded-full flex items-center justify-center text-[9px] font-medium text-white"
            :style="{ backgroundColor: getUserColor(user.name) }"
          >
            {{ getInitials(user.name) }}
          </div>
          <span>{{ user.name }}</span>
        </button>
      </div>

      <div class="border-t border-[#2a2a2a] mt-1 pt-1">
        <button
          @click="closeSubmenu"
          class="w-full px-3 py-1.5 text-[13px] text-gray-400 hover:text-white hover:bg-[#2a2a2a] text-left transition-colors"
        >
          ← Back
        </button>
      </div>
    </div>

    <!-- Creator submenu (same as assignee but for creator) -->
    <div v-else-if="activeSubmenu === 'creator'" class="py-1">
      <div class="px-2 py-1.5">
        <div class="relative">
          <Search class="absolute left-2 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-gray-500" />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Filter..."
            class="w-full bg-transparent text-[13px] text-white placeholder-gray-500 pl-7 pr-2 py-1 focus:outline-none"
            autofocus
          />
        </div>
      </div>

      <div class="border-t border-[#2a2a2a] my-1" />

      <div class="max-h-[300px] overflow-y-auto">
        <button
          v-if="currentUser"
          @click="selectFilter('creatorId' as keyof IssueFilters, currentUser.id)"
          class="w-full flex items-center gap-2 px-3 py-1.5 text-[13px] text-gray-300 hover:bg-[#2a2a2a] transition-colors"
        >
          <User class="w-4 h-4 text-gray-400" />
          <span>Current user</span>
        </button>

        <div class="border-t border-[#2a2a2a] my-1" />

        <button
          v-for="user in filteredUsers"
          :key="user.id"
          @click="emit('close')"
          class="w-full flex items-center gap-2 px-3 py-1.5 text-[13px] text-gray-300 hover:bg-[#2a2a2a] transition-colors"
        >
          <div 
            v-if="user.avatarUrl"
            class="w-5 h-5 rounded-full bg-cover bg-center"
            :style="{ backgroundImage: `url(${user.avatarUrl})` }"
          />
          <div 
            v-else
            class="w-5 h-5 rounded-full flex items-center justify-center text-[9px] font-medium text-white"
            :style="{ backgroundColor: getUserColor(user.name) }"
          >
            {{ getInitials(user.name) }}
          </div>
          <span>{{ user.name }}</span>
        </button>
      </div>

      <div class="border-t border-[#2a2a2a] mt-1 pt-1">
        <button
          @click="closeSubmenu"
          class="w-full px-3 py-1.5 text-[13px] text-gray-400 hover:text-white hover:bg-[#2a2a2a] text-left transition-colors"
        >
          ← Back
        </button>
      </div>
    </div>

    <!-- Priority submenu -->
    <div v-else-if="activeSubmenu === 'priority'" class="py-1">
      <div class="px-2 py-1.5">
        <div class="relative">
          <Search class="absolute left-2 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-gray-500" />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Filter..."
            class="w-full bg-transparent text-[13px] text-white placeholder-gray-500 pl-7 pr-2 py-1 focus:outline-none"
            autofocus
          />
        </div>
      </div>

      <div class="border-t border-[#2a2a2a] my-1" />

      <div class="max-h-[300px] overflow-y-auto">
        <button
          v-for="priority in priorityOptions"
          :key="priority.value"
          @click="selectFilter('priority', priority.value)"
          :class="cn(
            'w-full flex items-center gap-2 px-3 py-1.5 text-[13px] transition-colors',
            filters.priority === priority.value ? 'bg-[#2a2a2a] text-white' : 'text-gray-300 hover:bg-[#2a2a2a]'
          )"
        >
          <component :is="priority.icon" :class="cn('w-4 h-4', priority.color)" />
          <span>{{ priority.label }}</span>
        </button>
      </div>

      <div class="border-t border-[#2a2a2a] mt-1 pt-1">
        <button
          @click="closeSubmenu"
          class="w-full px-3 py-1.5 text-[13px] text-gray-400 hover:text-white hover:bg-[#2a2a2a] text-left transition-colors"
        >
          ← Back
        </button>
      </div>
    </div>

    <!-- Labels submenu -->
    <div v-else-if="activeSubmenu === 'labels'" class="py-1">
      <div class="px-2 py-1.5">
        <div class="relative">
          <Search class="absolute left-2 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-gray-500" />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Filter..."
            class="w-full bg-transparent text-[13px] text-white placeholder-gray-500 pl-7 pr-2 py-1 focus:outline-none"
            autofocus
          />
        </div>
      </div>

      <div class="border-t border-[#2a2a2a] my-1" />

      <div class="max-h-[300px] overflow-y-auto">
        <button
          v-for="label in filteredLabels"
          :key="label.id"
          @click="emit('close')"
          class="w-full flex items-center gap-2 px-3 py-1.5 text-[13px] text-gray-300 hover:bg-[#2a2a2a] transition-colors"
        >
          <div 
            class="w-3 h-3 rounded-full"
            :style="{ backgroundColor: label.color }"
          />
          <span>{{ label.name }}</span>
        </button>

        <div v-if="filteredLabels.length === 0" class="px-3 py-4 text-[13px] text-gray-500 text-center">
          No labels found
        </div>
      </div>

      <div class="border-t border-[#2a2a2a] mt-1 pt-1">
        <button
          @click="closeSubmenu"
          class="w-full px-3 py-1.5 text-[13px] text-gray-400 hover:text-white hover:bg-[#2a2a2a] text-left transition-colors"
        >
          ← Back
        </button>
      </div>
    </div>

    <!-- Project submenu -->
    <div v-else-if="activeSubmenu === 'project'" class="py-1">
      <div class="px-2 py-1.5">
        <div class="relative">
          <Search class="absolute left-2 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-gray-500" />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Filter..."
            class="w-full bg-transparent text-[13px] text-white placeholder-gray-500 pl-7 pr-2 py-1 focus:outline-none"
            autofocus
          />
        </div>
      </div>

      <div class="border-t border-[#2a2a2a] my-1" />

      <div class="max-h-[300px] overflow-y-auto">
        <button
          v-for="project in filteredProjects"
          :key="project.id"
          @click="selectFilter('projectId', project.id)"
          :class="cn(
            'w-full flex items-center gap-2 px-3 py-1.5 text-[13px] transition-colors',
            filters.projectId === project.id ? 'bg-[#2a2a2a] text-white' : 'text-gray-300 hover:bg-[#2a2a2a]'
          )"
        >
          <div 
            class="w-5 h-5 rounded flex items-center justify-center text-[10px]"
            :style="{ backgroundColor: project.color || '#6366f1' }"
          >
            {{ project.icon || '📁' }}
          </div>
          <span>{{ project.name }}</span>
        </button>

        <div v-if="filteredProjects.length === 0" class="px-3 py-4 text-[13px] text-gray-500 text-center">
          No projects found
        </div>
      </div>

      <div class="border-t border-[#2a2a2a] mt-1 pt-1">
        <button
          @click="closeSubmenu"
          class="w-full px-3 py-1.5 text-[13px] text-gray-400 hover:text-white hover:bg-[#2a2a2a] text-left transition-colors"
        >
          ← Back
        </button>
      </div>
    </div>

    <!-- Dates submenu -->
    <div v-else-if="activeSubmenu === 'dates'" class="py-1">
      <div class="px-3 py-4 text-[13px] text-gray-500 text-center">
        Date filtering coming soon
      </div>

      <div class="border-t border-[#2a2a2a] mt-1 pt-1">
        <button
          @click="closeSubmenu"
          class="w-full px-3 py-1.5 text-[13px] text-gray-400 hover:text-white hover:bg-[#2a2a2a] text-left transition-colors"
        >
          ← Back
        </button>
      </div>
    </div>
  </div>
</template>
