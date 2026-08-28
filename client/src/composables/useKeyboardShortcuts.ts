import { onMounted, onUnmounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useUiStore } from '@/stores/ui'

export function useKeyboardShortcuts() {
  const router = useRouter()
  const uiStore = useUiStore()
  
  // Track pending "G" navigation
  const pendingG = ref(false)
  let pendingGTimeout: ReturnType<typeof setTimeout> | null = null

  function clearPendingG() {
    pendingG.value = false
    if (pendingGTimeout) {
      clearTimeout(pendingGTimeout)
      pendingGTimeout = null
    }
  }

  function handleKeyDown(event: KeyboardEvent) {
    // Don't trigger shortcuts when typing in inputs
    const target = event.target as HTMLElement
    const isInput = target.tagName === 'INPUT' || 
                    target.tagName === 'TEXTAREA' || 
                    target.isContentEditable

    // Allow Escape and Cmd+K even in inputs
    const allowedInInput = event.key === 'Escape' || 
                          (event.key === 'k' && (event.metaKey || event.ctrlKey))

    if (isInput && !allowedInInput) {
      return
    }

    // Handle Escape - close modals/go back
    if (event.key === 'Escape') {
      event.preventDefault()
      
      // Close modals in priority order
      if (uiStore.shortcutsHelpOpen) {
        uiStore.closeShortcutsHelp()
      } else if (uiStore.commandPaletteOpen) {
        uiStore.closeCommandPalette()
      } else if (uiStore.createIssueModalOpen) {
        uiStore.closeCreateIssueModal()
      } else if (uiStore.createProjectModalOpen) {
        uiStore.closeCreateProjectModal()
      } else if (uiStore.createInitiativeModalOpen) {
        uiStore.closeCreateInitiativeModal()
      } else if (uiStore.createViewModalOpen) {
        uiStore.closeCreateViewModal()
      } else if (uiStore.issueDetailOpen) {
        uiStore.closeIssueDetail()
      } else if (uiStore.filtersOpen) {
        uiStore.toggleFilters()
      }
      return
    }

    // Don't process other shortcuts if a modal is open
    if (uiStore.commandPaletteOpen || 
        uiStore.createIssueModalOpen || 
        uiStore.createProjectModalOpen ||
        uiStore.shortcutsHelpOpen) {
      return
    }

    // Cmd/Ctrl + K - Open command palette
    if ((event.metaKey || event.ctrlKey) && event.key === 'k') {
      event.preventDefault()
      uiStore.openCommandPalette()
      return
    }

    // Cmd/Ctrl + B - Toggle list/board view
    if ((event.metaKey || event.ctrlKey) && event.key === 'b') {
      event.preventDefault()
      uiStore.toggleViewMode()
      return
    }

    // Cmd/Ctrl + I - Toggle issue details
    if ((event.metaKey || event.ctrlKey) && event.key === 'i') {
      event.preventDefault()
      uiStore.toggleIssueDetail()
      return
    }

    // G+a/b/d/c all mean "this view, for whatever team I'm looking at".
    const goToCurrentTeamView = (view: 'active' | 'backlog' | 'board' | 'cycles') => {
      const teamMatch = router.currentRoute.value.path.match(/\/team\/([^/]+)/)
      if (teamMatch) {
        router.push(`/team/${teamMatch[1]}/${view}`)
      }
    }

    // Handle G + key navigation
    if (pendingG.value) {
      clearPendingG()
      
      switch (event.key.toLowerCase()) {
        case 'h':
          event.preventDefault()
          router.push('/')
          break
        case 'i':
          event.preventDefault()
          router.push('/inbox')
          break
        case 'm':
          event.preventDefault()
          router.push('/my-issues')
          break
        case 'p':
          event.preventDefault()
          router.push('/projects')
          break
        case 's':
          event.preventDefault()
          router.push('/settings')
          break
        case 'a':
          event.preventDefault()
          goToCurrentTeamView('active')
          break
        case 'b':
          event.preventDefault()
          goToCurrentTeamView('backlog')
          break
        case 'd':
          event.preventDefault()
          goToCurrentTeamView('board')
          break
        case 'c':
          event.preventDefault()
          goToCurrentTeamView('cycles')
          break
      }
      return
    }

    // ? - Show keyboard shortcuts help
    if (event.key === '?' || (event.shiftKey && event.key === '/')) {
      event.preventDefault()
      uiStore.openShortcutsHelp()
      return
    }

    // / - Open search (command palette in search mode)
    if (event.key === '/') {
      event.preventDefault()
      uiStore.openCommandPalette()
      return
    }

    // C - Create new issue
    if (event.key === 'c' && !event.metaKey && !event.ctrlKey) {
      event.preventDefault()
      uiStore.openCreateIssueModal()
      return
    }

    // G - Start navigation sequence
    if (event.key === 'g' && !event.metaKey && !event.ctrlKey) {
      event.preventDefault()
      pendingG.value = true
      // Clear after 1 second if no follow-up key
      pendingGTimeout = setTimeout(clearPendingG, 1000)
      return
    }
  }

  onMounted(() => {
    window.addEventListener('keydown', handleKeyDown)
  })

  onUnmounted(() => {
    window.removeEventListener('keydown', handleKeyDown)
    clearPendingG()
  })

  return {
    pendingG
  }
}
