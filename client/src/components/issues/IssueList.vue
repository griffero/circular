<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { useIssuesStore, type IssueFilters } from '@/stores/issues'
import { useUiStore } from '@/stores/ui'
import { useAppStore } from '@/stores/app'
import { cn } from '@/utils/cn'
import Avatar from '@/components/ui/Avatar.vue'
import Button from '@/components/ui/Button.vue'
import IssueFiltersComponent from './IssueFilters.vue'
import { 
  Plus, 
  Circle,
  AlertCircle,
  Clock,
  CheckCircle2,
  XCircle,
  ChevronDown,
  GitPullRequest,
  MessageSquare,
  X
} from 'lucide-vue-next'
import type { Issue, IssueStatus, WorkflowStateType, WorkflowState } from '@/types'

const props = defineProps<{
  teamId?: string
  projectId?: string
  baseFilters?: Partial<IssueFilters>
  showFilters?: boolean
  emptyTitle?: string
  emptyDescription?: string
}>()

const uiStore = useUiStore()
const appStore = useAppStore()

const emit = defineEmits<{
  (e: 'issueClick', issue: Issue): void
  (e: 'createIssue'): void
}>()

const issuesStore = useIssuesStore()

const userFilters = ref<IssueFilters>({})

const resolvedSort = computed<IssueFilters['sort']>(() => (
  userFilters.value.sort || props.baseFilters?.sort || 'updated_at'
))

const resolvedDirection = computed<IssueFilters['direction']>(() => (
  userFilters.value.direction || props.baseFilters?.direction || 'desc'
))

const effectiveFilters = computed<IssueFilters>(() => ({
  ...props.baseFilters,
  ...userFilters.value,
  sort: resolvedSort.value,
  direction: resolvedDirection.value,
  teamId: props.teamId,
  projectId: props.projectId,
}))

const visibleFilters = computed<IssueFilters>(() => ({
  ...userFilters.value,
  sort: resolvedSort.value,
  direction: resolvedDirection.value,
}))

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

// Status configuration fallback (non-team routes)
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

const workflowStateIcon: Record<WorkflowStateType, typeof Circle> = {
  triage: Circle,
  backlog: Circle,
  unstarted: Circle,
  started: Clock,
  completed: CheckCircle2,
  canceled: XCircle,
}

const sectionMap = computed(() => {
  const map = new Map<string, { key: string; label: string; icon: typeof Circle; color: string; issues: Issue[] }>()
  const isTeamContext = !!props.teamId && issuesStore.workflowStates.length > 0

  if (isTeamContext) {
    const orderedStates = [...issuesStore.workflowStates].sort((a, b) => a.position - b.position)
    for (const state of orderedStates) {
      map.set(state.id, {
        key: state.id,
        label: state.name,
        icon: workflowStateIcon[state.stateType] || Circle,
        color: state.color ? '' : 'text-[var(--linear-muted)]',
        issues: [],
      })
    }

    for (const issue of issues.value) {
      const key = issue.workflowStateId || '__fallback_backlog__'
      if (!map.has(key)) {
        map.set(key, {
          key,
          label: issue.workflowState?.name || statusConfig[getEffectiveStatus(issue)].label,
          icon: issue.workflowState?.stateType ? (workflowStateIcon[issue.workflowState.stateType] || Circle) : statusConfig[getEffectiveStatus(issue)].icon,
          color: issue.workflowState?.color ? '' : statusConfig[getEffectiveStatus(issue)].color,
          issues: [],
        })
      }
      map.get(key)!.issues.push(issue)
    }
    return Array.from(map.values()).filter((s) => s.issues.length > 0)
  }

  const order: IssueStatus[] = ['in_review', 'in_progress', 'todo', 'backlog', 'done']
  for (const status of order) {
    map.set(status, {
      key: status,
      label: statusConfig[status].label,
      icon: statusConfig[status].icon,
      color: statusConfig[status].color,
      issues: [],
    })
  }
  for (const issue of issues.value) {
    const status = getEffectiveStatus(issue)
    if (map.has(status)) {
      map.get(status)!.issues.push(issue)
    }
  }
  return Array.from(map.values()).filter((s) => s.issues.length > 0)
})

// Fetch issues with current filters
async function fetchIssues() {
  if (props.teamId) {
    await issuesStore.fetchWorkflowStates(props.teamId)
  }
  await issuesStore.fetchIssues(effectiveFilters.value)
}

watch(
  effectiveFilters,
  () => {
    fetchIssues()
  },
  { deep: true, immediate: true }
)

