<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { cn } from '@/utils/cn'
import Avatar from '@/components/ui/Avatar.vue'
import OriginBadge from '@/components/ui/OriginBadge.vue'
import type { Issue, IssueStatus, IssuePriority, WorkflowStateType } from '@/types'
import {
  Circle,
  CheckCircle2,
  XCircle,
  Clock,
  AlertTriangle,
  ArrowUp,
  ArrowRight,
  ArrowDown,
  Minus,
  Calendar
} from 'lucide-vue-next'

const props = defineProps<{
  issue: Issue
}>()

const emit = defineEmits<{
  (e: 'click', issue: Issue): void
}>()

const router = useRouter()

const statusConfig: Record<IssueStatus, { icon: typeof Circle; color: string }> = {
  backlog: { icon: Circle, color: 'text-gray-400' },
  todo: { icon: Circle, color: 'text-gray-500' },
  in_progress: { icon: Clock, color: 'text-yellow-500' },
  in_review: { icon: Clock, color: 'text-blue-500' },
  done: { icon: CheckCircle2, color: 'text-green-500' },
  canceled: { icon: XCircle, color: 'text-red-400' },
}

const priorityConfig: Record<IssuePriority, { icon: typeof Minus; color: string; label: string }> = {
  0: { icon: Minus, color: 'text-gray-400', label: '' },
  1: { icon: AlertTriangle, color: 'text-red-500', label: 'Urgent' },
  2: { icon: ArrowUp, color: 'text-orange-500', label: 'High' },
  3: { icon: ArrowRight, color: 'text-yellow-500', label: 'Medium' },
  4: { icon: ArrowDown, color: 'text-blue-500', label: 'Low' },
}

function getEffectiveStatus(issue: Issue): IssueStatus {
  if (issue.workflowState?.stateType) {
    const map: Record<WorkflowStateType, IssueStatus> = {
      triage: 'backlog',
      backlog: 'backlog',
      unstarted: 'todo',
      started: 'in_progress',
      completed: 'done',
      canceled: 'canceled'
    }
    return map[issue.workflowState.stateType] || issue.status || 'backlog'
  }
  return issue.status || 'backlog'
}

const statusIcon = computed(() => statusConfig[getEffectiveStatus(props.issue)]?.icon || Circle)
const statusColor = computed(() => statusConfig[getEffectiveStatus(props.issue)]?.color || 'text-gray-400')
const priorityIcon = computed(() => priorityConfig[props.issue.priority]?.icon || Minus)
const priorityColor = computed(() => priorityConfig[props.issue.priority]?.color || 'text-gray-400')

const isOverdue = computed(() => {
  if (!props.issue.dueDate) return false
  return new Date(props.issue.dueDate) < new Date() && !['done', 'canceled'].includes(getEffectiveStatus(props.issue))
})

function handleClick() {
  emit('click', props.issue)
  router.push(`/issue/${props.issue.id}`)
}

function formatDate(dateString: string) {
  const date = new Date(dateString)
  const today = new Date()
  const diff = Math.ceil((date.getTime() - today.getTime()) / (1000 * 60 * 60 * 24))

  if (diff === 0) return 'Today'
  if (diff === 1) return 'Tomorrow'
  if (diff === -1) return 'Yesterday'
  if (diff < -1) return `${Math.abs(diff)} days ago`
  if (diff > 1 && diff <= 7) return `In ${diff} days`

  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
}
</script>

<template>
  <div
    @click="handleClick"
    :class="cn(
      'group flex items-center gap-3 px-4 py-2.5',
      'hover:bg-gray-50 dark:hover:bg-gray-800/50',
      'cursor-pointer transition-colors',
      'border-b border-gray-100 dark:border-gray-800 last:border-b-0'
    )"
  >
    <!-- Priority indicator -->
    <div v-if="issue.priority > 0" class="flex-shrink-0">
      <component :is="priorityIcon" :class="cn('h-4 w-4', priorityColor)" />
    </div>
    <div v-else class="w-4 flex-shrink-0" />

    <!-- Status icon -->
    <button
      @click.stop
      :class="cn('flex-shrink-0 hover:scale-110 transition-transform')"
    >
      <component :is="statusIcon" :class="cn('h-4 w-4', statusColor)" />
    </button>

    <!-- Identifier + Origin -->
    <span class="flex items-center gap-1 flex-shrink-0 text-xs font-mono text-gray-500">
      <OriginBadge :linear-id="issue.linearId" />
      <span class="w-16">{{ issue.identifier }}</span>
    </span>

    <!-- Title -->
    <span class="flex-1 text-sm text-gray-900 dark:text-gray-100 truncate">
      {{ issue.title }}
    </span>

    <!-- Labels -->
    <div v-if="issue.labels?.length" class="flex items-center gap-1 flex-shrink-0">
      <div
        v-for="label in issue.labels.slice(0, 2)"
        :key="label.id"
        :class="cn(
          'px-1.5 py-0.5 text-xs rounded',
          'bg-opacity-20 dark:bg-opacity-30'
        )"
        :style="{ backgroundColor: label.color + '33', color: label.color }"
      >
        {{ label.name }}
      </div>
      <span v-if="issue.labels.length > 2" class="text-xs text-gray-400">
        +{{ issue.labels.length - 2 }}
      </span>
    </div>

    <!-- Due date -->
    <div
      v-if="issue.dueDate"
      :class="cn(
        'flex items-center gap-1 text-xs flex-shrink-0',
        isOverdue ? 'text-red-500' : 'text-gray-500'
      )"
    >
      <Calendar class="h-3 w-3" />
      {{ formatDate(issue.dueDate) }}
    </div>

    <!-- Assignee -->
    <div class="flex-shrink-0">
      <Avatar
        v-if="issue.assignee"
        :name="issue.assignee.name"
        size="xs"
      />
      <div
        v-else
        class="w-5 h-5 rounded-full border border-dashed border-gray-300 dark:border-gray-600"
      />
    </div>
  </div>
</template>
