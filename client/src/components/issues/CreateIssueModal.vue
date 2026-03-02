<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useAppStore } from '@/stores/app'
import { useIssuesStore } from '@/stores/issues'
import Modal from '@/components/ui/Modal.vue'
import Button from '@/components/ui/Button.vue'
import Input from '@/components/ui/Input.vue'
import type { IssueStatus, IssuePriority } from '@/types'
import {
  Circle,
  CheckCircle2,
  XCircle,
  Clock,
  AlertTriangle,
  ArrowUp,
  ArrowRight,
  ArrowDown,
  Minus
} from 'lucide-vue-next'

const props = defineProps<{
  open: boolean
  teamId?: string
}>()

const emit = defineEmits<{
  (e: 'close'): void
  (e: 'created', issue: unknown): void
}>()

const authStore = useAuthStore()
const appStore = useAppStore()
const issuesStore = useIssuesStore()

const teams = computed(() => appStore.teams)
const projects = computed(() => appStore.projects)
const currentUser = computed(() => authStore.user)

const title = ref('')
const description = ref('')
const selectedTeamId = ref(props.teamId || '')
const selectedStatus = ref<IssueStatus>('backlog')
const selectedPriority = ref<IssuePriority>(0)
const selectedAssigneeId = ref<string | undefined>()
const selectedProjectId = ref<string | undefined>()
const dueDate = ref<string | undefined>()
const creating = ref(false)
const error = ref('')

// Reset form when modal opens
watch(() => props.open, (open) => {
  if (open) {
    title.value = ''
    description.value = ''
    selectedTeamId.value = props.teamId || teams.value[0]?.id || ''
    selectedStatus.value = 'backlog'
    selectedPriority.value = 0
    selectedAssigneeId.value = undefined
    selectedProjectId.value = undefined
    dueDate.value = undefined
    error.value = ''
  }
})

const statuses: { value: IssueStatus; label: string; icon: typeof Circle; color: string }[] = [
  { value: 'backlog', label: 'Backlog', icon: Circle, color: 'text-gray-400' },
  { value: 'todo', label: 'Todo', icon: Circle, color: 'text-[var(--linear-muted)]' },
  { value: 'in_progress', label: 'In Progress', icon: Clock, color: 'text-yellow-500' },
  { value: 'in_review', label: 'In Review', icon: Clock, color: 'text-blue-500' },
  { value: 'done', label: 'Done', icon: CheckCircle2, color: 'text-green-500' },
  { value: 'canceled', label: 'Canceled', icon: XCircle, color: 'text-red-400' },
]

const priorities: { value: IssuePriority; label: string; icon: typeof Minus; color: string }[] = [
  { value: 0, label: 'No priority', icon: Minus, color: 'text-gray-400' },
  { value: 1, label: 'Urgent', icon: AlertTriangle, color: 'text-red-500' },
  { value: 2, label: 'High', icon: ArrowUp, color: 'text-orange-500' },
  { value: 3, label: 'Medium', icon: ArrowRight, color: 'text-yellow-500' },
  { value: 4, label: 'Low', icon: ArrowDown, color: 'text-blue-500' },
]

async function handleSubmit() {
  if (!title.value.trim() || !selectedTeamId.value) return

  creating.value = true
  error.value = ''

  try {
    const issue = await issuesStore.createIssue({
      teamId: selectedTeamId.value,
      title: title.value.trim(),
      description: description.value || undefined,
      status: selectedStatus.value,
      priority: selectedPriority.value,
      assigneeId: selectedAssigneeId.value,
      projectId: selectedProjectId.value,
      dueDate: dueDate.value,
    })

    if (issue) {
      emit('created', issue)
      emit('close')
    }
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Failed to create issue'
  } finally {
    creating.value = false
  }
}
</script>

