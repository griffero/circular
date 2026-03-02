<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useAppStore } from '@/stores/app'
import { useIssuesStore } from '@/stores/issues'
import { cn } from '@/utils/cn'
import Button from '@/components/ui/Button.vue'
import Avatar from '@/components/ui/Avatar.vue'
import Dropdown from '@/components/ui/Dropdown.vue'
import DropdownItem from '@/components/ui/DropdownItem.vue'
import type { Issue, IssueStatus, IssuePriority } from '@/types'
import {
  X,
  ExternalLink,
  Copy,
  Trash2,
  MoreHorizontal,
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
  FolderKanban,
  Send,
  MessageSquare
} from 'lucide-vue-next'

const props = defineProps<{
  issue: Issue | null
}>()

const emit = defineEmits<{
  (e: 'close'): void
  (e: 'updated', issue: Issue): void
  (e: 'deleted'): void
}>()

const router = useRouter()
const authStore = useAuthStore()
const appStore = useAppStore()
const issuesStore = useIssuesStore()

const currentUser = computed(() => authStore.user)
const projects = computed(() => appStore.projects)
const comments = computed(() => issuesStore.comments)

const editingTitle = ref(false)
const editingDescription = ref(false)
const titleInput = ref('')
const descriptionInput = ref('')
const newComment = ref('')
const saving = ref(false)

// Watch for issue changes
watch(
  () => props.issue,
  (issue) => {
    if (issue) {
      titleInput.value = issue.title
      descriptionInput.value = issue.description || ''
      // Fetch labels and comments
      issuesStore.fetchLabels()
      issuesStore.fetchComments(issue.id)
    }
  },
  { immediate: true }
)

const statuses: { value: IssueStatus; label: string; icon: typeof Circle; color: string }[] = [
  { value: 'backlog', label: 'Backlog', icon: Circle, color: 'text-[var(--linear-muted)]' },
  { value: 'todo', label: 'Todo', icon: Circle, color: 'text-[var(--linear-muted)]' },
  { value: 'in_progress', label: 'In Progress', icon: Clock, color: 'text-yellow-500' },
  { value: 'in_review', label: 'In Review', icon: Clock, color: 'text-blue-500' },
  { value: 'done', label: 'Done', icon: CheckCircle2, color: 'text-green-500' },
  { value: 'canceled', label: 'Canceled', icon: XCircle, color: 'text-red-400' },
]

const priorities: { value: IssuePriority; label: string; icon: typeof Minus; color: string }[] = [
  { value: 0, label: 'No priority', icon: Minus, color: 'text-[var(--linear-muted)]' },
  { value: 1, label: 'Urgent', icon: AlertTriangle, color: 'text-red-500' },
  { value: 2, label: 'High', icon: ArrowUp, color: 'text-orange-500' },
  { value: 3, label: 'Medium', icon: ArrowRight, color: 'text-yellow-500' },
  { value: 4, label: 'Low', icon: ArrowDown, color: 'text-blue-500' },
]

function getStatus(status: IssueStatus) {
  return statuses.find(s => s.value === status) || statuses[0]
}

function getPriority(priority: IssuePriority) {
  return priorities.find(p => p.value === priority) || priorities[0]
}

async function updateTitle() {
  if (!props.issue || titleInput.value === props.issue.title) {
    editingTitle.value = false
    return
  }

  saving.value = true
  try {
    const updated = await issuesStore.updateIssue(props.issue.id, { title: titleInput.value })
    if (updated) emit('updated', updated)
  } finally {
    saving.value = false
    editingTitle.value = false
  }
}

async function updateDescription() {
  if (!props.issue) {
    editingDescription.value = false
    return
  }

  saving.value = true
  try {
    const updated = await issuesStore.updateIssue(props.issue.id, { description: descriptionInput.value })
    if (updated) emit('updated', updated)
  } finally {
    saving.value = false
    editingDescription.value = false
  }
}

