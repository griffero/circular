<script setup lang="ts">
import Modal from '@/components/ui/Modal.vue'
import { Command, Search, Plus, ArrowUp, ArrowDown } from 'lucide-vue-next'

defineProps<{
  open: boolean
}>()

const emit = defineEmits<{
  (e: 'close'): void
}>()

const sections = [
  {
    title: 'General',
    shortcuts: [
      { keys: ['⌘', 'K'], description: 'Open command menu' },
      { keys: ['?'], description: 'Show keyboard shortcuts' },
      { keys: ['/'], description: 'Open search' },
      { keys: ['Esc'], description: 'Go back / Close' },
    ]
  },
  {
    title: 'Navigation (G then...)',
    shortcuts: [
      { keys: ['G', 'H'], description: 'Go to home' },
      { keys: ['G', 'I'], description: 'Go to inbox' },
      { keys: ['G', 'M'], description: 'Go to my issues' },
      { keys: ['G', 'P'], description: 'Go to projects' },
      { keys: ['G', 'S'], description: 'Go to settings' },
    ]
  },
  {
    title: 'Issue Actions',
    shortcuts: [
      { keys: ['C'], description: 'Create new issue' },
      { keys: ['Enter'], description: 'Open selected issue' },
      { keys: ['Space'], description: 'Preview issue' },
      { keys: ['S'], description: 'Change status' },
      { keys: ['P'], description: 'Change priority' },
      { keys: ['A'], description: 'Assign to user' },
      { keys: ['I'], description: 'Assign to me' },
      { keys: ['L'], description: 'Add label' },
    ]
  },
  {
    title: 'View & Selection',
    shortcuts: [
      { keys: ['⌘', 'B'], description: 'Toggle list/board view' },
      { keys: ['⌘', 'I'], description: 'Toggle issue details' },
      { keys: ['X'], description: 'Select item' },
      { keys: ['↑', '/', 'K'], description: 'Move up' },
      { keys: ['↓', '/', 'J'], description: 'Move down' },
    ]
  },
]
</script>

<template>
  <Modal :open="open" @close="emit('close')" size="lg" title="Keyboard shortcuts">
    <div class="grid grid-cols-2 gap-6">
      <div v-for="section in sections" :key="section.title">
        <h3 class="text-sm font-medium text-white mb-3">{{ section.title }}</h3>
        <div class="space-y-2">
          <div 
            v-for="shortcut in section.shortcuts" 
            :key="shortcut.description"
            class="flex items-center justify-between text-sm"
          >
            <span class="text-gray-400">{{ shortcut.description }}</span>
            <div class="flex items-center gap-1">
              <kbd 
                v-for="(key, idx) in shortcut.keys" 
                :key="idx"
                class="px-2 py-1 text-xs font-mono bg-gray-800 border border-gray-700 rounded text-gray-300"
              >
                {{ key }}
              </kbd>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <div class="mt-6 pt-4 border-t border-gray-700">
      <p class="text-xs text-gray-500 text-center">
        Press <kbd class="px-1.5 py-0.5 text-xs font-mono bg-gray-800 border border-gray-700 rounded text-gray-400">?</kbd> anytime to show this help
      </p>
    </div>
  </Modal>
</template>
