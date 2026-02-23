<script setup lang="ts">
import { ref, computed } from 'vue'
import { useAppStore } from '@/stores/app'
import { useEmojiStore } from '@/stores/emoji'
import Avatar from '@/components/ui/Avatar.vue'
import EmojiIcon from '@/components/ui/EmojiIcon.vue'
import { Layers, Plus, SlidersHorizontal, FileText, Lock, Globe } from 'lucide-vue-next'

const appStore = useAppStore()
const emojiStore = useEmojiStore()

const activeTab = ref<'issues' | 'projects'>('issues')

function hasEmoji(icon?: string | null): boolean {
  return emojiStore.isRenderableEmoji(icon)
}

const issueViews = computed(() => {
  const fromProjects = appStore.projects.slice(0, 60).map((project, index) => ({
    id: `project-${project.id}`,
    name: project.name,
    description: project.description || `Issues related to ${project.name}`,
    ownerName: project.lead?.name || `owner-${(index % 9) + 1}`,
    icon: project.icon,
    color: project.color || '#6b7280',
    private: index % 4 === 0,
  }))

  if (fromProjects.length > 0) return fromProjects

  return appStore.teams.map((team, index) => ({
    id: `team-${team.id}`,
    name: team.name,
    description: `Issues for ${team.name}`,
    ownerName: team.name,
    icon: team.icon,
    color: team.color || '#6b7280',
    private: index % 3 === 0,
  }))
})

const projectViews = computed(() => {
  return appStore.teams.map((team, index) => ({
    id: `team-view-${team.id}`,
    name: `${team.name} projects`,
    description: `Projects owned by ${team.name}`,
    ownerName: team.name,
    icon: team.icon,
    color: team.color || '#6b7280',
    private: index % 2 === 0,
  }))
})

const visibleViews = computed(() => {
  return activeTab.value === 'issues' ? issueViews.value : projectViews.value
})
</script>

<template>
  <div data-testid="views-ready" class="h-full flex flex-col bg-[var(--linear-bg)]">
    <div class="h-11 px-4 border-b border-[var(--linear-border)] flex items-center justify-between">
      <div class="flex items-center gap-2">
        <Layers class="w-4 h-4 text-[var(--linear-muted)]" />
        <h1 class="text-[15px] font-medium text-[var(--linear-text)]">Views</h1>
      </div>
      <button class="flex items-center gap-1.5 text-[13px] text-[var(--linear-text)] hover:bg-[var(--linear-elevated)] px-2 py-1 rounded">
        <Plus class="w-3.5 h-3.5" />
        <span>View</span>
      </button>
    </div>

    <div class="h-11 px-4 border-b border-[var(--linear-border)] flex items-center justify-between">
      <div class="flex items-center gap-1">
        <button
          @click="activeTab = 'issues'"
          :class="[
            'px-2 py-1 text-[12px] rounded border transition-colors',
            activeTab === 'issues'
              ? 'bg-[var(--linear-elevated)] border-[var(--linear-border)] text-[var(--linear-text)]'
              : 'border-transparent text-[var(--linear-muted)] hover:bg-[var(--linear-elevated)]',
          ]"
        >
          Issues
        </button>
        <button
          @click="activeTab = 'projects'"
          :class="[
            'px-2 py-1 text-[12px] rounded border transition-colors',
            activeTab === 'projects'
              ? 'bg-[var(--linear-elevated)] border-[var(--linear-border)] text-[var(--linear-text)]'
              : 'border-transparent text-[var(--linear-muted)] hover:bg-[var(--linear-elevated)]',
          ]"
        >
          Projects
        </button>
      </div>

      <button class="hidden sm:flex items-center gap-1.5 text-[13px] text-[var(--linear-muted)] hover:text-[var(--linear-text)]">
        <SlidersHorizontal class="w-3.5 h-3.5" />
        Display
      </button>

      <button class="sm:hidden p-1.5 rounded hover:bg-[var(--linear-elevated)] text-[var(--linear-muted)]">
        <SlidersHorizontal class="w-4 h-4" />
      </button>
    </div>

    <div class="flex-1 overflow-auto">
      <div class="hidden sm:grid grid-cols-[1fr_120px] h-7 px-4 border-b border-[var(--linear-border-subtle)] text-[12px] text-[var(--linear-muted)] items-center">
        <span>Name</span>
        <span>Owner</span>
      </div>

      <div class="h-8 px-4 border-b border-[var(--linear-border-subtle)] bg-[var(--linear-elevated)] text-[13px] text-[var(--linear-text)] font-medium flex items-center justify-between">
        <div class="flex items-center gap-2">
          <img src="/fintoc-logo.png" alt="Fintoc" class="w-4 h-4 rounded" />
          <span>Fintoc - Workspace</span>
        </div>
        <button class="text-[var(--linear-muted)] hover:text-[var(--linear-text)]">
          <Plus class="w-3.5 h-3.5" />
        </button>
      </div>

      <div class="divide-y divide-[var(--linear-border-subtle)]">
        <button
          v-for="view in visibleViews"
          :key="view.id"
          class="w-full text-left px-4 py-2.5 hover:bg-[var(--linear-elevated)] transition-colors"
        >
          <div class="sm:grid sm:grid-cols-[1fr_120px] sm:items-center gap-3">
            <div class="flex items-start gap-2.5 min-w-0">
              <div
                class="w-4 h-4 mt-0.5 rounded flex items-center justify-center flex-shrink-0"
                :style="hasEmoji(view.icon) ? {} : { backgroundColor: view.color }"
              >
                <EmojiIcon :name="view.icon" fallback="" size="xs" />
              </div>
              <div class="min-w-0">
                <div class="flex items-center gap-1.5">
                  <span class="text-[13px] font-medium text-[var(--linear-text)] truncate">{{ view.name }}</span>
                  <Lock v-if="view.private" class="w-3 h-3 text-[var(--linear-muted)]" />
                  <Globe v-else class="w-3 h-3 text-[var(--linear-muted)]" />
                </div>
                <p class="text-[12px] text-[var(--linear-muted)] truncate">{{ view.description }}</p>
              </div>
            </div>

            <div class="hidden sm:flex items-center justify-start">
              <Avatar :name="view.ownerName" size="xs" />
            </div>
          </div>
        </button>
      </div>

      <div v-if="visibleViews.length === 0" class="py-10 flex flex-col items-center text-center px-4">
        <FileText class="w-8 h-8 text-[var(--linear-muted)] mb-2" />
        <p class="text-[13px] text-[var(--linear-text)]">No views yet</p>
        <p class="text-[12px] text-[var(--linear-muted)]">Create a view to save filters and display options.</p>
      </div>
    </div>
  </div>
</template>
