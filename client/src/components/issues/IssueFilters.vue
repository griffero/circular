<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useAppStore } from '@/stores/app'
import type { IssueStatus, IssuePriority } from '@/types'
import { cn } from '@/utils/cn'
import LinearStatusIcon from '@/components/icons/LinearStatusIcon.vue'
import LinearPriorityIcon from '@/components/icons/LinearPriorityIcon.vue'
import Dropdown from '@/components/ui/Dropdown.vue'
import DropdownItem from '@/components/ui/DropdownItem.vue'
import {
  X,
  Circle,
  Clock,
  CheckCircle2,
  XCircle,
  AlertTriangle,
  ArrowUp,
  ArrowRight,
  ArrowDown,
  Minus,
  User,
  Search,
  SortAsc,
  SortDesc
} from 'lucide-vue-next'

interface Filters {
  status?: IssueStatus
  statuses?: IssueStatus[]
  priority?: IssuePriority
  assigneeId?: string
  q?: string
  sort?: 'created_at' | 'updated_at' | 'priority' | 'due_date'
  direction?: 'asc' | 'desc'
}

const props = defineProps<{
  filters: Filters
}>()

const emit = defineEmits<{
  (e: 'update:filters', filters: Filters): void
}>()

const authStore = useAuthStore()
const appStore = useAppStore()

const currentUser = computed(() => authStore.user)
const users = computed(() => appStore.users)

onMounted(() => {
  if (users.value.length === 0) {
    appStore.fetchUsers()
  }
})

const assigneeOptions = computed(() => {
  const currentUserId = currentUser.value?.id
  if (!currentUserId) return users.value

  return [...users.value].sort((a, b) => {
    if (a.id === currentUserId) return -1
    if (b.id === currentUserId) return 1
    return a.name.localeCompare(b.name)
  })
})

const statuses: { value: IssueStatus | undefined; label: string; icon: typeof Circle; color: string }[] = [
  { value: undefined, label: 'All statuses', icon: Circle, color: 'text-gray-400' },
  { value: 'backlog', label: 'Backlog', icon: Circle, color: 'text-gray-400' },
  { value: 'todo', label: 'Todo', icon: Circle, color: 'text-gray-500' },
  { value: 'in_progress', label: 'In Progress', icon: Clock, color: 'text-yellow-500' },
  { value: 'in_review', label: 'In Review', icon: Clock, color: 'text-blue-500' },
  { value: 'done', label: 'Done', icon: CheckCircle2, color: 'text-green-500' },
  { value: 'canceled', label: 'Canceled', icon: XCircle, color: 'text-red-400' },
]

const priorities: { value: IssuePriority | undefined; label: string; icon: typeof Minus; color: string }[] = [
  { value: undefined, label: 'All priorities', icon: Minus, color: 'text-gray-400' },
  { value: 1, label: 'Urgent', icon: AlertTriangle, color: 'text-red-500' },
  { value: 2, label: 'High', icon: ArrowUp, color: 'text-orange-500' },
  { value: 3, label: 'Medium', icon: ArrowRight, color: 'text-yellow-500' },
  { value: 4, label: 'Low', icon: ArrowDown, color: 'text-blue-500' },
  { value: 0, label: 'No priority', icon: Minus, color: 'text-gray-400' },
]

const STATUS_STATE_NAME: Record<IssueStatus, string> = {
  backlog: 'Backlog',
  todo: 'Todo',
  in_progress: 'In Progress',
  in_review: 'In Review',
  done: 'Done',
  canceled: 'Canceled',
}

const sortOptions: { value: string; label: string }[] = [
  { value: 'created_at', label: 'Created' },
  { value: 'updated_at', label: 'Updated' },
  { value: 'priority', label: 'Priority' },
  { value: 'due_date', label: 'Due date' },
]

const hasActiveFilters = computed(() => {
  return (props.filters.statuses?.length ?? 0) > 0 ||
         props.filters.status !== undefined ||
         props.filters.priority !== undefined || 
         props.filters.assigneeId !== undefined ||
         !!props.filters.q?.trim() ||
         props.filters.sort !== undefined ||
         props.filters.direction !== undefined
})

function updateFilter<K extends keyof Filters>(key: K, value: Filters[K]) {
  emit('update:filters', { ...props.filters, [key]: value })
}