onMounted(() => {
  if (appStore.users.length === 0) {
    appStore.fetchUsers()
  }
})

function handleIssueClick(issue: Issue) {
  emit('issueClick', issue)
}

function handleFilterUpdate(newFilters: IssueFilters) {
  userFilters.value = { ...newFilters }
}

const activeFilterChips = computed(() => {
  const chips: Array<{ key: string; label: string; clear: () => void }> = []

  if (userFilters.value.statuses && userFilters.value.statuses.length > 0) {
    for (const status of userFilters.value.statuses) {
      const nextStatuses = userFilters.value.statuses.filter((item) => item !== status)
      chips.push({
        key: `status-${status}`,
        label: `Status: ${status.replace('_', ' ')}`,
        clear: () => {
          userFilters.value = {
            ...userFilters.value,
            status: nextStatuses.length === 1 ? nextStatuses[0] : undefined,
            statuses: nextStatuses.length > 0 ? nextStatuses : undefined,
          }
        }
      })
    }
  } else if (userFilters.value.status) {
    chips.push({
      key: `status-${userFilters.value.status}`,
      label: `Status: ${userFilters.value.status.replace('_', ' ')}`,
      clear: () => {
        userFilters.value = { ...userFilters.value, status: undefined, statuses: undefined }
      }
    })
  }

  if (userFilters.value.priority !== undefined) {
    chips.push({
      key: 'priority',
      label: `Priority: ${priorityConfig[userFilters.value.priority]?.label || userFilters.value.priority}`,
      clear: () => {
        userFilters.value = { ...userFilters.value, priority: undefined }
      }
    })
  }

  if (userFilters.value.assigneeId) {
    const assigneeName = appStore.users.find((user) => user.id === userFilters.value.assigneeId)?.name
    chips.push({
      key: 'assignee',
      label:
        userFilters.value.assigneeId === 'unassigned'
          ? 'Assignee: Unassigned'
          : `Assignee: ${assigneeName || 'Assigned'}`,
      clear: () => {
        userFilters.value = { ...userFilters.value, assigneeId: undefined }
      }
    })
  }

  if (userFilters.value.q && userFilters.value.q.trim().length > 0) {
    const query = userFilters.value.q.trim()
    chips.push({
      key: 'q',
      label: `Search: ${query}`,
      clear: () => {
        userFilters.value = { ...userFilters.value, q: undefined }
      }
    })
  }

  return chips
})

