<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAppStore } from '@/stores/app'
import { useEmojiStore } from '@/stores/emoji'
import EmojiIcon from '@/components/ui/EmojiIcon.vue'

const route = useRoute()
const router = useRouter()
const appStore = useAppStore()
const emojiStore = useEmojiStore()

const teams = computed(() => appStore.teams)
const currentTeam = computed(() => {
  const teamKey = route.params.teamKey as string
  return teams.value.find(t => t.key === teamKey)
})

const teamProjects = computed(() => {
  const teamId = currentTeam.value?.id
  if (!teamId) return []
  return appStore.projects.filter(project => project.teams?.some(team => team.id === teamId))
})

function hasEmoji(icon?: string | null): boolean {
  return emojiStore.isRenderableEmoji(icon)
}
</script>

<template>
  <div class="h-full bg-[var(--linear-bg)] overflow-auto p-3">
    <div v-if="teamProjects.length === 0" class="h-full flex items-center justify-center text-[var(--linear-muted)] text-sm">
      No projects for this team
    </div>

    <div v-else class="space-y-2">
      <button
        v-for="project in teamProjects"
        :key="project.id"
        @click="router.push(`/project/${project.slug}`)"
        class="w-full text-left linear-panel px-3 py-2 hover:bg-[var(--linear-surface)] transition-colors"
      >
        <div class="flex items-center gap-2">
          <div class="w-6 h-6 rounded flex items-center justify-center" :style="hasEmoji(project.icon) ? {} : { backgroundColor: project.color || '#6b7280' }">
            <EmojiIcon :name="project.icon" :fallback="project.name.charAt(0)" size="sm" />
          </div>
          <span class="text-[13px] text-[var(--linear-text)]">{{ project.name }}</span>
        </div>
      </button>
    </div>
  </div>
</template>
