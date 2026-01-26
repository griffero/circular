<script setup lang="ts">
import { computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import type { IssueStatus, IssuePriority } from '@/types'
import { cn } from '@/utils/cn'
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
  SortAsc,
  SortDesc
} from 'lucide-vue-next'

interface Filters {
  status?: IssueStatus
  priority?: IssuePriority
  assigneeId?: string
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

const currentUser = computed(() => authStore.user)

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

const sortOptions: { value: string; label: string }[] = [
  { value: 'created_at', label: 'Created' },
  { value: 'updated_at', label: 'Updated' },
  { value: 'priority', label: 'Priority' },
  { value: 'due_date', label: 'Due date' },
]

const hasActiveFilters = computed(() => {
  return props.filters.status !== undefined || 
         props.filters.priority !== undefined || 
         props.filters.assigneeId !== undefined
})

function updateFilter<K extends keyof Filters>(key: K, value: Filters[K]) {
  emit('update:filters', { ...props.filters, [key]: value })
}

function clearFilters() {
  emit('update:filters', {
    sort: props.filters.sort,
    direction: props.filters.direction
  })
}

function toggleDirection() {
  const newDirection = props.filters.direction === 'asc' ? 'desc' : 'asc'
  emit('update:filters', { ...props.filters, direction: newDirection })
}

function getStatusLabel(status?: IssueStatus) {
  return statuses.find(s => s.value === status)?.label || 'All statuses'
}

function getPriorityLabel(priority?: IssuePriority) {
  return priorities.find(p => p.value === priority)?.label || 'All priorities'
}

function getSortLabel(sort?: string) {
  return sortOptions.find(s => s.value === sort)?.label || 'Created'
}
</script>

<template>
  <div class="flex items-center gap-2 flex-wrap">
    <!-- Status filter -->
    <Dropdown align="left" width="w-48">
      <template #trigger>
        <button 
          :class="cn(
            'flex items-center gap-1.5 px-2.5 py-1.5 rounded text-[13px] transition-colors',
            filters.status !== undefined
              ? 'bg-[#2a2a2a] text-white'
              : 'text-gray-400 hover:bg-[#1a1a1a] hover:text-white'
          )"
        >
          <Circle class="w-4 h-4" />
          {{ getStatusLabel(filters.status) }}
        </button>
      </template>
      <template #default="{ close }">
        <DropdownItem
          v-for="status in statuses"
          :key="status.value || 'all'"
          @click="updateFilter('status', status.value); close()"
        >
          <component :is="status.icon" :class="cn('w-4 h-4', status.color)" />
          {{ status.label }}
        </DropdownItem>
      </template>
    </Dropdown>

    <!-- Priority filter -->
    <Dropdown align="left" width="w-48">
      <template #trigger>
        <button 
          :class="cn(
            'flex items-center gap-1.5 px-2.5 py-1.5 rounded text-[13px] transition-colors',
            filters.priority !== undefined
              ? 'bg-[#2a2a2a] text-white'
              : 'text-gray-400 hover:bg-[#1a1a1a] hover:text-white'
          )"
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
          <component :is="priority.icon" :class="cn('w-4 h-4', priority.color)" />
          {{ priority.label }}
        </DropdownItem>
      </template>
    </Dropdown>

    <!-- Assignee filter -->
    <Dropdown align="left" width="w-48">
      <template #trigger>
        <button 
          :class="cn(
            'flex items-center gap-1.5 px-2.5 py-1.5 rounded text-[13px] transition-colors',
            filters.assigneeId !== undefined
              ? 'bg-[#2a2a2a] text-white'
              : 'text-gray-400 hover:bg-[#1a1a1a] hover:text-white'
          )"
        >
          <User class="w-4 h-4" />
          {{ filters.assigneeId === currentUser?.id ? 'Assigned to me' : filters.assigneeId === 'unassigned' ? 'Unassigned' : 'Assignee' }}
        </button>
      </template>
      <template #default="{ close }">
        <DropdownItem @click="updateFilter('assigneeId', undefined); close()">
          <User class="w-4 h-4 text-gray-400" />
          All
        </DropdownItem>
        <DropdownItem @click="updateFilter('assigneeId', currentUser?.id); close()">
          <User class="w-4 h-4 text-indigo-400" />
          Assigned to me
        </DropdownItem>
        <DropdownItem @click="updateFilter('assigneeId', 'unassigned'); close()">
          <User class="w-4 h-4 text-gray-400" />
          Unassigned
        </DropdownItem>
      </template>
    </Dropdown>

    <!-- Clear filters -->
    <button
      v-if="hasActiveFilters"
      @click="clearFilters"
      class="flex items-center gap-1.5 px-2.5 py-1.5 rounded text-[13px] text-gray-400 hover:bg-[#1a1a1a] hover:text-white transition-colors"
    >
      <X class="w-4 h-4" />
      Clear
    </button>

    <div class="flex-1" />

    <!-- Sort -->
    <Dropdown align="right" width="w-40">
      <template #trigger>
        <button class="flex items-center gap-1.5 px-2.5 py-1.5 rounded text-[13px] text-gray-400 hover:bg-[#1a1a1a] hover:text-white transition-colors">
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
        <div class="border-t border-[#2a2a2a] my-1" />
        <DropdownItem @click="toggleDirection(); close()">
          <component :is="filters.direction === 'asc' ? SortDesc : SortAsc" class="w-4 h-4" />
          {{ filters.direction === 'asc' ? 'Descending' : 'Ascending' }}
        </DropdownItem>
      </template>
    </Dropdown>
  </div>
</template>
