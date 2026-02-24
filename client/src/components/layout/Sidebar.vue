<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useUiStore } from '@/stores/ui'
import { useAppStore } from '@/stores/app'
import { useEmojiStore } from '@/stores/emoji'
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
  Zap,
  User,
  Users,
  UsersRound,
  Lightbulb,
  FolderKanban,
  LayoutGrid,
  MoreHorizontal,
  PenLine,
  SlidersHorizontal,
  CircleDotDashed,
  Copy,
  Clock3,
  Package,
  Layers
} from 'lucide-vue-next'
import { api } from '@/api/client'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const uiStore = useUiStore()
const appStore = useAppStore()
const emojiStore = useEmojiStore()

const user = computed(() => authStore.user)
const teams = computed(() => appStore.teams)
const triageCounts = ref<Record<string, number>>({})
const loadingTriageCounts = ref<Set<string>>(new Set())

// Check if a team has a valid emoji (custom slack emoji or unicode)
function hasEmoji(icon?: string | null): boolean {
  return emojiStore.isRenderableEmoji(icon)
}

// Expanded states for teams
const expandedTeams = ref<Set<string>>(new Set())

// Teams section collapse state
const teamsCollapsed = ref(false)

function toggleTeam(teamId: string) {
  if (expandedTeams.value.has(teamId)) {
    expandedTeams.value.delete(teamId)
  } else {
    expandedTeams.value.add(teamId)
    fetchTriageCount(teamId)
  }
}

const sortedTeams = computed(() => {
  const currentKey = route.params.teamKey as string | undefined
  return [...teams.value].sort((a, b) => {
    if (a.key === currentKey) return -1
    if (b.key === currentKey) return 1
    return a.name.localeCompare(b.name)
  })
})

async function fetchTriageCount(teamId: string) {
  if (triageCounts.value[teamId] !== undefined || loadingTriageCounts.value.has(teamId)) return
  loadingTriageCounts.value.add(teamId)
  try {
    const data = await api.get<{ issues: Array<{ status?: string; workflowState?: { stateType?: string } }> }>(
      `/api/v1/issues?team_id=${teamId}&per_page=500`
    )
    const triageLike = data.issues.filter((issue) => {
      const type = issue.workflowState?.stateType
      return type === 'triage' || type === 'backlog' || issue.status === 'backlog'
    }).length
    triageCounts.value = { ...triageCounts.value, [teamId]: triageLike }
  } catch (err) {
    console.error('Failed to fetch triage count:', err)
    triageCounts.value = { ...triageCounts.value, [teamId]: 0 }
  } finally {
    loadingTriageCounts.value.delete(teamId)
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
      expandedTeams.value = new Set([team.id])
    }
  }
})

watch(
  () => route.params.teamKey,
  (teamKey) => {
    if (!teamKey) return
    const team = teams.value.find((t) => String(t.key || '').toLowerCase() === String(teamKey).toLowerCase())
    if (!team) return
    // Keep sidebar synchronized with current team route: expand active team only.
    expandedTeams.value = new Set([team.id])
    fetchTriageCount(team.id)
  },
  { immediate: true }
)

function handleLogout() {
  authStore.logout()
  router.push('/login')
}

function isTeamActive(teamKey: string) {
  return String(route.params.teamKey || '').toLowerCase() === String(teamKey || '').toLowerCase()
}

