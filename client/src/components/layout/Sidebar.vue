<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useUiStore } from '@/stores/ui'
import { useAppStore } from '@/stores/app'
import { cn } from '@/utils/cn'
import Dropdown from '@/components/ui/Dropdown.vue'
import DropdownItem from '@/components/ui/DropdownItem.vue'
import EmojiIcon from '@/components/ui/EmojiIcon.vue'
import {
  Inbox,
  Search,
  Settings,
  Moon,
  Sun,
  LogOut,
  ChevronDown,
  ChevronRight,
  Zap,
  User,
  Lightbulb,
  FolderKanban,
  LayoutGrid,
  MoreHorizontal,
  PenLine
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const uiStore = useUiStore()
const appStore = useAppStore()

const user = computed(() => authStore.user)
const teams = computed(() => appStore.teams)
const projects = computed(() => appStore.projects)

// Expanded states for teams
const expandedTeams = ref<Set<string>>(new Set())

function toggleTeam(teamId: string) {
  if (expandedTeams.value.has(teamId)) {
    expandedTeams.value.delete(teamId)
  } else {
    expandedTeams.value.add(teamId)
  }
}

onMounted(async () => {
  if (appStore.teams.length === 0) {
    await appStore.fetchTeams()
  }
  if (appStore.projects.length === 0) {
    await appStore.fetchProjects()
  }
  // Expand the active team by default
  if (route.params.teamKey) {
    const team = teams.value.find(t => t.key === route.params.teamKey)
    if (team) {
      expandedTeams.value.add(team.id)
    }
  }
})

function handleLogout() {
  authStore.logout()
  router.push('/login')
}

function isTeamActive(teamKey: string) {
  return route.params.teamKey === teamKey
}

function isTeamSubPageActive(teamKey: string, page: string) {
  return route.params.teamKey === teamKey && route.name === `team-${page}`
}

// Workspace name from user email domain or default
const workspaceName = computed(() => {
  const email = user.value?.email || ''
  const domain = email.split('@')[1]
  if (domain) {
    return domain.split('.')[0].charAt(0).toUpperCase() + domain.split('.')[0].slice(1)
  }
  return 'Workspace'
})
</script>

<template>
  <aside class="w-[220px] h-full flex flex-col bg-[#0d0d0d] border-r border-[#1f1f1f]">
    <!-- Workspace header -->
    <div class="flex items-center justify-between px-3 py-2">
      <Dropdown align="left" width="w-56">
        <template #trigger>
          <button class="flex items-center gap-2 hover:bg-[#1a1a1a] rounded px-1.5 py-1 -mx-1.5 transition-colors">
            <div class="w-5 h-5 rounded bg-indigo-600 flex items-center justify-center">
              <span class="text-[10px] font-bold text-white">{{ workspaceName.charAt(0) }}</span>
            </div>
            <span class="text-[13px] font-medium text-white">{{ workspaceName }}</span>
            <ChevronDown class="w-3.5 h-3.5 text-gray-500" />
          </button>
        </template>
        <template #default="{ close }">
          <div class="px-3 py-2 border-b border-[#2a2a2a]">
            <p class="text-xs text-gray-500">Signed in as</p>
            <p class="text-sm font-medium text-white truncate">{{ user?.email }}</p>
          </div>
          <DropdownItem @click="close(); router.push('/settings')">
            <Settings class="w-4 h-4" />
            Settings
          </DropdownItem>
          <DropdownItem @click="uiStore.toggleDarkMode(); close()">
            <Moon v-if="!uiStore.darkMode" class="w-4 h-4" />
            <Sun v-else class="w-4 h-4" />
            {{ uiStore.darkMode ? 'Light mode' : 'Dark mode' }}
          </DropdownItem>
          <div class="border-t border-[#2a2a2a] my-1" />
          <DropdownItem danger @click="handleLogout(); close()">
            <LogOut class="w-4 h-4" />
            Log out
          </DropdownItem>
        </template>
      </Dropdown>
      
      <div class="flex items-center gap-0.5">
        <button 
          @click="uiStore.openCommandPalette()"
          class="p-1.5 rounded hover:bg-[#1a1a1a] transition-colors"
        >
          <Search class="w-4 h-4 text-gray-500" />
        </button>
        <button 
          @click="uiStore.openCreateIssueModal()"
          class="p-1.5 rounded hover:bg-[#1a1a1a] transition-colors"
        >
          <PenLine class="w-4 h-4 text-gray-500" />
        </button>
      </div>
    </div>

    <!-- Main navigation -->
    <nav class="flex-1 overflow-y-auto px-2 py-1">
      <!-- Primary nav items -->
      <div class="space-y-0.5">
        <router-link
          to="/"
          :class="cn(
            'flex items-center gap-2.5 px-2 py-1.5 rounded text-[13px] transition-colors',
            route.name === 'home'
              ? 'bg-[#1a1a1a] text-white'
              : 'text-gray-400 hover:bg-[#1a1a1a] hover:text-white'
          )"
        >
          <Zap class="w-4 h-4" />
          <span>Pulse</span>
        </router-link>

        <router-link
          to="/inbox"
          :class="cn(
            'flex items-center justify-between px-2 py-1.5 rounded text-[13px] transition-colors',
            route.name === 'inbox'
              ? 'bg-[#1a1a1a] text-white'
              : 'text-gray-400 hover:bg-[#1a1a1a] hover:text-white'
          )"
        >
          <div class="flex items-center gap-2.5">
            <Inbox class="w-4 h-4" />
            <span>Inbox</span>
          </div>
          <span class="text-xs text-gray-500">0</span>
        </router-link>

        <router-link
          to="/my-issues"
          :class="cn(
            'flex items-center gap-2.5 px-2 py-1.5 rounded text-[13px] transition-colors',
            route.name === 'my-issues'
              ? 'bg-[#1a1a1a] text-white'
              : 'text-gray-400 hover:bg-[#1a1a1a] hover:text-white'
          )"
        >
          <User class="w-4 h-4" />
          <span>My issues</span>
        </router-link>
      </div>

      <!-- Workspace section -->
      <div class="mt-6">
        <div class="px-2 mb-1">
          <span class="text-[11px] font-medium text-gray-500 uppercase tracking-wide">Workspace</span>
        </div>
        <div class="space-y-0.5">
          <router-link
            to="/initiatives"
            :class="cn(
              'flex items-center gap-2.5 px-2 py-1.5 rounded text-[13px] transition-colors',
              route.name === 'initiatives'
                ? 'bg-[#1a1a1a] text-white'
                : 'text-gray-400 hover:bg-[#1a1a1a] hover:text-white'
            )"
          >
            <Lightbulb class="w-4 h-4" />
            <span>Initiatives</span>
          </router-link>

          <router-link
            to="/projects"
            :class="cn(
              'flex items-center gap-2.5 px-2 py-1.5 rounded text-[13px] transition-colors',
              route.name === 'projects'
                ? 'bg-[#1a1a1a] text-white'
                : 'text-gray-400 hover:bg-[#1a1a1a] hover:text-white'
            )"
          >
            <FolderKanban class="w-4 h-4" />
            <span>Projects</span>
          </router-link>

          <router-link
            to="/views"
            :class="cn(
              'flex items-center gap-2.5 px-2 py-1.5 rounded text-[13px] transition-colors',
              route.name === 'views'
                ? 'bg-[#1a1a1a] text-white'
                : 'text-gray-400 hover:bg-[#1a1a1a] hover:text-white'
            )"
          >
            <LayoutGrid class="w-4 h-4" />
            <span>Views</span>
          </router-link>

          <router-link
            to="/settings"
            class="w-full flex items-center gap-2.5 px-2 py-1.5 rounded text-[13px] text-gray-400 hover:bg-[#1a1a1a] hover:text-white transition-colors"
          >
            <MoreHorizontal class="w-4 h-4" />
            <span>More</span>
          </router-link>
        </div>
      </div>

      <!-- Your teams section -->
      <div class="mt-6">
        <div class="flex items-center justify-between px-2 mb-1">
          <span class="text-[11px] font-medium text-gray-500 uppercase tracking-wide">Your teams</span>
          <button class="p-0.5 rounded hover:bg-[#1a1a1a]">
            <ChevronDown class="w-3 h-3 text-gray-500" />
          </button>
        </div>
        
        <div v-if="teams.length === 0" class="text-xs text-gray-500 px-2 py-3 text-center">
          No teams yet
        </div>
        
        <div v-else class="space-y-0.5">
          <div v-for="team in teams" :key="team.id">
            <!-- Team header -->
            <button
              @click="toggleTeam(team.id)"
              :class="cn(
                'w-full flex items-center gap-2 px-2 py-1.5 rounded text-[13px] transition-colors',
                isTeamActive(team.key)
                  ? 'bg-[#1a1a1a] text-white'
                  : 'text-gray-400 hover:bg-[#1a1a1a] hover:text-white'
              )"
            >
              <div 
                class="w-5 h-5 rounded flex items-center justify-center flex-shrink-0"
                :style="{ backgroundColor: team.color || '#6366f1' }"
              >
                <EmojiIcon 
                  :name="team.icon" 
                  :fallback="team.key.substring(0, 2)" 
                  size="xs"
                />
              </div>
              <span class="flex-1 text-left truncate">{{ team.name }}</span>
              <ChevronRight 
                :class="cn(
                  'w-3.5 h-3.5 text-gray-500 transition-transform',
                  expandedTeams.has(team.id) && 'rotate-90'
                )" 
              />
            </button>
            
            <!-- Team sub-items -->
            <div v-if="expandedTeams.has(team.id)" class="ml-4 mt-0.5 space-y-0.5">
              <router-link
                :to="`/team/${team.key}/active`"
                :class="cn(
                  'flex items-center gap-2.5 px-2 py-1 rounded text-[12px] transition-colors',
                  isTeamSubPageActive(team.key, 'active')
                    ? 'bg-[#1a1a1a] text-white'
                    : 'text-gray-500 hover:bg-[#1a1a1a] hover:text-gray-300'
                )"
              >
                <span class="w-1.5 h-1.5 rounded-full bg-yellow-500"></span>
                <span>Active</span>
              </router-link>
              
              <router-link
                :to="`/team/${team.key}/backlog`"
                :class="cn(
                  'flex items-center gap-2.5 px-2 py-1 rounded text-[12px] transition-colors',
                  isTeamSubPageActive(team.key, 'backlog')
                    ? 'bg-[#1a1a1a] text-white'
                    : 'text-gray-500 hover:bg-[#1a1a1a] hover:text-gray-300'
                )"
              >
                <span class="w-1.5 h-1.5 rounded-full bg-gray-500"></span>
                <span>Backlog</span>
              </router-link>
              
              <router-link
                :to="`/team/${team.key}/board`"
                :class="cn(
                  'flex items-center gap-2.5 px-2 py-1 rounded text-[12px] transition-colors',
                  isTeamSubPageActive(team.key, 'board')
                    ? 'bg-[#1a1a1a] text-white'
                    : 'text-gray-500 hover:bg-[#1a1a1a] hover:text-gray-300'
                )"
              >
                <span class="w-1.5 h-1.5 rounded-full bg-blue-500"></span>
                <span>Board</span>
              </router-link>
            </div>
          </div>
        </div>
      </div>
    </nav>
  </aside>
</template>
