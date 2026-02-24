<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useEmojiStore } from '@/stores/emoji'
import { api } from '@/api/client'
import EmojiIcon from '@/components/ui/EmojiIcon.vue'
import Avatar from '@/components/ui/Avatar.vue'
import { Filter, SlidersHorizontal, Plus } from 'lucide-vue-next'
import { useCurrentTeam } from '@/composables/useCurrentTeam'
import type { Project } from '@/types'

const router = useRouter()
const emojiStore = useEmojiStore()
const { currentTeam } = useCurrentTeam()

const loading = ref(false)
const teamProjects = ref<Project[]>([])

watch(
  () => currentTeam.value?.key,
  async (teamKey) => {
    if (!teamKey) {
      teamProjects.value = []
      return
    }
    loading.value = true
    try {
      const data = await api.get<{ projects: Project[] }>(`/api/v1/projects?team_key=${encodeURIComponent(teamKey)}`)
      teamProjects.value = data.projects || []
    } finally {
      loading.value = false
    }
  },
  { immediate: true }
)

function hasEmoji(icon?: string | null): boolean {
  return emojiStore.isRenderableEmoji(icon)
}
</script>

<template>
  <div class="h-full bg-[var(--linear-bg)] overflow-auto flex flex-col">
    <div class="h-8 px-4 border-b border-[var(--linear-border-subtle)] flex items-center justify-between">
      <div class="flex items-center gap-2 min-w-0">
        <div class="w-4 h-4 rounded flex items-center justify-center flex-shrink-0" :style="hasEmoji(currentTeam?.icon) ? {} : { backgroundColor: currentTeam?.color || '#6b7280' }">
          <EmojiIcon :name="currentTeam?.icon" :fallback="currentTeam?.key?.substring(0, 1) || ''" size="xs" />
        </div>
        <span class="text-[13px] font-medium text-[var(--linear-text)] truncate">{{ currentTeam?.name }}</span>
      </div>
      <button class="h-6 px-2 rounded bg-indigo-600 hover:bg-indigo-700 text-white text-[12px] flex items-center gap-1">
        <Plus class="w-3.5 h-3.5" />
        New project
      </button>
    </div>

    <div class="h-8 px-4 border-b border-[var(--linear-border-subtle)] flex items-center justify-between">
      <div class="flex items-center gap-1.5">
        <span class="h-5 px-2 rounded border border-[var(--linear-border)] bg-[var(--linear-elevated)] text-[12px] text-[var(--linear-text)] inline-flex items-center">All projects</span>
      </div>
      <div class="flex items-center gap-3 text-[12px] text-[var(--linear-muted)]">
        <button class="inline-flex items-center gap-1 hover:text-[var(--linear-text)]">
          <Filter class="w-3.5 h-3.5" />
          Filter
        </button>
        <button class="inline-flex items-center gap-1 hover:text-[var(--linear-text)]">
          <SlidersHorizontal class="w-3.5 h-3.5" />
          Display
        </button>
      </div>
    </div>

    <div v-if="loading" class="h-full flex items-center justify-center">
      <div class="animate-spin rounded-full h-8 w-8 border-2 border-[var(--linear-accent)] border-t-transparent"></div>
    </div>

    <div v-else-if="teamProjects.length === 0" class="h-full flex items-center justify-center text-[var(--linear-muted)] text-sm">
      No projects for this team
    </div>

    <div v-else class="flex-1 overflow-auto">
      <div class="grid grid-cols-[1fr_110px_80px_80px_100px_80px] gap-2 h-8 px-6 border-b border-[var(--linear-border-subtle)] text-[12px] text-[var(--linear-muted)] items-center">
        <span>Name</span>
        <span>Health</span>
        <span>Priority</span>
        <span>Lead</span>
        <span>Target date</span>
        <span>Status</span>
      </div>
      <button
        v-for="project in teamProjects"
        :key="project.id"
        @click="router.push(`/project/${project.slug}`)"
        class="w-full grid grid-cols-[1fr_110px_80px_80px_100px_80px] gap-2 px-6 py-2 text-left border-b border-[var(--linear-border-subtle)] hover:bg-[var(--linear-elevated)] transition-colors items-center"
      >
        <div class="flex items-center gap-2 min-w-0">
          <div class="w-5 h-5 rounded flex items-center justify-center flex-shrink-0" :style="hasEmoji(project.icon) ? {} : { backgroundColor: project.color || '#6b7280' }">
            <EmojiIcon :name="project.icon" :fallback="project.name.charAt(0)" size="xs" />
          </div>
          <span class="text-[13px] text-[var(--linear-text)] truncate">{{ project.name }}</span>
        </div>
        <span class="text-[12px] text-[var(--linear-muted)]">
          {{ project.health === 'onTrack' ? 'On track' : project.health === 'atRisk' ? 'At risk' : project.health === 'offTrack' ? 'Off track' : 'No updates' }}
        </span>
        <span class="text-[12px] text-[var(--linear-muted)]">---</span>
        <div class="flex items-center">
          <Avatar v-if="project.lead" :name="project.lead.name || project.lead.email" size="xs" />
          <span v-else class="text-[12px] text-[var(--linear-muted)]">-</span>
        </div>
        <span class="text-[12px] text-[var(--linear-muted)]">
          {{ project.targetDate ? new Date(project.targetDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) : '-' }}
        </span>
        <span class="text-[12px] text-[var(--linear-muted)]">
          {{ Math.round(project.progress || 0) }}%
        </span>
      </button>
    </div>
  </div>
</template>