function isTeamSubPageActive(teamKey: string, page: string) {
  return isTeamActive(teamKey) && route.name === `team-${page}`
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
  <aside class="w-[220px] h-full flex flex-col bg-[var(--linear-sidebar)] border-r border-[var(--linear-border-subtle)]">
    <!-- Workspace header -->
    <div class="flex items-center justify-between px-3 py-2">
      <Dropdown align="left" width="w-56">
        <template #trigger>
          <button class="flex items-center gap-2 hover:bg-[var(--linear-elevated)] rounded px-1.5 py-1 -mx-1.5 transition-colors">
            <img 
              src="/fintoc-logo.png" 
              alt="Fintoc" 
              class="w-5 h-5 rounded"
            />
            <span class="text-[13px] font-medium text-[var(--linear-text)]">{{ workspaceName }}</span>
            <ChevronDown class="w-3.5 h-3.5 text-[var(--linear-muted)]" />
          </button>
        </template>
        <template #default="{ close }">
          <div class="px-3 py-2 border-b border-[var(--linear-border)]">
            <p class="text-xs text-[var(--linear-muted)]">Signed in as</p>
            <p class="text-sm font-medium text-[var(--linear-text)] truncate">{{ user?.email }}</p>
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
          <div class="border-t border-[var(--linear-border)] my-1" />
          <DropdownItem danger @click="handleLogout(); close()">
            <LogOut class="w-4 h-4" />
            Log out
          </DropdownItem>
        </template>
      </Dropdown>
      
      <div class="flex items-center gap-0.5">
        <button 
          @click="uiStore.openCommandPalette()"
          class="p-1.5 rounded hover:bg-[var(--linear-elevated)] transition-colors"
        >
          <Search class="w-4 h-4 text-[var(--linear-muted)]" />
        </button>
        <button 
          @click="uiStore.openCreateIssueModal()"
          class="p-1.5 rounded hover:bg-[var(--linear-elevated)] transition-colors"
        >
          <PenLine class="w-4 h-4 text-[var(--linear-muted)]" />
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
              ? 'bg-[var(--linear-elevated)] text-[var(--linear-text)]'
              : 'text-[var(--linear-muted)] hover:bg-[var(--linear-elevated)] hover:text-[var(--linear-text)]'
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
              ? 'bg-[var(--linear-elevated)] text-[var(--linear-text)]'
              : 'text-[var(--linear-muted)] hover:bg-[var(--linear-elevated)] hover:text-[var(--linear-text)]'
          )"
        >
          <div class="flex items-center gap-2.5">
            <Inbox class="w-4 h-4" />
            <span>Inbox</span>
          </div>
          <span class="text-xs text-[var(--linear-muted)]">0</span>
        </router-link>

        <router-link
          to="/my-issues"
          :class="cn(
            'flex items-center gap-2.5 px-2 py-1.5 rounded text-[13px] transition-colors',
            route.name === 'my-issues'
              ? 'bg-[var(--linear-elevated)] text-[var(--linear-text)]'
              : 'text-[var(--linear-muted)] hover:bg-[var(--linear-elevated)] hover:text-[var(--linear-text)]'
          )"
        >
          <User class="w-4 h-4" />
          <span>My issues</span>
        </router-link>
      </div>

      <!-- Workspace section -->
      <div class="mt-6">
        <div class="px-2 mb-1">
          <span class="text-[11px] font-medium text-[var(--linear-muted)]">Workspace</span>
        </div>
        <div class="space-y-0.5">
          <router-link
            to="/initiatives"
            :class="cn(
              'flex items-center gap-2.5 px-2 py-1.5 rounded text-[13px] transition-colors',
              route.name === 'initiatives'
                ? 'bg-[var(--linear-elevated)] text-[var(--linear-text)]'
                : 'text-[var(--linear-muted)] hover:bg-[var(--linear-elevated)] hover:text-[var(--linear-text)]'
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
                ? 'bg-[var(--linear-elevated)] text-[var(--linear-text)]'
                : 'text-[var(--linear-muted)] hover:bg-[var(--linear-elevated)] hover:text-[var(--linear-text)]'
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
                ? 'bg-[var(--linear-elevated)] text-[var(--linear-text)]'
                : 'text-[var(--linear-muted)] hover:bg-[var(--linear-elevated)] hover:text-[var(--linear-text)]'
            )"
          >
            <LayoutGrid class="w-4 h-4" />
            <span>Views</span>
          </router-link>

          <!-- More dropdown -->
          <Dropdown align="left" width="w-48">
            <template #trigger>
              <button
                :class="cn(
                  'w-full flex items-center gap-2.5 px-2 py-1.5 rounded text-[13px] transition-colors',
                  (route.path.startsWith('/settings/members') || route.path.startsWith('/settings/teams'))
                    ? 'bg-[var(--linear-elevated)] text-[var(--linear-text)]'
                    : 'text-[var(--linear-muted)] hover:bg-[var(--linear-elevated)] hover:text-[var(--linear-text)]'
                )"
              >
                <MoreHorizontal class="w-4 h-4" />
                <span>More</span>
              </button>
            </template>
            <template #default="{ close }">
              <DropdownItem @click="router.push('/settings/teams'); close()">
                <UsersRound class="w-4 h-4" />
                Teams
              </DropdownItem>
              <DropdownItem @click="router.push('/settings/members'); close()">
                <Users class="w-4 h-4" />
                Members
              </DropdownItem>
              <div class="border-t border-[var(--linear-border)] my-1" />
              <DropdownItem @click="close()">
                <SlidersHorizontal class="w-4 h-4" />
                Customize sidebar
              </DropdownItem>
            </template>
          </Dropdown>
        </div>
      </div>

      <!-- Your teams section -->
      <div class="mt-6">
        <div class="flex items-center justify-between px-2 mb-1">
          <span class="text-[11px] font-medium text-[var(--linear-muted)]">Your teams</span>
          <button 
            @click="teamsCollapsed = !teamsCollapsed"
            class="p-0.5 rounded hover:bg-[var(--linear-elevated)]"
          >
            <ChevronDown :class="cn('w-3 h-3 text-[var(--linear-muted)] transition-transform', teamsCollapsed && '-rotate-90')" />
          </button>
        </div>
        
        <div v-if="!teamsCollapsed && teams.length === 0" class="text-xs text-[var(--linear-muted)] px-2 py-3 text-center">
          No teams yet
        </div>
        
        <div v-else-if="!teamsCollapsed" class="space-y-1">
          <div
            v-for="team in sortedTeams"
            :key="team.id"
            :class="cn(
              'rounded-md transition-all',
              expandedTeams.has(team.id) && isTeamActive(team.key) && 'ring-1 ring-[var(--linear-accent)]/50 bg-[var(--linear-surface)]'
            )"
          >
            <!-- Team header -->
            <button
              @click="toggleTeam(team.id)"
              :class="cn(
                'w-full flex items-center gap-2 px-2 py-1.5 rounded text-[13px] transition-colors',
                isTeamActive(team.key)
                  ? 'text-[var(--linear-text)]'
                  : 'text-[var(--linear-muted)] hover:bg-[var(--linear-elevated)] hover:text-[var(--linear-text)]'
              )"
            >
              <div 
                class="w-5 h-5 rounded flex items-center justify-center flex-shrink-0"
                :style="hasEmoji(team.icon) ? {} : { backgroundColor: team.color || '#6366f1' }"
              >
                <EmojiIcon 
                  :name="team.icon" 
                  :fallback="team.key.substring(0, 2)" 
                  size="xs"
                />
              </div>
              <span class="flex-1 text-left truncate">{{ team.name }}</span>
              <ChevronDown 
                :class="cn(
                  'w-3.5 h-3.5 text-[var(--linear-muted)] transition-transform',
                  !expandedTeams.has(team.id) && '-rotate-90'
                )" 
              />
            </button>
            
            <!-- Team sub-items -->
            <div v-if="expandedTeams.has(team.id)" class="pb-1">
              <router-link
                :to="`/team/${team.key}/triage`"
                :class="cn(
                  'flex items-center gap-2.5 ml-5 px-2 py-1 rounded text-[13px] transition-colors',
                  isTeamSubPageActive(team.key, 'triage')
                    ? 'bg-[var(--linear-elevated)] text-[var(--linear-text)]'
                    : 'text-[var(--linear-muted)] hover:bg-[var(--linear-elevated)] hover:text-[var(--linear-text)]'
                )"
              >
                <CircleDotDashed class="w-4 h-4" />
                <span class="flex-1">Triage</span>
                <span class="text-[var(--linear-muted)] text-xs">
                  {{ triageCounts[team.id] ?? 0 }}
                </span>
              </router-link>

              <router-link
                :to="`/team/${team.key}/issues`"
                :class="cn(
                  'flex items-center gap-2.5 ml-5 px-2 py-1 rounded text-[13px] transition-colors',
                  isTeamSubPageActive(team.key, 'issues')
                    ? 'bg-[var(--linear-elevated)] text-[var(--linear-text)]'
                    : 'text-[var(--linear-muted)] hover:bg-[var(--linear-elevated)] hover:text-[var(--linear-text)]'
                )"
              >
                <Copy class="w-4 h-4" />
                <span>Issues</span>
              </router-link>

              <div class="ml-5">
                <router-link
                  :to="`/team/${team.key}/cycles/current`"
                  :class="cn(
                    'flex items-center gap-2.5 px-2 py-1 rounded text-[13px] transition-colors',
                    (isTeamSubPageActive(team.key, 'cycles-current') || isTeamSubPageActive(team.key, 'cycles-upcoming'))
                      ? 'bg-[var(--linear-elevated)] text-[var(--linear-text)]'
                      : 'text-[var(--linear-muted)] hover:bg-[var(--linear-elevated)] hover:text-[var(--linear-text)]'
                  )"
                >
                  <Clock3 class="w-4 h-4" />
                  <span>Cycles</span>
                </router-link>
                <router-link
                  :to="`/team/${team.key}/cycles/current`"
                  :class="cn(
                    'flex items-center gap-2 ml-6 pl-2 pr-2 py-1 border-l border-[var(--linear-border)] text-[13px] transition-colors',
                    isTeamSubPageActive(team.key, 'cycles-current')
                      ? 'text-[var(--linear-text)]'
                      : 'text-[var(--linear-muted)] hover:text-[var(--linear-text)]'
                  )"
                >
                  <span>Current</span>
                </router-link>
                <router-link
                  :to="`/team/${team.key}/cycles/upcoming`"
                  :class="cn(
                    'flex items-center gap-2 ml-6 pl-2 pr-2 py-1 border-l border-[var(--linear-border)] text-[13px] transition-colors',
                    isTeamSubPageActive(team.key, 'cycles-upcoming')
                      ? 'text-[var(--linear-text)]'
                      : 'text-[var(--linear-muted)] hover:text-[var(--linear-text)]'
                  )"
                >
                  <span>Upcoming</span>
                </router-link>
              </div>

              <router-link
                :to="`/team/${team.key}/projects`"
                :class="cn(
                  'flex items-center gap-2.5 ml-5 px-2 py-1 rounded text-[13px] transition-colors',
                  isTeamSubPageActive(team.key, 'projects')
                    ? 'bg-[var(--linear-elevated)] text-[var(--linear-text)]'
                    : 'text-[var(--linear-muted)] hover:bg-[var(--linear-elevated)] hover:text-[var(--linear-text)]'
                )"
              >
                <Package class="w-4 h-4" />
                <span>Projects</span>
              </router-link>

              <router-link
                :to="`/team/${team.key}/views`"
                :class="cn(
                  'flex items-center gap-2.5 ml-5 px-2 py-1 rounded text-[13px] transition-colors',
                  isTeamSubPageActive(team.key, 'views')
                    ? 'bg-[var(--linear-elevated)] text-[var(--linear-text)]'
                    : 'text-[var(--linear-muted)] hover:bg-[var(--linear-elevated)] hover:text-[var(--linear-text)]'
                )"
              >
                <Layers class="w-4 h-4" />
                <span>Views</span>
              </router-link>
            </div>
          </div>
        </div>
      </div>
    </nav>
  </aside>
</template>