<template>
  <Modal :open="open" @close="emit('close')" size="lg" title="Create issue">
    <form @submit.prevent="handleSubmit" class="space-y-4">
      <div v-if="error" class="p-3 bg-red-500/10 border border-red-500/30 rounded-lg text-sm text-red-400">
        {{ error }}
      </div>

      <!-- Title -->
      <div>
        <Input
          v-model="title"
          type="text"
          placeholder="Issue title"
          required
          autofocus
          class="text-lg font-medium"
        />
      </div>

      <!-- Description -->
      <div>
        <textarea
          v-model="description"
          rows="3"
          placeholder="Add description..."
          class="w-full px-3 py-2 text-sm rounded-md border border-[var(--linear-border)] bg-[var(--linear-elevated)] text-[var(--linear-text)] placeholder:text-[var(--linear-muted)] focus:ring-2 focus:ring-primary-500 focus:border-transparent resize-none"
        />
      </div>

      <!-- Properties grid -->
      <div class="grid grid-cols-2 gap-3">
        <!-- Team selector -->
        <div>
          <label class="block text-xs font-medium text-[var(--linear-muted)] mb-1">Team</label>
          <select
            v-model="selectedTeamId"
            class="w-full px-3 py-2 text-sm rounded-md border border-[var(--linear-border)] bg-[var(--linear-elevated)] text-[var(--linear-text)]"
          >
            <option v-for="team in teams" :key="team.id" :value="team.id">
              {{ team.key }} - {{ team.name }}
            </option>
          </select>
        </div>

        <!-- Status selector -->
        <div>
          <label class="block text-xs font-medium text-[var(--linear-muted)] mb-1">Status</label>
          <select
            v-model="selectedStatus"
            class="w-full px-3 py-2 text-sm rounded-md border border-[var(--linear-border)] bg-[var(--linear-elevated)] text-[var(--linear-text)]"
          >
            <option v-for="status in statuses" :key="status.value" :value="status.value">
              {{ status.label }}
            </option>
          </select>
        </div>

        <!-- Priority selector -->
        <div>
          <label class="block text-xs font-medium text-[var(--linear-muted)] mb-1">Priority</label>
          <select
            v-model="selectedPriority"
            class="w-full px-3 py-2 text-sm rounded-md border border-[var(--linear-border)] bg-[var(--linear-elevated)] text-[var(--linear-text)]"
          >
            <option v-for="priority in priorities" :key="priority.value" :value="priority.value">
              {{ priority.label }}
            </option>
          </select>
        </div>

        <!-- Assignee selector -->
        <div>
          <label class="block text-xs font-medium text-[var(--linear-muted)] mb-1">Assignee</label>
          <select
            v-model="selectedAssigneeId"
            class="w-full px-3 py-2 text-sm rounded-md border border-[var(--linear-border)] bg-[var(--linear-elevated)] text-[var(--linear-text)]"
          >
            <option :value="undefined">Unassigned</option>
            <option v-if="currentUser" :value="currentUser.id">{{ currentUser.name }} (me)</option>
          </select>
        </div>

        <!-- Project selector -->
        <div>
          <label class="block text-xs font-medium text-[var(--linear-muted)] mb-1">Project</label>
          <select
            v-model="selectedProjectId"
            class="w-full px-3 py-2 text-sm rounded-md border border-[var(--linear-border)] bg-[var(--linear-elevated)] text-[var(--linear-text)]"
          >
            <option :value="undefined">No project</option>
            <option v-for="project in projects" :key="project.id" :value="project.id">
              {{ project.name }}
            </option>
          </select>
        </div>

        <!-- Due date -->
        <div>
          <label class="block text-xs font-medium text-[var(--linear-muted)] mb-1">Due date</label>
          <Input
            v-model="dueDate"
            type="date"
          />
        </div>
      </div>

      <!-- Actions -->
      <div class="flex justify-end gap-3 pt-4 border-t border-[var(--linear-border)]">
        <Button type="button" variant="ghost" @click="emit('close')">
          Cancel
        </Button>
        <Button type="submit" :loading="creating" :disabled="!title.trim() || !selectedTeamId">
          Create issue
        </Button>
      </div>
    </form>
  </Modal>
</template>
