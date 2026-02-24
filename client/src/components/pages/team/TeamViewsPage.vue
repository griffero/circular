<script setup lang="ts">
import { ref, watch } from 'vue'
import { api } from '@/api/client'
import { useCurrentTeam } from '@/composables/useCurrentTeam'
import type { Project } from '@/types'
import Avatar from '@/components/ui/Avatar.vue'
import EmojiIcon from '@/components/ui/EmojiIcon.vue'
import { useEmojiStore } from '@/stores/emoji'
import { Plus, SlidersHorizontal } from 'lucide-vue-next'

const { currentTeam } = useCurrentTeam()
const emojiStore = useEmojiStore()
const loading = ref(false)
const teamViews = ref<Array<{ id: string; name: string; description: string; icon?: string | null; color?: string | null; ownerName: string }>>([])

function hasEmoji(icon?: string | null): boolean {
  return emojiStore.isRenderableEmoji(icon)
}

watch(
  () => currentTeam.value?.key,
  async (teamKey) => {
    if (!teamKey) {
      teamViews.value = []
      return
    }
    loading.value = true
    try {
      const data = await api.get<{ projects: Project[] }>(`/api/v1/projects?team_key=${encodeURIComponent(teamKey)}`)
      const projectMap = new Map<string, { id: string; name: string; description: string }>()
      for (const project of data.projects || []) {
        if (!project.id) continue
        if (!projectMap.has(project.id)) {
          projectMap.set(project.id, {
            id: project.id,
            name: project.name,
            description: project.description || `Issues related to ${project.name}`,
            icon: project.icon,
            color: project.color,
            ownerName: project.lead?.name || project.lead?.email || 'owner',
          })
        }
      }
      teamViews.value = Array.from(projectMap.values()).sort((a, b) => a.name.localeCompare(b.name))
    } finally {
      loading.value = false
    }
  },
  { immediate: true }
)
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
      <button class="h-6 px-2 rounded text-[12px] text-[var(--linear-text)] hover:bg-[var(--linear-elevated)] inline-flex items-center gap-1">
        <Plus class="w-3.5 h-3.5" />
        View
      </button>
    </div>

    <div class="h-8 px-4 border-b border-[var(--linear-border-subtle)] flex items-center justify-between">
      <div class="flex items-center gap-1.5">
        <span class="h-5 px-2 rounded border border-[var(--linear-border)] bg-[var(--linear-elevated)] text-[12px] text-[var(--linear-text)] inline-flex items-center">Issues</span>
        <span class="h-5 px-2 rounded text-[12px] text-[var(--linear-muted)] inline-flex items-center">Projects</span>
      </div>
      <button class="inline-flex items-center gap-1 text-[12px] text-[var(--linear-muted)] hover:text-[var(--linear-text)]">
        <SlidersHorizontal class="w-3.5 h-3.5" />
      </button>
    </div>

    <div v-if="loading" class="h-full flex items-center justify-center">
      <div class="animate-spin rounded-full h-8 w-8 border-2 border-[var(--linear-accent)] border-t-transparent"></div>
    </div>

    <div v-else-if="teamViews.length === 0" class="h-full flex items-center justify-center text-[var(--linear-muted)] text-sm">
      No views for this team
    </div>

    <div v-else class="flex-1 overflow-auto">
      <div class="grid grid-cols-[1fr_120px] h-7 px-4 border-b border-[var(--linear-border-subtle)] text-[12px] text-[var(--linear-muted)] items-center">
        <span>Name</span>
        <span>Owner</span>
      </div>
      <div class="divide-y divide-[var(--linear-border-subtle)]">
        <div v-for="view in teamViews" :key="view.id" class="px-4 py-2.5">
          <div class="grid grid-cols-[1fr_120px] items-center gap-3">
            <div class="flex items-start gap-2.5 min-w-0">
              <div class="w-4 h-4 mt-0.5 rounded flex items-center justify-center flex-shrink-0" :style="hasEmoji(view.icon) ? {} : { backgroundColor: view.color || '#6b7280' }">
                <EmojiIcon :name="view.icon" fallback="" size="xs" />
              </div>
              <div class="min-w-0">
                <p class="text-[13px] font-medium text-[var(--linear-text)] truncate">{{ view.name }}</p>
                <p class="text-[12px] text-[var(--linear-muted)] truncate">{{ view.description }}</p>
              </div>
            </div>
            <div class="flex items-center">
              <Avatar :name="view.ownerName" size="xs" />
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