async function updateStatus(status: IssueStatus) {
  if (!props.issue) return

  saving.value = true
  try {
    const updated = await issuesStore.updateIssue(props.issue.id, { status })
    if (updated) emit('updated', updated)
  } finally {
    saving.value = false
  }
}

async function updatePriority(priority: IssuePriority) {
  if (!props.issue) return

  saving.value = true
  try {
    const updated = await issuesStore.updateIssue(props.issue.id, { priority })
    if (updated) emit('updated', updated)
  } finally {
    saving.value = false
  }
}

async function updateAssignee(assigneeId: string | null) {
  if (!props.issue) return

  saving.value = true
  try {
    const updated = await issuesStore.updateIssue(props.issue.id, { assigneeId })
    if (updated) emit('updated', updated)
  } finally {
    saving.value = false
  }
}

async function updateProject(projectId: string | null) {
  if (!props.issue) return

  saving.value = true
  try {
    const updated = await issuesStore.updateIssue(props.issue.id, { projectId })
    if (updated) emit('updated', updated)
  } finally {
    saving.value = false
  }
}

async function submitComment() {
  if (!props.issue || !newComment.value.trim()) return

  try {
    await issuesStore.createComment(props.issue.id, newComment.value.trim())
    newComment.value = ''
  } catch (err) {
    console.error('Failed to create comment:', err)
  }
}

async function handleDelete() {
  if (!props.issue) return
  if (!confirm('Are you sure you want to delete this issue?')) return

  try {
    await issuesStore.deleteIssue(props.issue.id)
    emit('deleted')
    emit('close')
  } catch (err) {
    console.error('Failed to delete issue:', err)
  }
}

function copyIdentifier() {
  if (props.issue) {
    navigator.clipboard.writeText(props.issue.identifier)
  }
}

function openFullPage() {
  if (props.issue) {
    router.push(`/issue/${props.issue.id}`)
    emit('close')
  }
}

function formatDate(dateString: string) {
  return new Date(dateString).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}
</script>

