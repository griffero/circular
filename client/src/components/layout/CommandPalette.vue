<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useUiStore } from '@/stores/ui'
import { useAppStore } from '@/stores/app'
import { cn } from '@/utils/cn'
import Modal from '@/components/ui/Modal.vue'
import { Search, Home, Inbox, User, Settings, Plus, Moon, Sun, Users, FolderKanban, ArrowRight } from 'lucide-vue-next'
const router = useRouter()
const uiStore = useUiStore()
const appStore = useAppStore()

const searchQuery = ref('')
const selectedIndex = ref(0)
const inputRef = ref<HTMLInputElement | null>(null)

const isOpen = computed(() => uiStore.commandPaletteOpen)
const teams = computed(() => appStore.teams)
const projects = computed(() => appStore.projects)

interface Command {
  id: string
  name: string
  icon: typeof Home
  action: () => void
  section: string
  keywords?: string[]
}

const commands = computed<Command[]>(() => {
  const baseCommands: Command[] = [
    {
      id: 'new-issue',
      name: 'Create new issue',
      icon: Plus,
      action: () => {
        uiStore.closeCommandPalette()
        uiStore.openCreateIssueModal()
      },
      section: 'Actions',
      keywords: ['new', 'create', 'add', 'issue'],
    },
    {
      id: 'go-home',
      name: 'Go to Home',
      icon: Home,
      action: () => navigate('/'),
      section: 'Navigation',
      keywords: ['home', 'dashboard'],
    },
    {
      id: 'go-inbox',
      name: 'Go to Inbox',
      icon: Inbox,
      action: () => navigate('/inbox'),
      section: 'Navigation',
      keywords: ['inbox', 'notifications'],
    },
    {
      id: 'go-my-issues',
      name: 'Go to My Issues',
      icon: User,
      action: () => navigate('/my-issues'),
      section: 'Navigation',
      keywords: ['my', 'issues', 'assigned'],
    },
    {
      id: 'go-settings',
      name: 'Go to Settings',
      icon: Settings,
      action: () => navigate('/settings'),
      section: 'Navigation',
      keywords: ['settings', 'preferences', 'config'],
    },
    {
      id: 'toggle-dark-mode',
      name: uiStore.darkMode ? 'Switch to Light mode' : 'Switch to Dark mode',
      icon: uiStore.darkMode ? Sun : Moon,
      action: () => {
        uiStore.toggleDarkMode()
        uiStore.closeCommandPalette()
      },
      section: 'Settings',
      keywords: ['dark', 'light', 'theme', 'mode'],
    },
  ]

  // Add team commands
  const teamCommands: Command[] = teams.value.map(team => ({
    id: `team-${team.id}`,
    name: `Go to ${team.name}`,
    icon: Users,
    action: () => navigate(`/team/${team.key}`),
    section: 'Teams',
    keywords: ['team', team.name.toLowerCase(), team.key.toLowerCase()],
  }))

  // Add project commands
  const projectCommands: Command[] = projects.value.map(project => ({
    id: `project-${project.id}`,
    name: `Go to ${project.name}`,
    icon: FolderKanban,
    action: () => navigate(`/project/${project.slug}`),
    section: 'Projects',
    keywords: ['project', project.name.toLowerCase(), project.slug],
  }))

  return [...baseCommands, ...teamCommands, ...projectCommands]
})

const filteredCommands = computed(() => {
  const query = searchQuery.value.toLowerCase().trim()
  if (!query) return commands.value

  return commands.value.filter(cmd => {
    if (cmd.name.toLowerCase().includes(query)) return true
    if (cmd.keywords?.some(k => k.includes(query))) return true
    return false
  })
})

const groupedCommands = computed(() => {
  const groups: Record<string, Command[]> = {}
  for (const cmd of filteredCommands.value) {
    if (!groups[cmd.section]) {
      groups[cmd.section] = []
    }
    groups[cmd.section].push(cmd)
  }
  return groups
})

