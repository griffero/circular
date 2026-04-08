<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAppStore } from '@/stores/app'
import { useEmojiStore } from '@/stores/emoji'
import { useUiStore } from '@/stores/ui'
import EmojiIcon from '@/components/ui/EmojiIcon.vue'
import IssueList from '@/components/issues/IssueList.vue'
import Button from '@/components/ui/Button.vue'
import OriginBadge from '@/components/ui/OriginBadge.vue'
import type { Issue } from '@/types'
import {
  Plus,
  Calendar,
  Target,
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const appStore = useAppStore()
const emojiStore = useEmojiStore()
const uiStore = useUiStore()

const projects = computed(() => appStore.projects)
const currentProject = computed(() => {
  const projectSlug = route.params.projectSlug as string
  return projects.value.find((project) => project.slug === projectSlug)
})

const baseFilters = computed(() => ({
  sort: 'updated_at' as const,
  direction: 'desc' as const,
}))

function hasEmoji(icon?: string | null): boolean {
  return emojiStore.isRenderableEmoji(icon)
}

function handleIssueClick(issue: Issue) {
  router.push(`/issue/${issue.id}`)
}

function handleCreateIssue() {
  uiStore.openCreateIssueModal()
}

function formatDate(dateString?: string) {
  if (!dateString) return null
  return new Date(dateString).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  })
}

function projectStateLabel(state?: string) {
  switch (state) {
    case 'started':
      return 'Active'
    case 'planned':
      return 'Planned'
    case 'paused':
      return 'Paused'
    case 'completed':
      return 'Completed'
    case 'canceled':
      return 'Canceled'
    default:
      return 'Backlog'
  }
}

function projectStateClass(state?: string) {
  switch (state) {
    case 'started':
      return 'bg-green-500/20 text-green-400'
    case 'planned':
      return 'bg-blue-500/20 text-blue-400'
    case 'paused':
      return 'bg-yellow-500/20 text-yellow-400'
    case 'completed':
      return 'bg-emerald-500/20 text-emerald-400'
    case 'canceled':
      return 'bg-red-500/20 text-red-400'
    default:
      return 'bg-[var(--linear-elevated)] text-[var(--linear-muted)]'
  }
}
</script>

<template>
  <div v-if="currentProject" class="h-full flex flex-col bg-[var(--linear-bg)]">
    <div class="px-4 py-3 border-b border-[var(--linear-border)]">
      <div class="flex items-start justify-between gap-4">
        <div class="flex items-start gap-3 min-w-0">
          <div
            class="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0"
            :style="hasEmoji(currentProject.icon) ? {} : { backgroundColor: currentProject.color || '#6366f1' }"
          >
            <EmojiIcon
              :name="currentProject.icon"
              :fallback="currentProject.name.charAt(0)"
              size="lg"
            />
          </div>
          <div class="min-w-0">
            <h1 class="text-lg font-semibold text-[var(--linear-text)] truncate flex items-center gap-2">
              <OriginBadge :linear-id="currentProject.linearId" />
              {{ currentProject.name }}
            </h1>
            <p v-if="currentProject.description" class="text-sm text-[var(--linear-muted)] mt-0.5">
              {{ currentProject.description }}
            </p>
            <div class="mt-2 flex items-center flex-wrap gap-4 text-xs text-[var(--linear-muted)]">
              <span class="px-2 py-0.5 rounded" :class="projectStateClass(currentProject.state)">
                {{ projectStateLabel(currentProject.state) }}
              </span>
              <span v-if="currentProject.startDate" class="inline-flex items-center gap-1.5">
                <Calendar class="h-3.5 w-3.5" />
                Started {{ formatDate(currentProject.startDate) }}
              </span>
              <span v-if="currentProject.targetDate" class="inline-flex items-center gap-1.5">
                <Target class="h-3.5 w-3.5" />
                Target {{ formatDate(currentProject.targetDate) }}
              </span>
            </div>
          </div>
        </div>

        <Button size="sm" @click="handleCreateIssue">
          <Plus class="h-4 w-4" />
          New issue
        </Button>
      </div>
    </div>

    <IssueList
      :key="currentProject.id"
      :project-id="currentProject.id"
      :base-filters="baseFilters"
      :show-filters="true"
      empty-title="No project issues"
      empty-description="Issues linked to this project will appear here."
      @issue-click="handleIssueClick"
      @create-issue="handleCreateIssue"
    />
  </div>

  <div v-else class="h-full flex items-center justify-center bg-[var(--linear-bg)]">
    <p class="text-sm text-[var(--linear-muted)]">Project not found</p>
  </div>
</template>
