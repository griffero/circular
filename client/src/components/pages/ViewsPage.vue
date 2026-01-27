<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useIssuesStore, type IssueFilters } from '@/stores/issues'
import { useAppStore } from '@/stores/app'
import { useEmojiStore } from '@/stores/emoji'
import { cn } from '@/utils/cn'
import Avatar from '@/components/ui/Avatar.vue'
import EmojiIcon from '@/components/ui/EmojiIcon.vue'
import ViewFilterDropdown from '@/components/views/ViewFilterDropdown.vue'
import { 
  Layers,
  Filter,
  SlidersHorizontal,
  X,
  ChevronDown,
  Circle,
  Clock,
  CheckCircle2,
  XCircle,
  AlertTriangle,
  ArrowUp,
  ArrowRight,
  ArrowDown,
  Minus,
  MessageSquare,
  Link2
} from 'lucide-vue-next'
import type { Issue, IssueStatus, IssuePriority } from '@/types'

const router = useRouter()
const issuesStore = useIssuesStore()
const appStore = useAppStore()
const emojiStore = useEmojiStore()

// State
const activeTab = ref<'issues' | 'projects'>('issues')
const showFilterDropdown = ref(false)
const filters = ref<IssueFilters>({
  sort: 'created_at',
  direction: 'desc'
})

// Computed
const loading = computed(() => issuesStore.loading)
const issues = computed(() => issuesStore.issues)
const teams = computed(() => appStore.teams)
const projects = computed(() => appStore.projects)

// Active filters count
const activeFiltersCount = computed(() => {
  let count = 0
  if (filters.value.teamId) count++
  if (filters.value.projectId) count++
  if (filters.value.assigneeId) count++
  if (filters.value.status) count++
  if (filters.value.priority !== undefined) count++
  return count
})

// Has any filters
const hasFilters = computed(() => activeFiltersCount.value > 0)

// Status configuration
const statusConfig: Record<IssueStatus, { 
  label: string
  icon: typeof Circle
  color: string
}> = {
  backlog: { label: 'Backlog', icon: Circle, color: 'text-gray-400' },
  todo: { label: 'Todo', icon: Circle, color: 'text-gray-500' },
  in_progress: { label: 'In Progress', icon: Clock, color: 'text-yellow-500' },
  in_review: { label: 'In Review', icon: Clock, color: 'text-blue-500' },
  done: { label: 'Done', icon: CheckCircle2, color: 'text-green-500' },
  canceled: { label: 'Canceled', icon: XCircle, color: 'text-gray-400' }
}

// Priority configuration
const priorityConfig: Record<IssuePriority, { icon: typeof Minus; color: string }> = {
  0: { icon: Minus, color: 'text-gray-400' },
  1: { icon: AlertTriangle, color: 'text-red-500' },
  2: { icon: ArrowUp, color: 'text-orange-500' },
  3: { icon: ArrowRight, color: 'text-yellow-500' },
  4: { icon: ArrowDown, color: 'text-blue-500' }
}

// Group issues by status
const issuesByStatus = computed(() => {
  const grouped: Record<IssueStatus, Issue[]> = {
    in_review: [],
    in_progress: [],
    todo: [],
    backlog: [],
    done: [],
    canceled: []
  }
  
  for (const issue of issues.value) {
    const status = issue.status || 'backlog'
    if (grouped[status]) {
      grouped[status].push(issue)
    }
  }
  
  return grouped
})

// Status order for display
const statusOrder: IssueStatus[] = ['in_progress', 'in_review', 'todo', 'backlog', 'done', 'canceled']

// Collapsed sections
const collapsedSections = ref<Set<string>>(new Set())

function toggleSection(status: string) {
  if (collapsedSections.value.has(status)) {
    collapsedSections.value.delete(status)
  } else {
    collapsedSections.value.add(status)
  }
}

// Fetch issues
async function fetchIssues() {
  await issuesStore.fetchIssues(filters.value)
}

// Watch filters and refetch
watch(filters, () => {
  fetchIssues()
}, { deep: true })

// On mount
onMounted(async () => {
  await fetchIssues()
})

// Handle filter update
function handleFilterUpdate(newFilters: IssueFilters) {
  filters.value = newFilters
  showFilterDropdown.value = false
}