<template>
  <div v-if="issue" class="w-96 h-full flex flex-col border-l border-[var(--linear-border)] bg-[var(--linear-elevated)]">
    <!-- Header -->
    <div class="flex items-center justify-between px-4 py-3 border-b border-[var(--linear-border)]">
      <div class="flex items-center gap-2">
        <span class="text-sm font-mono text-[var(--linear-muted)]">{{ issue.identifier }}</span>
        <button 
          @click="copyIdentifier"
          class="p-1 hover:bg-[var(--linear-surface)] rounded"
          title="Copy identifier"
        >
          <Copy class="h-3.5 w-3.5 text-[var(--linear-muted)]" />
        </button>
      </div>
      <div class="flex items-center gap-1">
        <button
          @click="openFullPage"
          class="p-1.5 hover:bg-[var(--linear-surface)] rounded"
          title="Open full page"
        >
          <ExternalLink class="h-4 w-4 text-[var(--linear-muted)]" />
        </button>
        <Dropdown align="right" width="w-40">
          <template #trigger>
            <button class="p-1.5 hover:bg-[var(--linear-surface)] rounded">
              <MoreHorizontal class="h-4 w-4 text-[var(--linear-muted)]" />
            </button>
          </template>
          <template #default="{ close }">
            <DropdownItem danger @click="handleDelete(); close()">
              <Trash2 class="h-4 w-4" />
              Delete issue
            </DropdownItem>
          </template>
        </Dropdown>
        <button
          @click="emit('close')"
          class="p-1.5 hover:bg-[var(--linear-surface)] rounded"
        >
          <X class="h-4 w-4 text-[var(--linear-muted)]" />
        </button>
      </div>
    </div>

    <!-- Content -->
    <div class="flex-1 overflow-auto">
      <div class="p-4 space-y-4">
        <!-- Title -->
        <div>
          <div
            v-if="!editingTitle"
            @click="editingTitle = true; titleInput = issue.title"
            class="text-lg font-semibold text-[var(--linear-text)] cursor-text hover:bg-[var(--linear-surface)] rounded px-2 py-1 -mx-2"
          >
            {{ issue.title }}
          </div>
          <input
            v-else
            v-model="titleInput"
            @blur="updateTitle"
            @keydown.enter="updateTitle"
            @keydown.escape="editingTitle = false; titleInput = issue.title"
            class="w-full text-lg font-semibold text-[var(--linear-text)] bg-transparent border-b-2 border-primary-500 px-2 py-1 -mx-2 focus:outline-none"
            autofocus
          />
        </div>

        <!-- Description -->
        <div>
          <div
            v-if="!editingDescription"
            @click="editingDescription = true; descriptionInput = issue.description || ''"
            :class="cn(
              'cursor-text',
              'hover:bg-[var(--linear-surface)] rounded px-2 py-1 -mx-2 min-h-[60px]',
              issue.description ? 'prose prose-sm max-w-none prose-p:my-2 prose-ul:my-2 prose-ol:my-2' : 'text-sm text-[var(--linear-muted)]'
            )"
          >
            <div v-if="issue.description" v-html="issue.description" />
            <div v-else>Add description...</div>
          </div>
          <textarea
            v-else
            v-model="descriptionInput"
            @blur="updateDescription"
            @keydown.escape="editingDescription = false; descriptionInput = issue.description || ''"
            rows="4"
            class="w-full text-sm text-[var(--linear-text)] bg-transparent border border-[var(--linear-border)] rounded-md px-2 py-1 focus:outline-none focus:ring-2 focus:ring-primary-500 resize-none"
            placeholder="Add description..."
            autofocus
          />
        </div>

        <!-- Properties -->
        <div class="space-y-3 pt-4 border-t border-[var(--linear-border)]">
          <!-- Status -->
          <div class="flex items-center gap-3">
            <span class="text-xs font-medium text-[var(--linear-muted)] w-20">Status</span>
            <Dropdown align="left" width="w-44">
              <template #trigger>
                <button class="flex items-center gap-2 px-2 py-1 hover:bg-[var(--linear-surface)] rounded text-sm">
                  <component :is="getStatus(issue.status).icon" :class="cn('h-4 w-4', getStatus(issue.status).color)" />
                  {{ getStatus(issue.status).label }}
                </button>
              </template>
              <template #default="{ close }">
                <DropdownItem
                  v-for="status in statuses"
                  :key="status.value"
                  @click="updateStatus(status.value); close()"
                >
                  <component :is="status.icon" :class="cn('h-4 w-4', status.color)" />
                  {{ status.label }}
                </DropdownItem>
              </template>
            </Dropdown>
          </div>

          <!-- Priority -->
          <div class="flex items-center gap-3">
            <span class="text-xs font-medium text-[var(--linear-muted)] w-20">Priority</span>
            <Dropdown align="left" width="w-44">
              <template #trigger>
                <button class="flex items-center gap-2 px-2 py-1 hover:bg-[var(--linear-surface)] rounded text-sm">
                  <component :is="getPriority(issue.priority).icon" :class="cn('h-4 w-4', getPriority(issue.priority).color)" />
                  {{ getPriority(issue.priority).label }}
                </button>
              </template>
              <template #default="{ close }">
                <DropdownItem
                  v-for="priority in priorities"
                  :key="priority.value"
                  @click="updatePriority(priority.value); close()"
                >
                  <component :is="priority.icon" :class="cn('h-4 w-4', priority.color)" />
                  {{ priority.label }}
                </DropdownItem>
              </template>
            </Dropdown>
          </div>

          <!-- Assignee -->
          <div class="flex items-center gap-3">
            <span class="text-xs font-medium text-[var(--linear-muted)] w-20">Assignee</span>
            <Dropdown align="left" width="w-48">
              <template #trigger>
                <button class="flex items-center gap-2 px-2 py-1 hover:bg-[var(--linear-surface)] rounded text-sm">
                  <template v-if="issue.assignee">
                    <Avatar :name="issue.assignee.name" size="xs" />
                    {{ issue.assignee.name }}
                  </template>
                  <template v-else>
                    <User class="h-4 w-4 text-[var(--linear-muted)]" />
                    <span class="text-[var(--linear-muted)]">Unassigned</span>
                  </template>
                </button>
              </template>
              <template #default="{ close }">
                <DropdownItem @click="updateAssignee(null); close()">
                  <User class="h-4 w-4 text-[var(--linear-muted)]" />
                  Unassigned
                </DropdownItem>
                <DropdownItem v-if="currentUser" @click="updateAssignee(currentUser.id); close()">
                  <Avatar :name="currentUser.name" size="xs" />
                  {{ currentUser.name }} (me)
                </DropdownItem>
              </template>
            </Dropdown>
          </div>

          <!-- Project -->
          <div class="flex items-center gap-3">
            <span class="text-xs font-medium text-[var(--linear-muted)] w-20">Project</span>
            <Dropdown align="left" width="w-48">
              <template #trigger>
                <button class="flex items-center gap-2 px-2 py-1 hover:bg-[var(--linear-surface)] rounded text-sm">
                  <template v-if="issue.project">
                    <FolderKanban class="h-4 w-4 text-[var(--linear-muted)]" />
                    {{ issue.project.name }}
                  </template>
                  <template v-else>
                    <FolderKanban class="h-4 w-4 text-[var(--linear-muted)]" />
                    <span class="text-[var(--linear-muted)]">No project</span>
                  </template>
                </button>
              </template>
              <template #default="{ close }">
                <DropdownItem @click="updateProject(null); close()">
                  <FolderKanban class="h-4 w-4 text-[var(--linear-muted)]" />
                  No project
                </DropdownItem>
                <DropdownItem
                  v-for="project in projects"
                  :key="project.id"
                  @click="updateProject(project.id); close()"
                >
                  <div
                    class="w-4 h-4 rounded flex items-center justify-center"
                    :style="{ backgroundColor: project.color || '#6b7280' }"
                  >
                    <FolderKanban class="h-2.5 w-2.5 text-[var(--linear-text)]" />
                  </div>
                  {{ project.name }}
                </DropdownItem>
              </template>
            </Dropdown>
          </div>
        </div>

        <!-- Comments -->
        <div class="pt-4 border-t border-[var(--linear-border)]">
          <h3 class="text-sm font-medium text-[var(--linear-text)] mb-3 flex items-center gap-2">
            <MessageSquare class="h-4 w-4" />
            Activity
          </h3>

          <div v-if="comments.length === 0" class="text-sm text-[var(--linear-muted)] text-center py-4">
            No comments yet
          </div>

          <div v-else class="space-y-3 mb-4">
            <div
              v-for="comment in comments"
              :key="comment.id"
              class="flex gap-3"
            >
              <Avatar :name="comment.user?.name || 'U'" size="sm" />
              <div class="flex-1">
                <div class="flex items-center gap-2 mb-1">
                  <span class="text-sm font-medium text-[var(--linear-text)]">
                    {{ comment.user?.name }}
                  </span>
                  <span class="text-xs text-[var(--linear-muted)]">
                    {{ formatDate(comment.createdAt) }}
                  </span>
                </div>
                <p class="text-sm text-[var(--linear-muted)]">
                  {{ comment.body }}
                </p>
              </div>
            </div>
          </div>

          <!-- New comment -->
          <div class="flex gap-2">
            <input
              v-model="newComment"
              @keydown.enter.prevent="submitComment"
              type="text"
              placeholder="Write a comment..."
              class="flex-1 text-sm px-3 py-2 border border-[var(--linear-border)] rounded-md bg-[var(--linear-bg)] text-[var(--linear-text)] focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
            <Button size="sm" @click="submitComment" :disabled="!newComment.trim()">
              <Send class="h-4 w-4" />
            </Button>
          </div>
        </div>
      </div>
    </div>

    <!-- Footer -->
    <div class="px-4 py-2 text-xs text-[var(--linear-muted)] border-t border-[var(--linear-border)]">
      Created {{ formatDate(issue.createdAt) }}
    </div>
  </div>
</template>