function navigate(path: string) {
  router.push(path)
  uiStore.closeCommandPalette()
}

function handleClose() {
  uiStore.closeCommandPalette()
  searchQuery.value = ''
  selectedIndex.value = 0
}

function handleKeyDown(e: KeyboardEvent) {
  if (e.key === 'ArrowDown') {
    e.preventDefault()
    selectedIndex.value = Math.min(selectedIndex.value + 1, filteredCommands.value.length - 1)
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    selectedIndex.value = Math.max(selectedIndex.value - 1, 0)
  } else if (e.key === 'Enter') {
    e.preventDefault()
    const cmd = filteredCommands.value[selectedIndex.value]
    if (cmd) {
      cmd.action()
    }
  }
}

// Global keyboard shortcut
function handleGlobalKeyDown(e: KeyboardEvent) {
  if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
    e.preventDefault()
    uiStore.toggleCommandPalette()
  } else if (e.key === 'Escape' && isOpen.value) {
    handleClose()
  }
}

watch(isOpen, (open) => {
  if (open) {
    searchQuery.value = ''
    selectedIndex.value = 0
    setTimeout(() => {
      inputRef.value?.focus()
    }, 50)
  }
})

watch(searchQuery, () => {
  selectedIndex.value = 0
})

onMounted(() => {
  document.addEventListener('keydown', handleGlobalKeyDown)
})

onUnmounted(() => {
  document.removeEventListener('keydown', handleGlobalKeyDown)
})
</script>

<template>
  <Modal :open="isOpen" @close="handleClose" size="lg" :showClose="false">
    <div class="py-2">
      <!-- Search input -->
      <div class="px-3 pb-2 border-b border-gray-200 dark:border-gray-700">
        <div class="relative">
          <Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
          <input
            ref="inputRef"
            v-model="searchQuery"
            type="text"
            placeholder="Type a command or search..."
            class="w-full pl-10 pr-4 py-2.5 bg-transparent text-gray-900 dark:text-gray-100 placeholder-gray-400 border-0 focus:ring-0 text-sm"
            @keydown="handleKeyDown"
          />
        </div>
      </div>

      <!-- Results -->
      <div class="max-h-80 overflow-y-auto py-2">
        <template v-if="filteredCommands.length === 0">
          <div class="px-4 py-8 text-center text-gray-500 text-sm">
            No results found for "{{ searchQuery }}"
          </div>
        </template>

        <template v-else>
          <div v-for="(cmds, section) in groupedCommands" :key="section" class="mb-2">
            <div class="px-3 py-1 text-xs font-medium text-gray-500 uppercase tracking-wider">
              {{ section }}
            </div>
            <button
              v-for="cmd in cmds"
              :key="cmd.id"
              @click="cmd.action"
              :class="cn(
                'w-full flex items-center gap-3 px-3 py-2 text-left text-sm',
                'hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors',
                filteredCommands.indexOf(cmd) === selectedIndex && 'bg-gray-100 dark:bg-gray-800'
              )"
            >
              <component :is="cmd.icon" class="h-4 w-4 text-gray-400 flex-shrink-0" />
              <span class="flex-1 text-gray-900 dark:text-gray-100">{{ cmd.name }}</span>
              <ArrowRight class="h-3 w-3 text-gray-400" />
            </button>
          </div>
        </template>
      </div>

      <!-- Footer hints -->
      <div class="px-3 py-2 border-t border-gray-200 dark:border-gray-700 flex items-center gap-4 text-xs text-gray-500">
        <span class="flex items-center gap-1">
          <kbd class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-2xs">↑↓</kbd>
          to navigate
        </span>
        <span class="flex items-center gap-1">
          <kbd class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-2xs">↵</kbd>
          to select
        </span>
        <span class="flex items-center gap-1">
          <kbd class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-2xs">esc</kbd>
          to close
        </span>
      </div>
    </div>
  </Modal>
</template>