// Clear all filters
function clearFilters() {
  filters.value = {
    sort: filters.value.sort,
    direction: filters.value.direction
  }
}

// Remove specific filter
function removeFilter(key: keyof IssueFilters) {
  const newFilters = { ...filters.value }
  delete newFilters[key]
  filters.value = newFilters
}

// Get filter label
function getFilterLabel(key: keyof IssueFilters, value: unknown): string {
  switch (key) {
    case 'teamId':
      const team = teams.value.find(t => t.id === value)
      return team?.name || 'Team'
    case 'projectId':
      const project = projects.value.find(p => p.id === value)
      return project?.name || 'Project'
    case 'status':
      return statusConfig[value as IssueStatus]?.label || String(value)
    case 'priority':
      const priorityLabels = ['No priority', 'Urgent', 'High', 'Medium', 'Low']
      return priorityLabels[value as number] || 'Priority'
    case 'assigneeId':
      if (value === 'unassigned') return 'Unassigned'
      return 'Assignee'
    default:
      return String(value)
  }
}

// Navigate to issue
function goToIssue(issue: Issue) {
  router.push(`/issue/${issue.id}`)
}

// Format date
function formatDate(dateString: string) {
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
}

// Check if has emoji
function hasEmoji(icon?: string | null): boolean {
  if (!icon) return false
  if (emojiStore.getEmojiUrl(icon)) return true
  const stripped = icon.replace(/^:|:$/g, '')
  return /^[\p{Emoji}\u200d]+$/u.test(stripped) && stripped.length <= 8
}

// Close dropdown when clicking outside
function handleClickOutside(event: MouseEvent) {
  const target = event.target as HTMLElement
  if (!target.closest('.filter-dropdown-container')) {
    showFilterDropdown.value = false
  }
}
</script>

