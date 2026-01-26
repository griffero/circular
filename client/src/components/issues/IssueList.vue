<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useIssuesStore, type IssueFilters } from '@/stores/issues'
import { cn } from '@/utils/cn'
import Avatar from '@/components/ui/Avatar.vue'
import { 
  Plus, 
  Circle,
  AlertCircle,
  Clock,
  CheckCircle2,
  XCircle,
  ChevronDown,
  GitPullRequest,
  MessageSquare
} from 'lucide-vue-next'
import type { Issue, IssueStatus } from '@/types'

const props = defineProps<{
  teamId?: string
  projectId?: string
  showFilters?: boolean
  emptyTitle?: string
  emptyDescription?: string
}>()

const emit = defineEmits<{
  (e: 'issueClick', issue: Issue): void
  (e: 'createIssue'): void
}>()

const router = useRouter()
const issuesStore = useIssuesStore()

const filters = ref<IssueFilters>({
  teamId: props.teamId,
  projectId: props.projectId,
  sort: 'created_at',
  direction: 'desc'
})

const loading = computed(() => issuesStore.loading)
const issues = computed(() => issuesStore.issues)

// Collapsed status sections
const collapsedSections = ref<Set<string>>(new Set())

function toggleSection(status: string) {
  if (collapsedSections.value.has(status)) {
    collapsedSections.value.delete(status)
  } else {
    collapsedSections.value.add(status)
  }
}

// Status configuration matching Linear's style
const statusConfig: Record<IssueStatus, { 
  label: string
  icon: typeof Circle
  color: string
  bgColor: string
}> = {
  backlog: { label: 'Backlog', icon: Circle, color: 'text-gray-400', bgColor: 'bg-gray-400' },
  todo: { label: 'Todo', icon: Circle, color: 'text-gray-500', bgColor: 'bg-gray-500' },
  in_progress: { label: 'In Progress', icon: Clock, color: 'text-yellow-500', bgColor: 'bg-yellow-500' },
  in_review: { label: 'In Review', icon: AlertCircle, color: 'text-orange-500', bgColor: 'bg-orange-500' },
  done: { label: 'Done', icon: CheckCircle2, color: 'text-green-500', bgColor: 'bg-green-500' },
  canceled: { label: 'Canceled', icon: XCircle, color: 'text-gray-400', bgColor: 'bg-gray-400' }
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
    if (grouped[issue.status]) {
      grouped[issue.status].push(issue)
    }
  }
  
  return grouped
})

// Status order for display
const statusOrder: IssueStatus[] = ['in_review', 'in_progress', 'todo', 'backlog', 'done']

// Fetch issues with current filters
async function fetchIssues() {
  await issuesStore.fetchIssues({
    ...filters.value,
    teamId: props.teamId,
    projectId: props.projectId
  })
}

watch(
  () => [props.teamId, props.projectId],
  () => {
    filters.value.teamId = props.teamId
    filters.value.projectId = props.projectId
    fetchIssues()
  }
)

onMounted(() => {
  fetchIssues()
})

function handleIssueClick(issue: Issue) {
  emit('issueClick', issue)
}

function formatDate(dateString: string) {
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', { month: 'short', year: 'numeric' })
}

// Priority icons and colors
const priorityConfig: Record<number, { label: string; color: string }> = {
  0: { label: 'No priority', color: 'text-gray-400' },
  1: { label: 'Urgent', color: 'text-red-500' },
  2: { label: 'High', color: 'text-orange-500' },
  3: { label: 'Medium', color: 'text-yellow-500' },
  4: { label: 'Low', color: 'text-blue-500' }
}
</script>

<template>
  <div class="h-full flex flex-col bg-[#0d0d0d]">
    <!-- Loading -->
    <div v-if="loading" class="flex items-center justify-center py-16 flex-1">
      <div class="animate-spin rounded-full h-8 w-8 border-2 border-indigo-500 border-t-transparent"></div>
    </div>

    <!-- Empty state -->
    <div v-else-if="issues.length === 0" class="flex flex-col items-center justify-center py-16 flex-1">
      <div class="w-12 h-12 rounded-full bg-[#1a1a1a] flex items-center justify-center mb-4">
        <Circle class="w-6 h-6 text-gray-500" />
      </div>
      <h3 class="text-sm font-medium text-white mb-1">
        {{ emptyTitle || 'No issues found' }}
      </h3>
      <p class="text-xs text-gray-500 text-center max-w-xs mb-4">
        {{ emptyDescription || 'Create a new issue to get started.' }}
      </p>
      <button 
        @click="emit('createIssue')"
        class="flex items-center gap-1.5 px-3 py-1.5 rounded bg-indigo-600 hover:bg-indigo-700 text-white text-sm transition-colors"
      >
        <Plus class="w-4 h-4" />
        Create issue
      </button>
    </div>

    <!-- Issue list grouped by status -->
    <div v-else class="flex-1 overflow-auto">
      <div v-for="status in statusOrder" :key="status">
        <!-- Only show sections with issues -->
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
            
            <!-- Add button -->
            <button 
              class="ml-auto p-1 rounded hover:bg-[#2a2a2a] opacity-0 group-hover:opacity-100"
              @click.stop="emit('createIssue')"
            >
              <Plus class="w-3.5 h-3.5 text-gray-500" />
            </button>
          </div>

          <!-- Issues in this section -->
          <div v-if="!collapsedSections.has(status)">
            <div
              v-for="issue in issuesByStatus[status]"
              :key="issue.id"
              @click="handleIssueClick(issue)"
              class="flex items-center gap-3 px-4 py-2 hover:bg-[#1a1a1a] cursor-pointer border-b border-[#1f1f1f] group"
            >
              <!-- Priority indicator -->
              <div class="w-4 flex justify-center">
                <span 
                  v-if="issue.priority > 0"
                  class="text-xs"
                  :class="priorityConfig[issue.priority]?.color"
                >
                  ●
                </span>
              </div>

              <!-- Status icon -->
              <component 
                :is="statusConfig[issue.status].icon" 
                :class="cn('w-4 h-4 flex-shrink-0', statusConfig[issue.status].color)" 
              />

              <!-- Issue identifier -->
              <span class="text-[13px] text-gray-500 font-mono w-20 flex-shrink-0">
                {{ issue.identifier }}
              </span>

              <!-- Title -->
              <span class="text-[13px] text-gray-300 flex-1 truncate">
                {{ issue.title }}
              </span>

              <!-- Labels -->
              <div v-if="issue.labels?.length" class="flex items-center gap-1">
                <div
                  v-for="label in issue.labels.slice(0, 2)"
                  :key="label.id"
                  class="w-2 h-2 rounded-full flex-shrink-0"
                  :style="{ backgroundColor: label.color }"
                />
              </div>

              <!-- PR indicator -->
              <div v-if="issue.linkedPrNumber" class="flex items-center gap-1 text-xs text-gray-500">
                <GitPullRequest class="w-3 h-3" />
                <span>#{{ issue.linkedPrNumber }}</span>
              </div>

              <!-- Comments count -->
              <div v-if="issue.commentsCount && issue.commentsCount > 0" class="flex items-center gap-1 text-xs text-gray-500">
                <MessageSquare class="w-3 h-3" />
                <span>{{ issue.commentsCount }}</span>
              </div>

              <!-- Date -->
              <span class="text-xs text-gray-500 w-20 text-right">
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
</template>
