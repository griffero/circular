<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAppStore } from '@/stores/app'
import { useUiStore } from '@/stores/ui'
import { cn } from '@/utils/cn'
import {
  Bell,
  Filter,
  Settings,
  LayoutGrid,
  Rows3
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const appStore = useAppStore()
const uiStore = useUiStore()

const teams = computed(() => appStore.teams)

const currentTeam = computed(() => {
  const teamKey = route.params.teamKey as string
  if (!teamKey) return null
  return teams.value.find(t => t.key === teamKey)
})

const isTeamPage = computed(() => {
  return ['team-active', 'team-backlog', 'team-board'].includes(route.name as string)
})

// Get page title for non-team pages
const pageTitle = computed(() => {
  switch (route.name) {
    case 'home': return 'Pulse'
    case 'inbox': return 'Inbox'
    case 'my-issues': return 'My Issues'
    case 'initiatives': return 'Initiatives'
    case 'projects': return 'Projects'
    case 'views': return 'Views'
    default:
      if (route.name?.toString().startsWith('settings')) {
        return 'Settings'
      }
      return ''
  }
})

const tabs = computed(() => {
  if (!currentTeam.value) return []
  const teamKey = currentTeam.value.key
  return [
    { name: 'All issues', to: `/team/${teamKey}`, active: route.name === 'team-issues' },
    { name: 'Active', to: `/team/${teamKey}/active`, active: route.name === 'team-active' },
    { name: 'Backlog', to: `/team/${teamKey}/backlog`, active: route.name === 'team-backlog' },
  ]
})
</script>

<template>
  <header class="h-11 flex items-center justify-between px-4 border-b border-[var(--linear-border-subtle)] bg-[var(--linear-bg)]">
    <!-- Left: Team icon + tabs OR page title -->
    <div class="flex items-center gap-3">
      <!-- Team header with icon -->
      <template v-if="isTeamPage && currentTeam">
        <div class="flex items-center gap-2">
          <div 
            class="w-5 h-5 rounded flex items-center justify-center"
            :style="{ backgroundColor: currentTeam.color || '#6366f1' }"
          >
            <span class="text-[10px] font-bold text-white">{{ currentTeam.key.substring(0, 2) }}</span>
          </div>
          <span class="text-[13px] font-medium text-white">{{ currentTeam.name }}</span>
        </div>
        
        <!-- Tabs -->
        <nav class="flex items-center ml-4">
          <router-link
            v-for="tab in tabs"
            :key="tab.name"
            :to="tab.to"
            :class="cn(
              'px-3 py-1.5 text-[13px] rounded transition-colors',
              tab.active
                ? 'bg-[var(--linear-elevated)] text-[var(--linear-text)]'
                : 'text-[var(--linear-muted)] hover:text-[var(--linear-text)] hover:bg-[var(--linear-elevated)]'
            )"
          >
            {{ tab.name }}
          </router-link>
        </nav>
        
        <!-- Settings icon for team -->
        <button class="p-1.5 rounded hover:bg-[var(--linear-elevated)] ml-1">
          <Settings class="w-4 h-4 text-[var(--linear-muted)]" />
        </button>
      </template>

      <!-- Non-team page title -->
      <template v-else>
        <span class="text-[13px] font-medium text-[var(--linear-text)]">{{ pageTitle }}</span>
      </template>
    </div>

    <!-- Right: Actions -->
    <div class="flex items-center gap-1">
      <!-- Filter -->
      <button 
        @click="uiStore.toggleFilters()"
        :class="cn(
          'flex items-center gap-1.5 px-2.5 py-1.5 rounded text-[13px] transition-colors',
          uiStore.filtersOpen
            ? 'bg-[var(--linear-elevated)] text-[var(--linear-text)]'
            : 'text-[var(--linear-muted)] hover:bg-[var(--linear-elevated)] hover:text-[var(--linear-text)]'
        )"
      >
        <Filter class="w-4 h-4" />
        <span>Filter</span>
      </button>

      <!-- Display toggle (only on team pages) -->
      <button 
        v-if="isTeamPage"
        class="flex items-center gap-1.5 px-2.5 py-1.5 rounded text-[13px] text-[var(--linear-muted)] hover:bg-[var(--linear-elevated)] hover:text-[var(--linear-text)] transition-colors"
      >
        <Rows3 class="w-4 h-4" />
        <span>Display</span>
      </button>

      <!-- Notifications -->
      <button class="p-1.5 rounded hover:bg-[var(--linear-elevated)] relative ml-1">
        <Bell class="w-4 h-4 text-[var(--linear-muted)]" />
      </button>

      <!-- Board view toggle -->
      <button 
        v-if="isTeamPage"
        class="p-1.5 rounded hover:bg-[var(--linear-elevated)] ml-1"
        @click="router.push(`/team/${currentTeam?.key}/board`)"
      >
        <LayoutGrid class="w-4 h-4 text-[var(--linear-muted)]" />
      </button>
    </div>
  </header>
</template>
