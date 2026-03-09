import { defineStore } from 'pinia'
import { ref, watch } from 'vue'

export type ViewMode = 'list' | 'board'

export const useUiStore = defineStore('ui', () => {
  const themeVersion = '2'
  const storedThemeVersion = localStorage.getItem('themeVersion')
  const storedDarkMode = localStorage.getItem('darkMode')

  // Dark mode
  const darkMode = ref(
    storedThemeVersion === themeVersion && storedDarkMode !== null
      ? storedDarkMode === 'true'
      : true,
  )

  // Sidebar
  const sidebarCollapsed = ref(localStorage.getItem('sidebarCollapsed') === 'true')

  // View mode (list or board)
  const viewMode = ref<ViewMode>((localStorage.getItem('viewMode') as ViewMode) || 'list')

  // Command palette
  const commandPaletteOpen = ref(false)

  // Keyboard shortcuts help
  const shortcutsHelpOpen = ref(false)

  // Create modals
  const createIssueModalOpen = ref(false)
  const createProjectModalOpen = ref(false)
  const createInitiativeModalOpen = ref(false)
  const createViewModalOpen = ref(false)
  const createTeamModalOpen = ref(false)
  const createCycleModalOpen = ref(false)

  // Issue detail sidebar
  const issueDetailOpen = ref(false)
  const selectedIssueId = ref<string | null>(null)

  // Filters panel
  const filtersOpen = ref(false)

  // Apply dark mode to document
  watch(darkMode, (value) => {
    localStorage.setItem('darkMode', String(value))
    localStorage.setItem('themeVersion', themeVersion)
    if (value) {
      document.documentElement.classList.add('dark')
    } else {
      document.documentElement.classList.remove('dark')
    }
  }, { immediate: true })

  // Persist sidebar collapsed state
  watch(sidebarCollapsed, (value) => {
    localStorage.setItem('sidebarCollapsed', String(value))
  })

  // Persist view mode
  watch(viewMode, (value) => {
    localStorage.setItem('viewMode', value)
  })

  function toggleDarkMode() {
    darkMode.value = !darkMode.value
  }

  function toggleSidebar() {
    sidebarCollapsed.value = !sidebarCollapsed.value
  }

  function openCommandPalette() {
    commandPaletteOpen.value = true
  }

  function closeCommandPalette() {
    commandPaletteOpen.value = false
  }

  function toggleCommandPalette() {
    commandPaletteOpen.value = !commandPaletteOpen.value
  }

  function openCreateIssueModal() {
    createIssueModalOpen.value = true
  }

  function closeCreateIssueModal() {
    createIssueModalOpen.value = false
  }

  function openCreateProjectModal() {
    createProjectModalOpen.value = true
  }

  function closeCreateProjectModal() {
    createProjectModalOpen.value = false
  }

  function openCreateInitiativeModal() {
    createInitiativeModalOpen.value = true
  }

  function closeCreateInitiativeModal() {
    createInitiativeModalOpen.value = false
  }

  function openCreateViewModal() {
    createViewModalOpen.value = true
  }

  function closeCreateViewModal() {
    createViewModalOpen.value = false
  }

  function openCreateTeamModal() {
    createTeamModalOpen.value = true
  }

  function closeCreateTeamModal() {
    createTeamModalOpen.value = false
  }

  function openCreateCycleModal() {
    createCycleModalOpen.value = true
  }

  function closeCreateCycleModal() {
    createCycleModalOpen.value = false
  }

  function openShortcutsHelp() {
    shortcutsHelpOpen.value = true
  }

  function closeShortcutsHelp() {
    shortcutsHelpOpen.value = false
  }

  function toggleShortcutsHelp() {
    shortcutsHelpOpen.value = !shortcutsHelpOpen.value
  }

  function openIssueDetail(issueId: string) {
    selectedIssueId.value = issueId
    issueDetailOpen.value = true
  }

  function closeIssueDetail() {
    issueDetailOpen.value = false
    selectedIssueId.value = null
  }

  function toggleIssueDetail() {
    issueDetailOpen.value = !issueDetailOpen.value
  }

  function setViewMode(mode: ViewMode) {
    viewMode.value = mode
  }

  function toggleViewMode() {
    viewMode.value = viewMode.value === 'list' ? 'board' : 'list'
  }

  function toggleFilters() {
    filtersOpen.value = !filtersOpen.value
  }

  return {
    // State
    darkMode,
    sidebarCollapsed,
    viewMode,
    commandPaletteOpen,
    shortcutsHelpOpen,
    createIssueModalOpen,
    createProjectModalOpen,
    createInitiativeModalOpen,
    createViewModalOpen,
    createTeamModalOpen,
    createCycleModalOpen,
    issueDetailOpen,
    selectedIssueId,
    filtersOpen,

    // Actions
    toggleDarkMode,
    toggleSidebar,
    setViewMode,
    toggleViewMode,
    openCommandPalette,
    closeCommandPalette,
    toggleCommandPalette,
    openShortcutsHelp,
    closeShortcutsHelp,
    toggleShortcutsHelp,
    openCreateIssueModal,
    closeCreateIssueModal,
    openCreateProjectModal,
    closeCreateProjectModal,
    openCreateInitiativeModal,
    closeCreateInitiativeModal,
    openCreateViewModal,
    closeCreateViewModal,
    openCreateTeamModal,
    closeCreateTeamModal,
    openCreateCycleModal,
    closeCreateCycleModal,
    openIssueDetail,
    closeIssueDetail,
    toggleIssueDetail,
    toggleFilters,
  }
})
