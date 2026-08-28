<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { cn } from '@/utils/cn'
import Avatar from '@/components/ui/Avatar.vue'
import OriginBadge from '@/components/ui/OriginBadge.vue'
import LinearStatusIcon from '@/components/icons/LinearStatusIcon.vue'
import LinearPriorityIcon from '@/components/icons/LinearPriorityIcon.vue'
import type { Issue, IssueStatus, WorkflowStateType } from '@/types'
import { Calendar } from 'lucide-vue-next'

const props = defineProps<{
  issue: Issue
}>()

const emit = defineEmits<{
  (e: 'click', issue: Issue): void
}>()

const router = useRouter()

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
    <!-- Priority indicator: Linear keeps the slot and draws dashes at priority 0 -->
    <div class="flex-shrink-0 text-[var(--linear-muted)]">
      <LinearPriorityIcon :priority="issue.priority" :size="16" />
    </div>

    <!-- Status icon -->
    <button
      @click.stop
      :class="cn('flex-shrink-0 hover:scale-110 transition-transform')"
    >
      <LinearStatusIcon
        :name="issue.workflowState?.name"
        :type="issue.workflowState?.stateType"
        :size="14"
      />
    </button>

    <!-- Identifier + Origin -->
    <span class="issue-identifier flex items-center gap-1 flex-shrink-0">
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
