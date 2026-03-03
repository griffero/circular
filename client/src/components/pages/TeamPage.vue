<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAppStore } from '@/stores/app'
import { useUiStore } from '@/stores/ui'
import { useEmojiStore } from '@/stores/emoji'
import { useCurrentTeam } from '@/composables/useCurrentTeam'
import EmojiIcon from '@/components/ui/EmojiIcon.vue'
import Dropdown from '@/components/ui/Dropdown.vue'
import DropdownItem from '@/components/ui/DropdownItem.vue'
import Button from '@/components/ui/Button.vue'
import {
  LayoutList,
  Columns3,
  Clock,
  CircleDot,
  Plus,
  Filter,
  MoreHorizontal,
  Settings,
  Bookmark,
  Share2,
  Copy
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const appStore = useAppStore()
const uiStore = useUiStore()
const emojiStore = useEmojiStore()
const { currentTeam } = useCurrentTeam()

const teamsLoaded = computed(() => appStore.teams.length > 0 || !appStore.loading)

interface Tab {
  name: string
  to: string
  routeName: string
}

const tabs = computed<Tab[]>(() => {
  if (!currentTeam.value) return []
  const base = `/team/${currentTeam.value.key}`
  return [
    { name: 'All Issues', to: `${base}/issues`, routeName: 'team-issues' },
    { name: 'Active', to: `${base}/active`, routeName: 'team-active' },
    { name: 'Triage', to: `${base}/triage`, routeName: 'team-triage' },
    { name: 'Backlog', to: `${base}/backlog`, routeName: 'team-backlog' },
    { name: 'Board', to: `${base}/board`, routeName: 'team-board' },
    { name: 'Cycles', to: `${base}/cycles/current`, routeName: 'team-cycles-current' },
  ]
})

const issueShellRouteNames = new Set([
  'team-triage',
  'team-issues',
  'team-active',
  'team-backlog',
  'team-board',
])

const showIssueShellHeader = computed(() => issueShellRouteNames.has(String(route.name || '')))
const issueFilterQueryKeys = ['q', 'status', 'statuses', 'priority', 'assignee', 'sort', 'direction']

const issueShellQuery = computed(() => {
  const nextQuery: Record<string, unknown> = {}
  for (const key of issueFilterQueryKeys) {
    const value = route.query[key]
    if (value !== undefined && value !== null && value !== '') {
      nextQuery[key] = value
    }
  }
  return nextQuery
})

// Check if has emoji
function hasEmoji(icon?: string | null): boolean {
  return emojiStore.isRenderableEmoji(icon)
}

function isTabActive(routeName: string) {
  if (routeName === 'team-cycles-current') {
    return route.name === 'team-cycles-current' || route.name === 'team-cycles-upcoming'
  }
  return route.name === routeName
}

function tabTarget(tab: Tab) {
  if (issueShellRouteNames.has(tab.routeName)) {
    return { path: tab.to, query: issueShellQuery.value }
  }
  return { path: tab.to }
}
</script>

<template>
  <div v-if="currentTeam" class="flex flex-col h-full bg-[var(--linear-bg)]">
    <!-- Team header with tabs -->
    <div v-if="showIssueShellHeader" class="flex items-center justify-between px-4 py-2 border-b border-[var(--linear-border)]">
      <div class="flex items-center gap-3">
        <div class="flex items-center gap-2">
          <div 
            class="w-5 h-5 rounded flex items-center justify-center"
            :style="hasEmoji(currentTeam.icon) ? {} : { backgroundColor: currentTeam.color || '#6366f1' }"
          >
            <EmojiIcon 
              :name="currentTeam.icon" 
              :fallback="currentTeam.key.substring(0, 2)" 
              size="sm"
            />
          </div>
          <span class="text-sm font-medium text-[var(--linear-text)]">{{ currentTeam.name }}</span>
        </div>

        <nav class="flex items-center gap-1 ml-2">
          <router-link
            v-for="tab in tabs"
            :key="tab.name"
            :to="tabTarget(tab)"
            :class="[
              'px-3 py-1.5 text-sm rounded-md transition-colors',
              isTabActive(tab.routeName)
                ? 'bg-[var(--linear-elevated)] text-[var(--linear-text)]'
                : 'text-[var(--linear-muted)] hover:text-[var(--linear-text)] hover:bg-[var(--linear-surface)]'
            ]"
          >
            {{ tab.name }}
          </router-link>
        </nav>
        
        <button 
          @click="router.push('/settings/teams')"
          class="p-1.5 rounded hover:bg-[var(--linear-surface)] ml-1 text-[var(--linear-muted)] hover:text-[var(--linear-text)] transition-colors"
          title="Team settings"
        >
          <Settings class="w-4 h-4" />
        </button>
      </div>

      <div class="flex items-center gap-2">
        <Button
          size="sm"
          :variant="uiStore.filtersOpen ? 'secondary' : 'ghost'"
          @click="uiStore.toggleFilters()"
        >
          <Filter class="h-4 w-4" />
          Filter
        </Button>
        <Button
          size="sm"
          @click="uiStore.openCreateIssueModal()"
        >
          <Plus class="h-4 w-4" />
          New issue
        </Button>
        <Dropdown align="right">
          <template #trigger>
            <button class="p-1.5 hover:bg-[var(--linear-surface)] rounded text-[var(--linear-muted)] hover:text-[var(--linear-text)] transition-colors">
              <MoreHorizontal class="h-4 w-4" />
            </button>
          </template>
          <div class="py-1 min-w-[160px]">
            <DropdownItem @click="navigator.clipboard.writeText(window.location.href)">
              <Copy class="w-4 h-4" />
              Copy link
            </DropdownItem>
            <DropdownItem>
              <Bookmark class="w-4 h-4" />
              Add to favorites
            </DropdownItem>
            <DropdownItem @click="router.push('/settings/teams')">
              <Settings class="w-4 h-4" />
              Team settings
            </DropdownItem>
          </div>
        </Dropdown>
      </div>
    </div>

    <!-- Team content -->
    <div class="flex-1 overflow-auto">
      <router-view />
    </div>
  </div>

  <div v-else-if="teamsLoaded" class="flex items-center justify-center h-full bg-[var(--linear-bg)]">
    <div class="text-center">
      <p class="text-[var(--linear-muted)]">Team not found</p>
      <button 
        @click="router.push('/')"
        class="mt-4 px-4 py-2 text-sm text-[var(--linear-muted)] hover:text-[var(--linear-text)] hover:bg-[var(--linear-surface)] rounded transition-colors"
      >
        Go back home
      </button>
    </div>
  </div>

  <div v-else class="flex items-center justify-center h-full bg-[var(--linear-bg)]">
    <div class="animate-spin rounded-full h-8 w-8 border-2 border-[var(--linear-accent)] border-t-transparent"></div>
  </div>
</template>
