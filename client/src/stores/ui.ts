import { defineStore } from 'pinia'
import { ref, watch } from 'vue'

export type ViewMode = 'list' | 'board'

export const useUiStore = defineStore('ui', () => {
  // Dark mode
  const darkMode = ref(localStorage.getItem('darkMode') === 'true' || window.matchMedia('(prefers-color-scheme: dark)').matches)

  // Sidebar
  const sidebarCollapsed = ref(localStorage.getItem('sidebarCollapsed') === 'true')

  // View mode (list or board)
  const viewMode = ref<ViewMode>((localStorage.getItem('viewMode') as ViewMode) || 'list')

  // Command palette
  const commandPaletteOpen = ref(false)

  // Create issue modal
  const createIssueModalOpen = ref(false)

  // Apply dark mode to document
  watch(darkMode, (value) => {
    localStorage.setItem('darkMode', String(value))
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

  function setViewMode(mode: ViewMode) {
    viewMode.value = mode
  }

  return {
    // State
    darkMode,
    sidebarCollapsed,
    viewMode,
    commandPaletteOpen,
    createIssueModalOpen,

    // Actions
    toggleDarkMode,
    toggleSidebar,
    setViewMode,
    openCommandPalette,
    closeCommandPalette,
    toggleCommandPalette,
    openCreateIssueModal,
    closeCreateIssueModal,
  }
})
