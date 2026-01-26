<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useAppStore } from '@/stores/app'
import { useUiStore, type ViewMode } from '@/stores/ui'
import { cn } from '@/utils/cn'
import Avatar from '@/components/ui/Avatar.vue'
import Dropdown from '@/components/ui/Dropdown.vue'
import DropdownItem from '@/components/ui/DropdownItem.vue'
import Button from '@/components/ui/Button.vue'
import {
  Bell,
  Filter,
  LayoutGrid,
  List,
  ChevronRight
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const appStore = useAppStore()
const uiStore = useUiStore()

const user = computed(() => authStore.user)
const teams = computed(() => appStore.teams)

// Check if current page supports view toggle
const isTeamPage = computed(() => {
  return ['team-active', 'team-backlog', 'team-board'].includes(route.name as string)
})

// Track which list view was last used (for returning from board)
const lastListRoute = computed(() => {
  if (route.name === 'team-active' || route.name === 'team-backlog') {
    return route.name
  }
  return 'team-active' // default
})

function handleViewChange(mode: ViewMode) {
  uiStore.setViewMode(mode)
  
  if (!isTeamPage.value) return
  
  const teamKey = route.params.teamKey
  if (!teamKey) return
  
  if (mode === 'board') {
    router.push(`/team/${teamKey}/board`)
  } else {
    // Go to active issues list by default
    router.push(`/team/${teamKey}/active`)
  }
}

const breadcrumbs = computed(() => {
  const crumbs: { name: string; path?: string }[] = []
  const params = route.params

  // Add team if present
  if (params.teamKey) {
    const team = teams.value.find(t => t.key === params.teamKey)
    crumbs.push({
      name: team?.name || (params.teamKey as string),
      path: `/team/${params.teamKey}`
    })
  }

  // Add page name based on route
  if (route.name === 'home') {
    crumbs.push({ name: 'Home' })
  } else if (route.name === 'inbox') {
    crumbs.push({ name: 'Inbox' })
  } else if (route.name === 'my-issues') {
    crumbs.push({ name: 'My Issues' })
  } else if (route.name === 'team-active') {
    crumbs.push({ name: 'Active' })
  } else if (route.name === 'team-backlog') {
    crumbs.push({ name: 'Backlog' })
  } else if (route.name === 'team-board') {
    crumbs.push({ name: 'Board' })
  } else if (route.name === 'team-cycles') {
    crumbs.push({ name: 'Cycles' })
  } else if (route.name?.toString().startsWith('settings')) {
    crumbs.push({ name: 'Settings', path: '/settings' })
    
    if (route.name === 'members-settings') {
      crumbs.push({ name: 'Members' })
    } else if (route.name === 'teams-settings') {
      crumbs.push({ name: 'Teams' })
    } else if (route.name === 'labels-settings') {
      crumbs.push({ name: 'Labels' })
    }
  }

  return crumbs
})

const pageTitle = computed(() => {
  return breadcrumbs.value[breadcrumbs.value.length - 1]?.name || ''
})
</script>

<template>
  <header class="h-12 flex items-center justify-between px-4 border-b border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900">
    <!-- Breadcrumbs -->
    <div class="flex items-center gap-1 text-sm">
      <template v-for="(crumb, idx) in breadcrumbs" :key="idx">
        <ChevronRight v-if="idx > 0" class="h-3.5 w-3.5 text-gray-400" />
        <router-link
          v-if="crumb.path && idx < breadcrumbs.length - 1"
          :to="crumb.path"
          class="text-gray-500 hover:text-gray-900 dark:hover:text-gray-100"
        >
          {{ crumb.name }}
        </router-link>
        <span v-else class="font-medium text-gray-900 dark:text-gray-100">
          {{ crumb.name }}
        </span>
      </template>
    </div>

    <!-- Actions -->
    <div class="flex items-center gap-2">
      <!-- View toggle (only on team pages) -->
      <div v-if="isTeamPage" class="flex items-center gap-0.5 p-0.5 bg-gray-100 dark:bg-gray-800 rounded-md">
        <button
          @click="handleViewChange('list')"
          :class="cn(
            'p-1.5 rounded transition-colors',
            route.name !== 'team-board'
              ? 'bg-white dark:bg-gray-700 shadow-sm'
              : 'hover:bg-gray-200 dark:hover:bg-gray-700'
          )"
          title="List view"
        >
          <List :class="cn(
            'h-4 w-4',
            route.name !== 'team-board'
              ? 'text-gray-600 dark:text-gray-300'
              : 'text-gray-400'
          )" />
        </button>
        <button
          @click="handleViewChange('board')"
          :class="cn(
            'p-1.5 rounded transition-colors',
            route.name === 'team-board'
              ? 'bg-white dark:bg-gray-700 shadow-sm'
              : 'hover:bg-gray-200 dark:hover:bg-gray-700'
          )"
          title="Board view"
        >
          <LayoutGrid :class="cn(
            'h-4 w-4',
            route.name === 'team-board'
              ? 'text-gray-600 dark:text-gray-300'
              : 'text-gray-400'
          )" />
        </button>
      </div>

      <!-- Filter button (placeholder) -->
      <Button variant="ghost" size="sm">
        <Filter class="h-4 w-4" />
        Filter
      </Button>

      <!-- Notifications -->
      <button class="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-md relative">
        <Bell class="h-4 w-4 text-gray-600 dark:text-gray-400" />
        <span class="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full"></span>
      </button>

      <!-- User menu -->
      <Dropdown align="right" width="w-48">
        <template #trigger>
          <button class="flex items-center">
            <Avatar :name="user?.name || 'U'" :src="undefined" size="sm" />
          </button>
        </template>
        <template #default="{ close }">
          <div class="px-3 py-2 border-b border-gray-100 dark:border-gray-800">
            <p class="text-sm font-medium text-gray-900 dark:text-gray-100 truncate">{{ user?.name }}</p>
            <p class="text-xs text-gray-500 truncate">{{ user?.email }}</p>
          </div>
          <DropdownItem @click="close()">Profile</DropdownItem>
          <DropdownItem @click="close()">Preferences</DropdownItem>
          <div class="border-t border-gray-100 dark:border-gray-800 my-1" />
          <DropdownItem danger @click="authStore.logout(); close()">Log out</DropdownItem>
        </template>
      </Dropdown>
    </div>
  </header>
</template>
