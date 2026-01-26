<script setup lang="ts">
import { watch } from 'vue'
import { RouterView } from 'vue-router'
import { useUiStore } from '@/stores/ui'
import { useKeyboardShortcuts } from '@/composables/useKeyboardShortcuts'
import CommandPalette from '@/components/layout/CommandPalette.vue'
import KeyboardShortcutsHelp from '@/components/layout/KeyboardShortcutsHelp.vue'
import CreateIssueModal from '@/components/issues/CreateIssueModal.vue'
import CreateProjectModal from '@/components/projects/CreateProjectModal.vue'
import CreateInitiativeModal from '@/components/initiatives/CreateInitiativeModal.vue'
import CreateViewModal from '@/components/views/CreateViewModal.vue'

const uiStore = useUiStore()

// Initialize keyboard shortcuts
useKeyboardShortcuts()

// Apply dark mode class to html element
watch(
  () => uiStore.darkMode,
  (isDark) => {
    document.documentElement.classList.toggle('dark', isDark)
  },
  { immediate: true }
)
</script>

<template>
  <RouterView />
  <CommandPalette />
  <KeyboardShortcutsHelp 
    :open="uiStore.shortcutsHelpOpen" 
    @close="uiStore.closeShortcutsHelp()" 
  />
  <CreateIssueModal
    :open="uiStore.createIssueModalOpen"
    @close="uiStore.closeCreateIssueModal()"
    @created="uiStore.closeCreateIssueModal()"
  />
  <CreateProjectModal
    :open="uiStore.createProjectModalOpen"
    @close="uiStore.closeCreateProjectModal()"
    @created="uiStore.closeCreateProjectModal()"
  />
  <CreateInitiativeModal
    :open="uiStore.createInitiativeModalOpen"
    @close="uiStore.closeCreateInitiativeModal()"
    @created="uiStore.closeCreateInitiativeModal()"
  />
  <CreateViewModal
    :open="uiStore.createViewModalOpen"
    @close="uiStore.closeCreateViewModal()"
    @created="uiStore.closeCreateViewModal()"
  />
</template>