function updateFilters(next: Partial<Filters>) {
  emit('update:filters', { ...props.filters, ...next })
}

function clearFilters() {
  emit('update:filters', {
    status: undefined,
    statuses: undefined,
    priority: undefined,
    assigneeId: undefined,
    q: undefined,
    sort: undefined,
    direction: undefined
  })
}

function toggleDirection() {
  const newDirection = props.filters.direction === 'asc' ? 'desc' : 'asc'
  emit('update:filters', { ...props.filters, direction: newDirection })
}

function getStatusLabel(status?: IssueStatus) {
  return statuses.find(s => s.value === status)?.label || 'All statuses'
}

const selectedStatuses = computed<IssueStatus[]>(() => {
  if (props.filters.statuses && props.filters.statuses.length > 0) {
    return props.filters.statuses
  }
  return props.filters.status ? [props.filters.status] : []
})

function toggleStatus(status: IssueStatus) {
  const set = new Set(selectedStatuses.value)
  if (set.has(status)) {
    set.delete(status)
  } else {
    set.add(status)
  }

  const nextStatuses = Array.from(set)
  if (nextStatuses.length === 0) {
    updateFilters({ status: undefined, statuses: undefined })
    return
  }

  updateFilters({
    status: nextStatuses.length === 1 ? nextStatuses[0] : undefined,
    statuses: nextStatuses
  })
}

function clearStatusFilters() {
  updateFilters({ status: undefined, statuses: undefined })
}

function statusLabel() {
  if (selectedStatuses.value.length === 0) return 'All statuses'
  if (selectedStatuses.value.length === 1) return getStatusLabel(selectedStatuses.value[0])
  return `${selectedStatuses.value.length} statuses`
}

function getPriorityLabel(priority?: IssuePriority) {
  return priorities.find(p => p.value === priority)?.label || 'All priorities'
}

function getSortLabel(sort?: string) {
  return sortOptions.find(s => s.value === sort)?.label || 'Updated'
}

function getAssigneeLabel(assigneeId?: string) {
  if (!assigneeId) return 'Assignee'
  if (assigneeId === 'unassigned') return 'Unassigned'
  if (assigneeId === currentUser.value?.id) return 'Assigned to me'
  return users.value.find((user) => user.id === assigneeId)?.name || 'Assignee'
}

function triggerClass(active: boolean) {
  return cn(
    'flex items-center gap-1.5 px-2.5 py-1.5 rounded text-[13px] border transition-colors',
    active
      ? 'bg-[var(--linear-surface)] border-[var(--linear-border)] text-[var(--linear-text)]'
      : 'border-transparent text-[var(--linear-muted)] hover:bg-[var(--linear-surface)] hover:text-[var(--linear-text)]'
  )
}
</script>

