<script setup lang="ts">
import { computed, ref, onMounted, watch, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useIssuesStore } from '@/stores/issues'
import { useAppStore } from '@/stores/app'
import type { Issue, WorkflowState } from '@/types'
import Dropdown from '@/components/ui/Dropdown.vue'
import DropdownItem from '@/components/ui/DropdownItem.vue'
import Modal from '@/components/ui/Modal.vue'
import Button from '@/components/ui/Button.vue'
import Avatar from '@/components/ui/Avatar.vue'
import EmojiText from '@/components/ui/EmojiText.vue'
import EmojiIcon from '@/components/ui/EmojiIcon.vue'
import { useEmojiStore } from '@/stores/emoji'
import {
  ArrowLeft,
  Copy,
  Trash2,
  MoreHorizontal,
  Circle,
  CheckCircle2,
  XCircle,
  Clock,
  User,
  Tag,
  FolderKanban,
  Calendar,
  MessageSquare,
  Send,
  ChevronDown,
  Minus,
  AlertCircle,
  SignalHigh,
  SignalMedium,
  SignalLow,
  Check,
  CircleDashed
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const issuesStore = useIssuesStore()
const appStore = useAppStore()
const emojiStore = useEmojiStore()

const issueId = computed(() => route.params.issueId as string)

const issue = computed(() => issuesStore.currentIssue)
const currentUser = computed(() => authStore.user)
const loading = computed(() => issuesStore.loading)
const workflowStates = computed(() => issuesStore.workflowStates)
const labels = computed(() => issuesStore.labels)
const users = computed(() => appStore.users)
const projects = computed(() => appStore.projects)
const comments = computed(() => issuesStore.comments)

// Project search
const projectSearch = ref('')
const deleting = ref(false)
const showDeleteConfirm = ref(false)
const editingTitle = ref(false)
const titleDraft = ref('')
const titleSaving = ref(false)
const titleInputRef = ref<HTMLInputElement | null>(null)
const editingDescription = ref(false)
const descriptionDraft = ref('')
const descriptionSaving = ref(false)
const descriptionInputRef = ref<HTMLTextAreaElement | null>(null)
const newComment = ref('')
const commentsLoading = ref(false)

const filteredProjects = computed(() => {
  if (!projectSearch.value) return projects.value
  const search = projectSearch.value.toLowerCase()
  return projects.value.filter(p => p.name.toLowerCase().includes(search))
})

// Check if icon is emoji
function hasEmoji(icon?: string | null): boolean {
  return emojiStore.isRenderableEmoji(icon)
}

const priorities = [
  { value: 0, label: 'No priority', icon: Minus, color: 'text-[var(--linear-muted)]' },
  { value: 1, label: 'Urgent', icon: AlertCircle, color: 'text-red-500' },
  { value: 2, label: 'High', icon: SignalHigh, color: 'text-orange-500' },
  { value: 3, label: 'Medium', icon: SignalMedium, color: 'text-yellow-500' },
  { value: 4, label: 'Low', icon: SignalLow, color: 'text-blue-500' },
]

const statusIcons: Record<string, { icon: any; color: string }> = {
  triage: { icon: Circle, color: 'text-[var(--linear-muted)]' },
  backlog: { icon: Circle, color: 'text-[var(--linear-muted)]' },
  unstarted: { icon: Circle, color: 'text-[var(--linear-muted)]' },
  started: { icon: Clock, color: 'text-yellow-500' },
  completed: { icon: CheckCircle2, color: 'text-green-500' },
  canceled: { icon: XCircle, color: 'text-red-400' },
}

function getStatusIcon(stateType?: string) {
  return statusIcons[stateType || 'backlog'] || statusIcons.backlog
}

function getPriority(value: number) {
  return priorities.find(p => p.value === value) || priorities[0]
}

// Update functions
async function updateStatus(state: WorkflowState) {
  if (!issue.value) return
  await issuesStore.updateIssue(issue.value.id, { workflowStateId: state.id })
}

async function updatePriority(priority: number) {
  if (!issue.value) return
  await issuesStore.updateIssue(issue.value.id, { priority })
}

async function updateAssignee(userId: string | null) {
  if (!issue.value) return
  await issuesStore.updateIssue(issue.value.id, { assigneeId: userId })
}

async function updateProject(projectId: string | null) {
  if (!issue.value) return
  await issuesStore.updateIssue(issue.value.id, { projectId })
}

async function updateDueDate(date: string | null) {
  if (!issue.value) return
  await issuesStore.updateIssue(issue.value.id, { dueDate: date })
}

function syncEditorDrafts() {
  titleDraft.value = issue.value?.title || ''
  descriptionDraft.value = issue.value?.description || ''
}

async function startTitleEdit() {
  if (!issue.value) return
  titleDraft.value = issue.value.title
  editingTitle.value = true
  await nextTick()
  titleInputRef.value?.focus()
  titleInputRef.value?.select()
}

function cancelTitleEdit() {
  editingTitle.value = false
  titleDraft.value = issue.value?.title || ''
}

async function saveTitleEdit() {
  if (!issue.value || titleSaving.value) return

  const nextTitle = titleDraft.value.trim()
  if (!nextTitle) {
    cancelTitleEdit()
    return
  }
  if (nextTitle === issue.value.title) {
    cancelTitleEdit()
    return
  }

  titleSaving.value = true
  try {
    await issuesStore.updateIssue(issue.value.id, { title: nextTitle })
    editingTitle.value = false
  } finally {
    titleSaving.value = false
  }
}

async function startDescriptionEdit() {
  if (!issue.value) return
  descriptionDraft.value = issue.value.description || ''
  editingDescription.value = true
  await nextTick()
  descriptionInputRef.value?.focus()
}

function cancelDescriptionEdit() {
  editingDescription.value = false
  descriptionDraft.value = issue.value?.description || ''
}

async function saveDescriptionEdit() {
  if (!issue.value || descriptionSaving.value) return
  if (descriptionDraft.value === (issue.value.description || '')) {
    cancelDescriptionEdit()
    return
  }

  descriptionSaving.value = true
  try {
    await issuesStore.updateIssue(issue.value.id, { description: descriptionDraft.value })
    editingDescription.value = false
  } finally {
    descriptionSaving.value = false
  }
}

function copyIdentifier() {
  if (!issue.value) return
  navigator.clipboard.writeText(issue.value.identifier)
}

function goBack() {
  if (window.history.length > 1) {
    router.back()
    return
  }

  if (issue.value?.team?.key) {
    router.push(`/team/${issue.value.team.key}/issues`)
    return
  }

  router.push('/')
}

async function deleteIssue() {
  if (!issue.value || deleting.value) return

  const redirectPath = issue.value.team?.key ? `/team/${issue.value.team.key}/issues` : '/my-issues'
  deleting.value = true
  try {
    await issuesStore.deleteIssue(issue.value.id)
    showDeleteConfirm.value = false
    router.push(redirectPath)
  } finally {
    deleting.value = false
  }
}

function openDeleteConfirm() {
  if (!issue.value || deleting.value) return
  showDeleteConfirm.value = true
}

function closeDeleteConfirm() {
  if (deleting.value) return
  showDeleteConfirm.value = false
}

async function toggleLabel(labelId: string) {
  if (!issue.value) return
  const currentLabelIds = issue.value.labels?.map(l => l.id) || []
  const newLabelIds = currentLabelIds.includes(labelId)
    ? currentLabelIds.filter(id => id !== labelId)
    : [...currentLabelIds, labelId]
  await issuesStore.updateIssue(issue.value.id, { labelIds: newLabelIds })
}

async function submitComment() {
  if (!issue.value || !newComment.value.trim()) return

  await issuesStore.createComment(issue.value.id, newComment.value.trim())
  newComment.value = ''
}

// Load issue when route changes
async function loadIssue() {
  if (issueId.value) {
    await issuesStore.fetchIssue(issueId.value)
    // Load workflow states for the team if we have the issue
    if (issue.value?.teamId) {
      await issuesStore.fetchWorkflowStates(issue.value.teamId)
      await issuesStore.fetchLabels(issue.value.teamId)
    }
    commentsLoading.value = true
    try {
      await issuesStore.fetchComments(issueId.value)
    } finally {
      commentsLoading.value = false
    }
  }
}

// Load users and projects
onMounted(async () => {
  await loadIssue()
  syncEditorDrafts()
  if (users.value.length === 0) {
    await appStore.fetchUsers()
  }
  if (projects.value.length === 0) {
    await appStore.fetchProjects()
  }
})

watch(issueId, loadIssue)
watch(issue, () => {
  if (!editingTitle.value && !editingDescription.value) {
    syncEditorDrafts()
  }
})

// Format date for display
function formatDate(dateString?: string | null) {
  if (!dateString) return null
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
}
</script>

<template>
  <div class="h-full flex bg-[var(--linear-bg)]">
    <!-- Main content -->
    <div class="flex-1 flex flex-col overflow-hidden">
      <!-- Header -->
      <div class="flex items-center justify-between gap-3 px-4 py-2 border-b border-[var(--linear-border)]">
        <div class="flex items-center gap-3">
          <button
            @click="goBack"
            class="p-1.5 hover:bg-[var(--linear-surface)] rounded text-[var(--linear-muted)] hover:text-[var(--linear-text)] transition-colors"
          >
            <ArrowLeft class="h-4 w-4" />
          </button>
          <span class="text-sm font-mono text-[var(--linear-muted)]">{{ issue?.identifier }}</span>
        </div>
        <div v-if="issue" class="flex items-center gap-1">
          <button
            @click="copyIdentifier"
            class="p-1.5 rounded text-[var(--linear-muted)] hover:text-[var(--linear-text)] hover:bg-[var(--linear-surface)] transition-colors"
            title="Copy identifier"
          >
            <Copy class="h-4 w-4" />
          </button>
          <Dropdown align="right" width="w-40">
            <template #trigger>
              <button class="p-1.5 rounded text-[var(--linear-muted)] hover:text-[var(--linear-text)] hover:bg-[var(--linear-surface)] transition-colors">
                <MoreHorizontal class="h-4 w-4" />
              </button>
            </template>
            <template #default="{ close }">
              <DropdownItem danger @click="openDeleteConfirm(); close()">
                <Trash2 class="h-4 w-4" />
                Delete issue
              </DropdownItem>
            </template>
          </Dropdown>
        </div>
      </div>

      <!-- Issue content -->
      <div v-if="loading" class="flex items-center justify-center py-16">
        <div class="animate-spin rounded-full h-8 w-8 border-2 border-[var(--linear-accent)] border-t-transparent"></div>
      </div>

      <div v-else-if="issue" class="flex-1 overflow-auto p-6">
        <div class="mb-4">
          <div v-if="editingTitle" class="space-y-2">
            <input
              ref="titleInputRef"
              v-model="titleDraft"
              type="text"
              class="w-full text-2xl font-semibold text-[var(--linear-text)] bg-[var(--linear-surface)] border border-[var(--linear-border)] rounded px-3 py-2 outline-none focus:border-[var(--linear-accent)]"
              placeholder="Issue title"
              @keydown.enter.prevent="saveTitleEdit"
              @keydown.esc.prevent="cancelTitleEdit"
            />
            <div class="flex items-center gap-2">
              <button
                class="px-2 py-1 text-xs rounded border border-[var(--linear-border)] text-[var(--linear-text)] hover:bg-[var(--linear-surface)] transition-colors disabled:opacity-60"
                :disabled="titleSaving"
                @click="saveTitleEdit"
              >
                Save
              </button>
              <button
                class="px-2 py-1 text-xs rounded text-[var(--linear-muted)] hover:text-[var(--linear-text)] hover:bg-[var(--linear-surface)] transition-colors"
                :disabled="titleSaving"
                @click="cancelTitleEdit"
              >
                Cancel
              </button>
            </div>
          </div>

          <div v-else class="group flex items-start gap-3">
            <h1 class="text-2xl font-semibold text-[var(--linear-text)] flex-1">
              {{ issue.title }}
            </h1>
            <button
              class="px-2 py-1 text-xs rounded text-[var(--linear-muted)] hover:text-[var(--linear-text)] hover:bg-[var(--linear-surface)] transition-colors opacity-0 group-hover:opacity-100"
              @click="startTitleEdit"
            >
              Edit
            </button>
          </div>
        </div>

        <div v-if="editingDescription" class="space-y-2 mb-8">
          <textarea
            ref="descriptionInputRef"
            v-model="descriptionDraft"
            rows="6"
            class="w-full text-sm text-[var(--linear-text)] bg-[var(--linear-surface)] border border-[var(--linear-border)] rounded px-3 py-2 outline-none focus:border-[var(--linear-accent)] resize-y"
            placeholder="Add description"
            @keydown.meta.enter.prevent="saveDescriptionEdit"
            @keydown.ctrl.enter.prevent="saveDescriptionEdit"
            @keydown.esc.prevent="cancelDescriptionEdit"
          />
          <div class="flex items-center gap-2">
            <button
              class="px-2 py-1 text-xs rounded border border-[var(--linear-border)] text-[var(--linear-text)] hover:bg-[var(--linear-surface)] transition-colors disabled:opacity-60"
              :disabled="descriptionSaving"
              @click="saveDescriptionEdit"
            >
              Save
            </button>
            <button
              class="px-2 py-1 text-xs rounded text-[var(--linear-muted)] hover:text-[var(--linear-text)] hover:bg-[var(--linear-surface)] transition-colors"
              :disabled="descriptionSaving"
              @click="cancelDescriptionEdit"
            >
              Cancel
            </button>
          </div>
        </div>

        <div
          v-else-if="issue.description"
          class="group text-sm text-[var(--linear-text)] whitespace-pre-wrap mb-8"
        >
          <div class="flex items-start gap-3">
            <div class="flex-1">
              <EmojiText :text="issue.description" />
            </div>
            <button
              class="px-2 py-1 text-xs rounded text-[var(--linear-muted)] hover:text-[var(--linear-text)] hover:bg-[var(--linear-surface)] transition-colors opacity-0 group-hover:opacity-100"
              @click="startDescriptionEdit"
            >
              Edit
            </button>
          </div>
        </div>
        <div v-else class="mb-8">
          <button
            class="text-sm text-[var(--linear-muted)] hover:text-[var(--linear-text)] hover:bg-[var(--linear-surface)] rounded px-2 py-1 transition-colors"
            @click="startDescriptionEdit"
          >
            Add description
          </button>
        </div>

        <!-- Activity -->
        <div class="border-t border-[var(--linear-border)] pt-6">
          <h2 class="text-sm font-medium text-[var(--linear-text)] mb-4 flex items-center gap-2">
            <MessageSquare class="h-4 w-4" />
            Activity
          </h2>

          <div v-if="commentsLoading" class="flex items-center justify-center py-6">
            <div class="animate-spin rounded-full h-5 w-5 border-2 border-[var(--linear-accent)] border-t-transparent"></div>
          </div>

          <div v-else-if="comments.length === 0" class="text-sm text-[var(--linear-muted)] text-center py-4">
            No activity yet
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
                <p class="text-sm text-[var(--linear-muted)] whitespace-pre-wrap">
                  {{ comment.body }}
                </p>
              </div>
            </div>
          </div>

          <div class="flex gap-2 mt-3">
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

      <div v-else class="flex items-center justify-center h-full">
        <div class="text-center">
          <p class="text-[var(--linear-muted)]">Issue not found</p>
          <button 
            @click="router.push('/')"
            class="mt-4 px-4 py-2 text-sm text-[var(--linear-muted)] hover:text-[var(--linear-text)] hover:bg-[var(--linear-surface)] rounded transition-colors"
          >
            Go back home
          </button>
        </div>
      </div>
    </div>

    <!-- Sidebar -->
    <div v-if="issue" class="w-72 border-l border-[var(--linear-border)] bg-[var(--linear-elevated)] p-4 overflow-auto">
      <div class="space-y-4">
        <!-- Status -->
        <div>
          <label class="text-xs font-medium text-[var(--linear-muted)] uppercase tracking-wider mb-2 block">Status</label>
          <Dropdown align="left" :full-width="true">
            <template #trigger>
              <button class="w-full flex items-center justify-between gap-2 px-3 py-2 bg-[var(--linear-surface)] border border-[var(--linear-border)] rounded hover:bg-[var(--linear-surface)] text-sm text-[var(--linear-text)] transition-colors">
                <div class="flex items-center gap-2">
                  <component 
                    :is="getStatusIcon(issue.workflowState?.stateType).icon" 
                    :class="['h-4 w-4', getStatusIcon(issue.workflowState?.stateType).color]" 
                  />
                  {{ issue.workflowState?.name || 'Backlog' }}
                </div>
                <ChevronDown class="h-4 w-4 text-[var(--linear-muted)]" />
              </button>
            </template>
            <div class="py-1 min-w-[200px]">
              <DropdownItem 
                v-for="state in workflowStates" 
                :key="state.id"
                @click="updateStatus(state)"
              >
                <div class="flex items-center gap-2">
                  <component 
                    :is="getStatusIcon(state.stateType).icon" 
                    :class="['h-4 w-4', getStatusIcon(state.stateType).color]" 
                  />
                  {{ state.name }}
                </div>
              </DropdownItem>
            </div>
          </Dropdown>
        </div>

        <!-- Priority -->
        <div>
          <label class="text-xs font-medium text-[var(--linear-muted)] uppercase tracking-wider mb-2 block">Priority</label>
          <Dropdown align="left" :full-width="true">
            <template #trigger>
              <button class="w-full flex items-center justify-between gap-2 px-3 py-2 bg-[var(--linear-surface)] border border-[var(--linear-border)] rounded hover:bg-[var(--linear-surface)] text-sm text-[var(--linear-text)] transition-colors">
                <div class="flex items-center gap-2">
                  <component 
                    :is="getPriority(issue.priority || 0).icon" 
                    :class="['h-4 w-4', getPriority(issue.priority || 0).color]" 
                  />
                  {{ getPriority(issue.priority || 0).label }}
                </div>
                <ChevronDown class="h-4 w-4 text-[var(--linear-muted)]" />
              </button>
            </template>
            <div class="py-1 min-w-[180px]">
              <DropdownItem 
                v-for="p in priorities" 
                :key="p.value"
                @click="updatePriority(p.value)"
              >
                <div class="flex items-center gap-2">
                  <component :is="p.icon" :class="['h-4 w-4', p.color]" />
                  {{ p.label }}
                </div>
              </DropdownItem>
            </div>
          </Dropdown>
        </div>

        <!-- Assignee -->
        <div>
          <label class="text-xs font-medium text-[var(--linear-muted)] uppercase tracking-wider mb-2 block">Assignee</label>
          <Dropdown align="left" :full-width="true">
            <template #trigger>
              <button class="w-full flex items-center justify-between gap-2 px-3 py-2 bg-[var(--linear-surface)] border border-[var(--linear-border)] rounded hover:bg-[var(--linear-surface)] text-sm transition-colors">
                <div class="flex items-center gap-2">
                  <template v-if="issue.assignee">
                    <Avatar :src="issue.assignee.avatarUrl" :name="issue.assignee.name" size="xs" />
                    <span class="text-[var(--linear-text)]">{{ issue.assignee.displayName || issue.assignee.name }}</span>
                  </template>
                  <template v-else>
                    <User class="h-4 w-4 text-[var(--linear-muted)]" />
                    <span class="text-[var(--linear-muted)]">Unassigned</span>
                  </template>
                </div>
                <ChevronDown class="h-4 w-4 text-[var(--linear-muted)]" />
              </button>
            </template>
            <div class="py-1 min-w-[200px] max-h-[300px] overflow-auto">
              <DropdownItem v-if="currentUser" @click="updateAssignee(currentUser.id)">
                <div class="flex items-center gap-2">
                  <Avatar :src="currentUser.avatarUrl" :name="currentUser.name" size="xs" />
                  <span>{{ currentUser.displayName || currentUser.name }} (me)</span>
                </div>
              </DropdownItem>
              <div v-if="currentUser" class="border-t border-[var(--linear-border)] my-1"></div>
              <DropdownItem @click="updateAssignee(null)">
                <div class="flex items-center gap-2">
                  <User class="h-4 w-4 text-[var(--linear-muted)]" />
                  <span class="text-[var(--linear-muted)]">Unassigned</span>
                </div>
              </DropdownItem>
              <div class="border-t border-[var(--linear-border)] my-1"></div>
              <DropdownItem 
                v-for="u in users" 
                :key="u.id"
                @click="updateAssignee(u.id)"
              >
                <div class="flex items-center gap-2">
                  <Avatar :src="u.avatarUrl" :name="u.name" size="xs" />
                  <span>{{ u.name }}</span>
                </div>
              </DropdownItem>
            </div>
          </Dropdown>
        </div>

        <!-- Labels -->
        <div>
          <label class="text-xs font-medium text-[var(--linear-muted)] uppercase tracking-wider mb-2 block">Labels</label>
          <Dropdown align="left" :full-width="true">
            <template #trigger>
              <button class="w-full flex items-center justify-between gap-2 px-3 py-2 bg-[var(--linear-surface)] border border-[var(--linear-border)] rounded hover:bg-[var(--linear-surface)] text-sm transition-colors">
                <div class="flex items-center gap-2 flex-wrap">
                  <template v-if="issue.labels && issue.labels.length > 0">
                    <span 
                      v-for="label in issue.labels" 
                      :key="label.id"
                      class="px-2 py-0.5 rounded text-xs"
                      :style="{ backgroundColor: label.color + '20', color: label.color }"
                    >
                      {{ label.name }}
                    </span>
                  </template>
                  <template v-else>
                    <Tag class="h-4 w-4 text-[var(--linear-muted)]" />
                    <span class="text-[var(--linear-muted)]">Add labels</span>
                  </template>
                </div>
                <ChevronDown class="h-4 w-4 text-[var(--linear-muted)] flex-shrink-0" />
              </button>
            </template>
            <div class="py-1 min-w-[200px] max-h-[300px] overflow-auto">
              <template v-if="labels.length > 0">
                <DropdownItem 
                  v-for="label in labels" 
                  :key="label.id"
                  @click="toggleLabel(label.id)"
                >
                  <div class="flex items-center justify-between w-full">
                    <div class="flex items-center gap-2">
                      <div 
                        class="w-3 h-3 rounded-full" 
                        :style="{ backgroundColor: label.color }"
                      ></div>
                      <span>{{ label.name }}</span>
                    </div>
                    <CheckCircle2 
                      v-if="issue.labels?.some(l => l.id === label.id)" 
                      class="h-4 w-4 text-[var(--linear-accent)]" 
                    />
                  </div>
                </DropdownItem>
              </template>
              <div v-else class="px-3 py-2 text-sm text-[var(--linear-muted)]">
                No labels available
              </div>
            </div>
          </Dropdown>
        </div>

        <!-- Project -->
        <div>
          <label class="text-xs font-medium text-[var(--linear-muted)] uppercase tracking-wider mb-2 block">Project</label>
          <Dropdown align="left-side" width="w-80">
            <template #trigger>
              <button class="w-full flex items-center justify-between gap-2 px-3 py-2 bg-[var(--linear-surface)] border border-[var(--linear-border)] rounded hover:bg-[var(--linear-surface)] text-sm transition-colors">
                <div class="flex items-center gap-2">
                  <template v-if="issue.project">
                    <EmojiIcon 
                      v-if="hasEmoji(issue.project.icon)"
                      :name="issue.project.icon" 
                      :fallback="issue.project.name?.charAt(0) || 'P'" 
                      size="sm"
                    />
                    <div 
                      v-else
                      class="w-5 h-5 rounded flex items-center justify-center text-[10px] font-bold text-[var(--linear-text)]"
                      :style="{ backgroundColor: issue.project.color || '#6366f1' }"
                    >
                      {{ issue.project.name?.charAt(0)?.toUpperCase() || 'P' }}
                    </div>
                    <span class="text-[var(--linear-text)]">{{ issue.project.name }}</span>
                  </template>
                  <template v-else>
                    <FolderKanban class="h-4 w-4 text-[var(--linear-muted)]" />
                    <span class="text-[var(--linear-muted)]">Add to project</span>
                  </template>
                </div>
                <ChevronDown class="h-4 w-4 text-[var(--linear-muted)]" />
              </button>
            </template>
            <div class="min-w-[280px]">
              <!-- Search input -->
              <div class="p-2 border-b border-[var(--linear-border)]">
                <div class="flex items-center gap-2 px-2 py-1.5 bg-[var(--linear-bg)] rounded border border-[var(--linear-border)]">
                  <input 
                    v-model="projectSearch"
                    type="text"
                    placeholder="Move to project..."
                    class="flex-1 bg-transparent text-sm text-[var(--linear-text)] placeholder:text-[var(--linear-muted)] outline-none"
                    @click.stop
                  />
                  <div class="flex items-center gap-1 text-[10px] text-[var(--linear-muted)]">
                    <span class="px-1 py-0.5 bg-[var(--linear-surface)] border border-[var(--linear-border)] rounded">⇧</span>
                    <span class="px-1 py-0.5 bg-[var(--linear-surface)] border border-[var(--linear-border)] rounded">P</span>
                  </div>
                </div>
              </div>
              
              <!-- Project list -->
              <div class="max-h-[350px] overflow-auto py-1">
                <!-- No project option -->
                <button 
                  @click="updateProject(null); projectSearch = ''"
                  class="w-full flex items-center justify-between px-3 py-2 hover:bg-[var(--linear-surface)] transition-colors"
                >
                  <div class="flex items-center gap-3">
                    <CircleDashed class="w-5 h-5 text-[var(--linear-muted)]" />
                    <span class="text-[13px] text-[var(--linear-text)]">No project</span>
                  </div>
                  <Check v-if="!issue.project" class="w-4 h-4 text-[var(--linear-text)]" />
                </button>
                
                <!-- Projects -->
                <button 
                  v-for="p in filteredProjects" 
                  :key="p.id"
                  @click="updateProject(p.id); projectSearch = ''"
                  class="w-full flex items-center justify-between px-3 py-2 hover:bg-[var(--linear-surface)] transition-colors"
                >
                  <div class="flex items-center gap-3">
                    <EmojiIcon 
                      v-if="hasEmoji(p.icon)"
                      :name="p.icon" 
                      :fallback="p.name?.charAt(0) || 'P'" 
                      size="sm"
                    />
                    <div 
                      v-else
                      class="w-5 h-5 rounded flex items-center justify-center text-[10px] font-bold text-[var(--linear-text)]"
                      :style="{ backgroundColor: p.color || '#6366f1' }"
                    >
                      {{ p.name?.charAt(0)?.toUpperCase() || 'P' }}
                    </div>
                    <span class="text-[13px] text-[var(--linear-text)]">{{ p.name }}</span>
                  </div>
                  <Check v-if="issue.project?.id === p.id" class="w-4 h-4 text-[var(--linear-text)]" />
                </button>
                
                <!-- Empty state -->
                <div v-if="filteredProjects.length === 0 && projectSearch" class="px-3 py-4 text-center text-sm text-[var(--linear-muted)]">
                  No projects found
                </div>
              </div>
            </div>
          </Dropdown>
        </div>

        <!-- Due date -->
        <div>
          <label class="text-xs font-medium text-[var(--linear-muted)] uppercase tracking-wider mb-2 block">Due date</label>
          <Dropdown align="left" :full-width="true">
            <template #trigger>
              <button class="w-full flex items-center justify-between gap-2 px-3 py-2 bg-[var(--linear-surface)] border border-[var(--linear-border)] rounded hover:bg-[var(--linear-surface)] text-sm transition-colors">
                <div class="flex items-center gap-2">
                  <Calendar class="h-4 w-4" :class="issue.dueDate ? 'text-[var(--linear-accent)]' : 'text-[var(--linear-muted)]'" />
                  <span :class="issue.dueDate ? 'text-[var(--linear-text)]' : 'text-[var(--linear-muted)]'">
                    {{ formatDate(issue.dueDate) || 'Set due date' }}
                  </span>
                </div>
                <ChevronDown class="h-4 w-4 text-[var(--linear-muted)]" />
              </button>
            </template>
            <div class="p-3 min-w-[200px]">
              <input 
                type="date" 
                :value="issue.dueDate?.split('T')[0]"
                @change="(e) => updateDueDate((e.target as HTMLInputElement).value)"
                class="w-full px-3 py-2 bg-[var(--linear-surface)] border border-[var(--linear-border)] rounded text-sm text-[var(--linear-text)] focus:outline-none focus:border-[var(--linear-accent)]"
              />
              <button 
                v-if="issue.dueDate"
                @click="updateDueDate(null)"
                class="w-full mt-2 px-3 py-1.5 text-sm text-red-400 hover:bg-[var(--linear-surface)] rounded transition-colors"
              >
                Remove due date
              </button>
            </div>
          </Dropdown>
        </div>
      </div>
    </div>
  </div>

  <Modal
    :open="showDeleteConfirm"
    title="Delete issue"
    description="This action cannot be undone."
    size="sm"
    :closable="!deleting"
    @close="closeDeleteConfirm"
  >
    <div class="space-y-3">
      <p class="text-sm text-[var(--linear-muted)]">
        Delete
        <span class="font-medium text-[var(--linear-text)]">{{ issue?.identifier }}</span>
        <span v-if="issue?.title"> - {{ issue.title }}</span>
        ?
      </p>
    </div>
    <template #footer>
      <Button variant="ghost" :disabled="deleting" @click="closeDeleteConfirm">
        Cancel
      </Button>
      <Button variant="danger" :loading="deleting" @click="deleteIssue">
        Delete issue
      </Button>
    </template>
  </Modal>
</template>
