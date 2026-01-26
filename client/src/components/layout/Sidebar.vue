<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useUiStore } from '@/stores/ui'
import { useAppStore } from '@/stores/app'
import { cn } from '@/utils/cn'
import Avatar from '@/components/ui/Avatar.vue'
import Dropdown from '@/components/ui/Dropdown.vue'
import DropdownItem from '@/components/ui/DropdownItem.vue'
import Tooltip from '@/components/ui/Tooltip.vue'
import {
  Home,
  Inbox,
  User,
  Settings,
  Plus,
  ChevronDown,
  Search,
  Moon,
  Sun,
  LogOut,
  ChevronsLeft,
  ChevronsRight,
  FolderKanban
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const uiStore = useUiStore()
const appStore = useAppStore()

const collapsed = computed(() => uiStore.sidebarCollapsed)
const user = computed(() => authStore.user)
const teams = computed(() => appStore.teams)
const projects = computed(() => appStore.projects)

const sidebarClass = computed(() =>
  cn(
    'h-full flex flex-col',
    'bg-gray-50 dark:bg-gray-900',
    'border-r border-gray-200 dark:border-gray-800',
    'transition-all duration-200',
    collapsed.value ? 'w-14' : 'w-60'
  )
)

interface NavItem {
  name: string
  icon: typeof Home
  to: string
  active?: boolean
}

const mainNav = computed<NavItem[]>(() => {
  return [
    { name: 'Home', icon: Home, to: '/', active: route.name === 'home' },
    { name: 'Inbox', icon: Inbox, to: '/inbox', active: route.name === 'inbox' },
    { name: 'My Issues', icon: User, to: '/my-issues', active: route.name === 'my-issues' },
  ]
})

onMounted(async () => {
  // Fetch data if not already loaded
  if (appStore.teams.length === 0) {
    await appStore.fetchTeams()
  }
  if (appStore.projects.length === 0) {
    await appStore.fetchProjects()
  }
})

function handleLogout() {
  authStore.logout()
  router.push('/login')
}

function handleCreateIssue() {
  uiStore.openCreateIssueModal()
}

function isTeamActive(teamKey: string) {
  return route.params.teamKey === teamKey
}

function isProjectActive(projectSlug: string) {
  return route.params.projectSlug === projectSlug
}
</script>

<template>
  <aside :class="sidebarClass">
    <!-- User menu -->
    <div class="border-b border-gray-200 dark:border-gray-800">
      <div class="p-2">
      <Dropdown align="left" :width="collapsed ? 'w-48' : 'w-56'">
        <template #trigger>
          <button
            :class="cn(
              'w-full flex items-center gap-2 px-2 py-1.5 rounded-md',
              'hover:bg-gray-200 dark:hover:bg-gray-800',
              'transition-colors'
            )"
          >
            <div class="h-6 w-6 rounded bg-gradient-to-br from-primary-500 to-primary-700 flex items-center justify-center text-white text-xs font-bold flex-shrink-0">
              {{ user?.name?.charAt(0) || 'U' }}
            </div>
            <template v-if="!collapsed">
              <span class="flex-1 text-left text-sm font-medium text-gray-900 dark:text-gray-100 truncate">
                {{ user?.name || 'User' }}
              </span>
              <ChevronDown class="h-4 w-4 text-gray-400 flex-shrink-0" />
            </template>
          </button>
        </template>
        <template #default="{ close }">
          <div class="px-3 py-2 border-b border-gray-100 dark:border-gray-800">
            <p class="text-xs text-gray-500">Signed in as</p>
            <p class="text-sm font-medium text-gray-900 dark:text-gray-100 truncate">{{ user?.email }}</p>
            <p class="text-xs text-gray-500 capitalize mt-1">{{ user?.role }}</p>
          </div>
          <DropdownItem @click="close(); router.push('/settings')">
            <Settings class="h-4 w-4" />
            Settings
          </DropdownItem>
          <DropdownItem @click="uiStore.toggleDarkMode(); close()">
            <Moon v-if="!uiStore.darkMode" class="h-4 w-4" />
            <Sun v-else class="h-4 w-4" />
            {{ uiStore.darkMode ? 'Light mode' : 'Dark mode' }}
          </DropdownItem>
          <div class="border-t border-gray-100 dark:border-gray-800 my-1" />
          <DropdownItem danger @click="handleLogout(); close()">
            <LogOut class="h-4 w-4" />
            Log out
          </DropdownItem>
        </template>
      </Dropdown>
      </div>
    </div>

    <!-- Search & Create -->
    <div class="p-2 space-y-1">
      <Tooltip :content="collapsed ? 'Search (⌘K)' : ''" :position="collapsed ? 'right' : 'top'">
        <button
          @click="uiStore.openCommandPalette()"
          :class="cn(
            'w-full flex items-center gap-2 px-2 py-1.5 rounded-md',
            'text-gray-500 dark:text-gray-400',
            'hover:bg-gray-200 dark:hover:bg-gray-800',
            'transition-colors'
          )"
        >
          <Search class="h-4 w-4 flex-shrink-0" />
          <template v-if="!collapsed">
            <span class="flex-1 text-left text-sm">Search...</span>
            <span class="text-xs text-gray-400">⌘K</span>
          </template>
        </button>
      </Tooltip>

      <Tooltip :content="collapsed ? 'New Issue (C)' : ''" :position="collapsed ? 'right' : 'top'">
        <button
          @click="handleCreateIssue"
          :class="cn(
            'w-full flex items-center gap-2 px-2 py-1.5 rounded-md',
            'bg-primary-600 hover:bg-primary-700 text-white',
            'transition-colors'
          )"
        >
          <Plus class="h-4 w-4 flex-shrink-0" />
          <span v-if="!collapsed" class="text-sm font-medium">New Issue</span>
        </button>
      </Tooltip>
    </div>

    <!-- Main navigation -->
    <nav class="flex-1 p-2 space-y-1 overflow-y-auto scrollbar-hide">
      <Tooltip
        v-for="item in mainNav"
        :key="item.name"
        :content="collapsed ? item.name : ''"
        :position="collapsed ? 'right' : 'top'"
      >
        <router-link
          :to="item.to"
          :class="cn(
            'flex items-center gap-2 px-2 py-1.5 rounded-md',
            'text-sm transition-colors',
            item.active
              ? 'bg-gray-200 dark:bg-gray-800 text-gray-900 dark:text-gray-100'
              : 'text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-800 hover:text-gray-900 dark:hover:text-gray-100'
          )"
        >
          <component :is="item.icon" class="h-4 w-4 flex-shrink-0" />
          <span v-if="!collapsed">{{ item.name }}</span>
        </router-link>
      </Tooltip>

      <!-- Teams section -->
      <div v-if="!collapsed" class="mt-6">
        <div class="flex items-center justify-between px-2 mb-1">
          <span class="text-xs font-medium text-gray-500 uppercase tracking-wider">Your Teams</span>
          <button 
            class="p-0.5 rounded hover:bg-gray-200 dark:hover:bg-gray-800"
            @click="router.push('/settings/teams')"
          >
            <Plus class="h-3.5 w-3.5 text-gray-400" />
          </button>
        </div>
        <div v-if="teams.length === 0" class="text-xs text-gray-400 px-2 py-4 text-center">
          No teams yet
        </div>
        <div v-else class="space-y-0.5">
          <router-link
            v-for="team in teams"
            :key="team.id"
            :to="`/team/${team.key}`"
            :class="cn(
              'flex items-center gap-2 px-2 py-1.5 rounded-md text-sm',
              'transition-colors',
              isTeamActive(team.key)
                ? 'bg-gray-200 dark:bg-gray-800 text-gray-900 dark:text-gray-100'
                : 'text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800'
            )"
          >
            <div 
              class="w-4 h-4 rounded flex items-center justify-center text-2xs font-bold text-white flex-shrink-0"
              :style="{ backgroundColor: team.color || '#6b7280' }"
            >
              {{ team.key.charAt(0) }}
            </div>
            <span class="truncate">{{ team.name }}</span>
          </router-link>
        </div>
      </div>

      <!-- Projects section -->
      <div v-if="!collapsed" class="mt-4">
        <div class="flex items-center justify-between px-2 mb-1">
          <span class="text-xs font-medium text-gray-500 uppercase tracking-wider">Projects</span>
          <button 
            class="p-0.5 rounded hover:bg-gray-200 dark:hover:bg-gray-800"
            @click="router.push('/settings')"
          >
            <Plus class="h-3.5 w-3.5 text-gray-400" />
          </button>
        </div>
        <div v-if="projects.length === 0" class="text-xs text-gray-400 px-2 py-4 text-center">
          No projects yet
        </div>
        <div v-else class="space-y-0.5">
          <router-link
            v-for="project in projects"
            :key="project.id"
            :to="`/project/${project.slug}`"
            :class="cn(
              'flex items-center gap-2 px-2 py-1.5 rounded-md text-sm',
              'transition-colors',
              isProjectActive(project.slug)
                ? 'bg-gray-200 dark:bg-gray-800 text-gray-900 dark:text-gray-100'
                : 'text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800'
            )"
          >
            <div 
              class="w-4 h-4 rounded flex items-center justify-center flex-shrink-0"
              :style="{ backgroundColor: project.color || '#6b7280' }"
            >
              <FolderKanban class="h-2.5 w-2.5 text-white" />
            </div>
            <span class="truncate">{{ project.name }}</span>
          </router-link>
        </div>
      </div>
    </nav>

    <!-- Collapse toggle -->
    <div class="border-t border-gray-200 dark:border-gray-800">
      <div class="p-2">
        <Tooltip :content="collapsed ? 'Expand' : 'Collapse'" :position="collapsed ? 'right' : 'top'">
          <button
            @click="uiStore.toggleSidebar()"
            :class="cn(
              'w-full flex items-center gap-2 px-2 py-1.5 rounded-md',
              'text-gray-500 dark:text-gray-400',
              'hover:bg-gray-200 dark:hover:bg-gray-800',
              'transition-colors'
            )"
          >
            <ChevronsLeft v-if="!collapsed" class="h-4 w-4" />
            <ChevronsRight v-else class="h-4 w-4" />
            <span v-if="!collapsed" class="text-sm">Collapse</span>
          </button>
        </Tooltip>
      </div>
    </div>
  </aside>
</template>