<template>
  <div class="flex items-center gap-2 flex-wrap">
    <!-- Search filter -->
    <div class="relative min-w-[220px]">
      <Search class="w-4 h-4 text-[var(--linear-muted)] absolute left-2.5 top-1/2 -translate-y-1/2 pointer-events-none" />
      <input
        :value="filters.q || ''"
        type="text"
        placeholder="Search issues..."
        class="w-full h-8 pl-8 pr-2 rounded border border-[var(--linear-border)] bg-[var(--linear-surface)] text-[13px] text-[var(--linear-text)] placeholder:text-[var(--linear-muted)] focus:outline-none focus:ring-2 focus:ring-primary-500"
        @input="updateFilter('q', ($event.target as HTMLInputElement).value || undefined)"
      />
    </div>

    <!-- Status filter -->
    <Dropdown align="left" width="w-48">
      <template #trigger>
        <button 
          :class="triggerClass(selectedStatuses.length > 0)"
        >
          <Circle class="w-4 h-4" />
          {{ statusLabel() }}
        </button>
      </template>
      <template #default="{ close }">
        <DropdownItem
          @click="clearStatusFilters(); close()"
        >
          <Circle class="w-4 h-4 text-[var(--linear-muted)]" />
          All statuses
        </DropdownItem>
        <DropdownItem
          v-for="status in statuses.filter((item) => item.value !== undefined)"
          :key="status.value"
          @click="toggleStatus(status.value as IssueStatus)"
        >
          <span class="w-3.5 h-3.5 rounded-sm border border-[var(--linear-border)] flex items-center justify-center text-[10px]">
            <span v-if="selectedStatuses.includes(status.value as IssueStatus)">✓</span>
          </span>
          <LinearStatusIcon
            :name="STATUS_STATE_NAME[status.value as IssueStatus]"
            :size="14"
            glyph-bg="var(--linear-overlay-bg)"
          />
          {{ status.label }}
        </DropdownItem>
      </template>
    </Dropdown>

    <!-- Priority filter -->
    <Dropdown align="left" width="w-48">
      <template #trigger>
        <button 
          :class="triggerClass(filters.priority !== undefined)"
        >
          <ArrowUp class="w-4 h-4" />
          {{ getPriorityLabel(filters.priority) }}
        </button>
      </template>
      <template #default="{ close }">
        <DropdownItem
          v-for="priority in priorities"
          :key="priority.value ?? 'all'"
          @click="updateFilter('priority', priority.value); close()"
        >
          <LinearPriorityIcon
            v-if="priority.value !== undefined"
            class="text-[var(--linear-muted)]"
            :priority="priority.value"
            :size="16"
          />
          <component v-else :is="priority.icon" :class="cn('w-4 h-4', priority.color)" />
          {{ priority.label }}
        </DropdownItem>
      </template>
    </Dropdown>

    <!-- Assignee filter -->
    <Dropdown align="left" width="w-48">
      <template #trigger>
        <button 
          :class="triggerClass(filters.assigneeId !== undefined)"
        >
          <User class="w-4 h-4" />
          {{ getAssigneeLabel(filters.assigneeId) }}
        </button>
      </template>
      <template #default="{ close }">
        <DropdownItem @click="updateFilter('assigneeId', undefined); close()">
          <User class="w-4 h-4 text-[var(--linear-muted)]" />
          All
        </DropdownItem>
        <DropdownItem @click="updateFilter('assigneeId', currentUser?.id); close()">
          <User class="w-4 h-4 text-indigo-400" />
          Assigned to me
        </DropdownItem>
        <DropdownItem @click="updateFilter('assigneeId', 'unassigned'); close()">
          <User class="w-4 h-4 text-[var(--linear-muted)]" />
          Unassigned
        </DropdownItem>
        <div v-if="assigneeOptions.length > 0" class="border-t border-[var(--linear-border)] my-1" />
        <DropdownItem
          v-for="user in assigneeOptions"
          :key="user.id"
          @click="updateFilter('assigneeId', user.id); close()"
        >
          <User class="w-4 h-4 text-[var(--linear-muted)]" />
          {{ user.id === currentUser?.id ? `${user.name} (me)` : user.name }}
        </DropdownItem>
      </template>
    </Dropdown>

    <!-- Clear filters -->
    <button
      v-if="hasActiveFilters"
      @click="clearFilters"
      class="flex items-center gap-1.5 px-2.5 py-1.5 rounded text-[13px] text-[var(--linear-muted)] hover:bg-[var(--linear-surface)] hover:text-[var(--linear-text)] transition-colors"
    >
      <X class="w-4 h-4" />
      Clear
    </button>

    <div class="flex-1" />

    <!-- Sort -->
    <Dropdown align="right" width="w-40">
      <template #trigger>
        <button class="flex items-center gap-1.5 px-2.5 py-1.5 rounded text-[13px] text-[var(--linear-muted)] hover:bg-[var(--linear-surface)] hover:text-[var(--linear-text)] transition-colors">
          <component :is="filters.direction === 'asc' ? SortAsc : SortDesc" class="w-4 h-4" />
          {{ getSortLabel(filters.sort) }}
        </button>
      </template>
      <template #default="{ close }">
        <DropdownItem
          v-for="option in sortOptions"
          :key="option.value"
          @click="updateFilter('sort', option.value as Filters['sort']); close()"
        >
          {{ option.label }}
        </DropdownItem>
        <div class="border-t border-[var(--linear-border)] my-1" />
        <DropdownItem @click="toggleDirection(); close()">
          <component :is="filters.direction === 'asc' ? SortDesc : SortAsc" class="w-4 h-4" />
          {{ filters.direction === 'asc' ? 'Descending' : 'Ascending' }}
        </DropdownItem>
      </template>
    </Dropdown>
  </div>
</template>