function clearAllUserFilters() {
  userFilters.value = {
    ...userFilters.value,
    status: undefined,
    statuses: undefined,
    priority: undefined,
    assigneeId: undefined,
    q: undefined,
  }
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

function getEffectiveStatus(issue: Issue): IssueStatus {
  if (issue.workflowState?.stateType) {
    const stateTypeToStatus: Record<WorkflowStateType, IssueStatus> = {
      triage: 'backlog',
      backlog: 'backlog',
      unstarted: 'todo',
      started: 'in_progress',
      completed: 'done',
      canceled: 'canceled',
    }
    return stateTypeToStatus[issue.workflowState.stateType] || issue.status || 'backlog'
  }
  return issue.status || 'backlog'
}
</script>

<template>
  <div class="h-full flex flex-col bg-[var(--linear-bg)]">
    <!-- Filters panel -->
    <div 
      v-if="showFilters && uiStore.filtersOpen" 
      class="px-4 py-3 border-b border-[var(--linear-border)] bg-[var(--linear-bg)]"
    >
      <IssueFiltersComponent
        :filters="visibleFilters"
        @update:filters="handleFilterUpdate"
      />
      <div v-if="activeFilterChips.length > 0" class="mt-2 flex flex-wrap items-center gap-2">
        <button
          v-for="chip in activeFilterChips"
          :key="chip.key"
          class="inline-flex items-center gap-1.5 px-2 py-1 rounded text-xs border border-[var(--linear-border)] text-[var(--linear-muted)] hover:text-[var(--linear-text)] hover:bg-[var(--linear-surface)] transition-colors"
          @click="chip.clear()"
        >
          <span class="capitalize">{{ chip.label }}</span>
          <X class="w-3 h-3" />
        </button>
        <button
          class="inline-flex items-center gap-1.5 px-2 py-1 rounded text-xs text-[var(--linear-muted)] hover:text-[var(--linear-text)] hover:bg-[var(--linear-surface)] transition-colors"
          @click="clearAllUserFilters"
        >
          <X class="w-3 h-3" />
          Clear all
        </button>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="flex items-center justify-center py-16 flex-1">
      <div class="animate-spin rounded-full h-8 w-8 border-2 border-[var(--linear-accent)] border-t-transparent"></div>
    </div>

    <!-- Empty state -->
    <div v-else-if="issues.length === 0" class="flex flex-col items-center justify-center py-16 flex-1">
      <div class="w-12 h-12 rounded-full bg-[var(--linear-elevated)] border border-[var(--linear-border)] flex items-center justify-center mb-4">
        <Circle class="w-6 h-6 text-[var(--linear-muted)]" />
      </div>
      <h3 class="text-sm font-medium text-[var(--linear-text)] mb-1">
        {{ emptyTitle || 'No issues found' }}
      </h3>
      <p class="text-xs text-[var(--linear-muted)] text-center max-w-xs mb-4">
        {{ emptyDescription || 'Create a new issue to get started.' }}
      </p>
      <Button
        size="sm"
        @click="emit('createIssue')"
      >
        <Plus class="w-4 h-4" />
        Create issue
      </Button>
    </div>

    <!-- Issue list grouped by status -->
    <div v-else class="flex-1 overflow-auto">
      <div v-for="section in sectionMap" :key="section.key">
          <!-- Section header -->
          <div 
            @click="toggleSection(section.key)"
            class="group flex items-center gap-2 px-4 py-2 cursor-pointer hover:bg-[var(--linear-elevated)] sticky top-0 bg-[var(--linear-bg)] z-10 border-b border-[var(--linear-border)]"
          >
            <ChevronDown 
              :class="cn(
                'w-3.5 h-3.5 text-[var(--linear-muted)] transition-transform',
                collapsedSections.has(section.key) && '-rotate-90'
              )" 
            />
            <component 
              :is="section.icon" 
              :class="cn('w-4 h-4', section.color)" 
              :style="section.color ? undefined : (issuesStore.workflowStates.find((s: WorkflowState) => s.id === section.key)?.color ? { color: issuesStore.workflowStates.find((s: WorkflowState) => s.id === section.key)?.color } : undefined)"
            />
            <span class="text-[13px] font-medium text-[var(--linear-text)]">{{ section.label }}</span>
            <span class="text-xs text-[var(--linear-muted)] ml-1">{{ section.issues.length }}</span>
            
            <!-- Add button -->
            <button 
              class="ml-auto p-1 rounded hover:bg-[var(--linear-surface)] opacity-0 group-hover:opacity-100"
              @click.stop="emit('createIssue')"
            >
              <Plus class="w-3.5 h-3.5 text-[var(--linear-muted)]" />
            </button>
          </div>

          <!-- Issues in this section -->
          <div v-if="!collapsedSections.has(section.key)">
            <div
              v-for="issue in section.issues"
              :key="issue.id"
              @click="handleIssueClick(issue)"
              class="flex items-center gap-3 px-4 py-2 hover:bg-[var(--linear-elevated)] cursor-pointer border-b border-[var(--linear-border-subtle)] group"
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
                :is="statusConfig[getEffectiveStatus(issue)].icon" 
                :class="cn('w-4 h-4 flex-shrink-0', statusConfig[getEffectiveStatus(issue)].color)" 
              />

              <!-- Issue identifier -->
              <span class="text-[13px] text-gray-500 font-mono w-20 flex-shrink-0">
                {{ issue.identifier }}
              </span>

              <!-- Title -->
              <span class="text-[13px] text-[var(--linear-text)] flex-1 truncate">
                {{ issue.title }}
              </span>

              <!-- Labels -->
              <div v-if="issue.labels?.length" class="flex items-center gap-1">
                <div
                  v-for="label in issue.labels.slice(0, 2)"
                  :key="label.id"
                  class="px-1.5 py-0.5 text-xs rounded border border-[var(--linear-border)] text-[var(--linear-muted)]"
                >
                  {{ label.name }}
                </div>
              </div>

              <!-- Project -->
              <div v-if="issue.project?.name" class="max-w-[220px] truncate text-xs text-[var(--linear-muted)] border border-[var(--linear-border)] rounded-full px-2 py-0.5">
                {{ issue.project.name }}
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
                :name="issue.assignee.name || issue.assignee.displayName || issue.assignee.email"
                size="xs"
                class="flex-shrink-0"
              />
              <div v-else class="w-5 h-5 rounded-full border border-dashed border-gray-600 flex-shrink-0" />
            </div>
          </div>
      </div>
    </div>
  </div>
</template>