<template>
  <div class="h-full flex flex-col bg-[#0d0d0d]" @click="handleClickOutside">
    <!-- Header -->
    <div class="border-b border-[#1f1f1f]">
      <!-- Breadcrumb -->
      <div class="px-6 pt-4 pb-2">
        <div class="flex items-center gap-2 text-[13px] text-gray-400">
          <span>Views</span>
          <span>›</span>
          <span class="text-white">All issues</span>
        </div>
      </div>

      <!-- Title and description -->
      <div class="px-6 pb-4">
        <div class="flex items-center gap-3">
          <div class="w-8 h-8 rounded-lg bg-[#1a1a1a] flex items-center justify-center">
            <Layers class="w-4 h-4 text-gray-400" />
          </div>
          <div>
            <h1 class="text-lg font-medium text-white">All issues</h1>
            <p class="text-[13px] text-gray-500">Description (optional)</p>
          </div>
        </div>
      </div>

      <!-- Tabs and filters -->
      <div class="px-6 pb-3 flex items-center gap-4">
        <!-- Tabs -->
        <div class="flex items-center gap-1">
          <button
            @click="activeTab = 'issues'"
            :class="cn(
              'px-3 py-1.5 text-[13px] rounded-md transition-colors',
              activeTab === 'issues'
                ? 'bg-[#1a1a1a] text-white'
                : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
            )"
          >
            Issues
          </button>
          <button
            @click="activeTab = 'projects'"
            :class="cn(
              'px-3 py-1.5 text-[13px] rounded-md transition-colors',
              activeTab === 'projects'
                ? 'bg-[#1a1a1a] text-white'
                : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
            )"
          >
            Projects
          </button>
        </div>

        <!-- Filter button -->
        <div class="relative filter-dropdown-container">
          <button
            @click.stop="showFilterDropdown = !showFilterDropdown"
            :class="cn(
              'flex items-center gap-1.5 px-3 py-1.5 text-[13px] rounded-md transition-colors',
              hasFilters
                ? 'bg-indigo-500/20 text-indigo-400'
                : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
            )"
          >
            <Filter class="w-4 h-4" />
            <span>Filter</span>
            <span v-if="hasFilters" class="text-[11px] bg-indigo-500/30 px-1.5 rounded">
              {{ activeFiltersCount }}
            </span>
          </button>

          <!-- Filter dropdown -->
          <div
            v-if="showFilterDropdown"
            class="absolute top-full left-0 mt-1 z-50"
            @click.stop
          >
            <ViewFilterDropdown
              :filters="filters"
              @update:filters="handleFilterUpdate"
              @close="showFilterDropdown = false"
            />
          </div>
        </div>

        <!-- Active filter pills -->
        <div v-if="hasFilters" class="flex items-center gap-2">
          <button
            v-if="filters.teamId"
            @click="removeFilter('teamId')"
            class="flex items-center gap-1 px-2 py-1 text-[12px] bg-[#1a1a1a] text-gray-300 rounded hover:bg-[#2a2a2a] transition-colors"
          >
            {{ getFilterLabel('teamId', filters.teamId) }}
            <X class="w-3 h-3" />
          </button>
          <button
            v-if="filters.status"
            @click="removeFilter('status')"
            class="flex items-center gap-1 px-2 py-1 text-[12px] bg-[#1a1a1a] text-gray-300 rounded hover:bg-[#2a2a2a] transition-colors"
          >
            {{ getFilterLabel('status', filters.status) }}
            <X class="w-3 h-3" />
          </button>
          <button
            v-if="filters.priority !== undefined"
            @click="removeFilter('priority')"
            class="flex items-center gap-1 px-2 py-1 text-[12px] bg-[#1a1a1a] text-gray-300 rounded hover:bg-[#2a2a2a] transition-colors"
          >
            {{ getFilterLabel('priority', filters.priority) }}
            <X class="w-3 h-3" />
          </button>
          <button
            v-if="filters.assigneeId"
            @click="removeFilter('assigneeId')"
            class="flex items-center gap-1 px-2 py-1 text-[12px] bg-[#1a1a1a] text-gray-300 rounded hover:bg-[#2a2a2a] transition-colors"
          >
            {{ getFilterLabel('assigneeId', filters.assigneeId) }}
            <X class="w-3 h-3" />
          </button>
          <button
            v-if="filters.projectId"
            @click="removeFilter('projectId')"
            class="flex items-center gap-1 px-2 py-1 text-[12px] bg-[#1a1a1a] text-gray-300 rounded hover:bg-[#2a2a2a] transition-colors"
          >
            {{ getFilterLabel('projectId', filters.projectId) }}
            <X class="w-3 h-3" />
          </button>

          <button
            @click="clearFilters"
            class="text-[12px] text-gray-500 hover:text-white transition-colors"
          >
            Clear all
          </button>
        </div>

        <div class="flex-1" />

        <!-- Display options -->
        <button 
          title="Display options (coming soon)"
          class="flex items-center gap-1.5 px-3 py-1.5 text-[13px] text-gray-400 hover:text-white hover:bg-[#1a1a1a] rounded-md transition-colors opacity-60 cursor-not-allowed"
        >
          <SlidersHorizontal class="w-4 h-4" />
          <span>Display</span>
        </button>
      </div>
    </div>

    <!-- Content -->
    <div class="flex-1 overflow-auto">
      <!-- Issues tab -->
      <div v-if="activeTab === 'issues'">
        <!-- Loading -->
        <div v-if="loading" class="flex items-center justify-center py-16">
          <div class="animate-spin rounded-full h-8 w-8 border-2 border-indigo-500 border-t-transparent"></div>
        </div>

        <!-- Empty state -->
        <div v-else-if="issues.length === 0" class="flex flex-col items-center justify-center py-16">
          <div class="text-center">
            <h3 class="text-lg font-medium text-white mb-2">
              {{ hasFilters ? 'No issues match your filters' : 'Views are limited to 5,000 issues' }}
            </h3>
            <p class="text-[13px] text-gray-500">
              {{ hasFilters ? 'Try adjusting your filters to see more results.' : 'Apply filters to narrow results' }}
            </p>
          </div>
        </div>

        <!-- Issue list grouped by status -->
        <div v-else>
          <div v-for="status in statusOrder" :key="status">
            <div v-if="issuesByStatus[status].length > 0">
              <!-- Section header -->
              <div 
                @click="toggleSection(status)"
                class="flex items-center gap-2 px-4 py-2 cursor-pointer hover:bg-[#1a1a1a] sticky top-0 bg-[#0d0d0d] z-10 border-b border-[#1f1f1f]"
              >
                <ChevronDown 
                  :class="cn(
                    'w-3.5 h-3.5 text-gray-500 transition-transform',
                    collapsedSections.has(status) && '-rotate-90'
                  )" 
                />
                <component 
                  :is="statusConfig[status].icon" 
                  :class="cn('w-4 h-4', statusConfig[status].color)" 
                />
                <span class="text-[13px] font-medium text-white">{{ statusConfig[status].label }}</span>
                <span class="text-xs text-gray-500 ml-1">{{ issuesByStatus[status].length }}</span>
              </div>

              <!-- Issues in this section -->
              <div v-if="!collapsedSections.has(status)">
                <div
                  v-for="issue in issuesByStatus[status]"
                  :key="issue.id"
                  @click="goToIssue(issue)"
                  class="flex items-center gap-3 px-4 py-2 hover:bg-[#1a1a1a] cursor-pointer border-b border-[#1f1f1f] group"
                >
                  <!-- Priority indicator -->
                  <div class="w-4 flex justify-center">
                    <component 
                      v-if="issue.priority > 0"
                      :is="priorityConfig[issue.priority].icon"
                      :class="cn('w-4 h-4', priorityConfig[issue.priority].color)"
                    />
                  </div>

                  <!-- Status icon -->
                  <component 
                    :is="statusConfig[issue.status || 'backlog'].icon" 
                    :class="cn('w-4 h-4 flex-shrink-0', statusConfig[issue.status || 'backlog'].color)" 
                  />

                  <!-- Issue identifier -->
                  <span class="text-[13px] text-gray-500 font-mono w-20 flex-shrink-0">
                    {{ issue.identifier }}
                  </span>

                  <!-- Title -->
                  <span class="text-[13px] text-gray-300 flex-1 truncate">
                    {{ issue.title }}
                  </span>

                  <!-- Team icon -->
                  <div 
                    v-if="issue.team"
                    class="w-5 h-5 rounded flex items-center justify-center flex-shrink-0"
                    :style="hasEmoji(issue.team.icon) ? {} : { backgroundColor: issue.team.color || '#6366f1' }"
                  >
                    <EmojiIcon 
                      :name="issue.team.icon" 
                      :fallback="issue.team.key.substring(0, 2)" 
                      size="xs"
                    />
                  </div>

                  <!-- Labels -->
                  <div v-if="issue.labels?.length" class="flex items-center gap-1">
                    <div
                      v-for="label in issue.labels.slice(0, 2)"
                      :key="label.id"
                      class="w-2 h-2 rounded-full flex-shrink-0"
                      :style="{ backgroundColor: label.color }"
                    />
                  </div>

                  <!-- Date -->
                  <span class="text-xs text-gray-500 w-16 text-right">
                    {{ formatDate(issue.createdAt) }}
                  </span>

                  <!-- Assignee -->
                  <Avatar
                    v-if="issue.assignee"
                    :name="issue.assignee.name"
                    size="xs"
                    class="flex-shrink-0"
                  />
                  <div v-else class="w-5 h-5 rounded-full border border-dashed border-gray-600 flex-shrink-0" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Projects tab -->
      <div v-else-if="activeTab === 'projects'" class="p-6">
        <div v-if="projects.length === 0" class="flex flex-col items-center justify-center py-16">
          <div class="text-center">
            <h3 class="text-lg font-medium text-white mb-2">No projects</h3>
            <p class="text-[13px] text-gray-500">Create a project to organize your issues.</p>
          </div>
        </div>

        <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <div
            v-for="project in projects"
            :key="project.id"
            @click="router.push(`/project/${project.slug}`)"
            class="p-4 bg-[#1a1a1a] rounded-lg border border-[#2a2a2a] hover:border-[#3a3a3a] cursor-pointer transition-colors"
          >
            <div class="flex items-center gap-3 mb-3">
              <div 
                class="w-8 h-8 rounded-lg flex items-center justify-center"
                :style="hasEmoji(project.icon) ? {} : { backgroundColor: project.color || '#6366f1' }"
              >
                <EmojiIcon 
                  :name="project.icon" 
                  :fallback="project.name.charAt(0)" 
                  size="sm"
                />
              </div>
              <div>
                <h3 class="text-[14px] font-medium text-white">{{ project.name }}</h3>
                <p v-if="project.status" class="text-[12px] text-gray-500 capitalize">{{ project.status }}</p>
              </div>
            </div>
            <p v-if="project.description" class="text-[13px] text-gray-400 line-clamp-2">
              {{ project.description }}
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
