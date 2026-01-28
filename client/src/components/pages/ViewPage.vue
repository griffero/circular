<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useUiStore } from '@/stores/ui'
import { Eye, Plus, Inbox } from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const uiStore = useUiStore()

const viewId = computed(() => route.params.viewId as string)

// Placeholder view data
const view = ref<{
  id: string
  name: string
  description?: string
  filters: Record<string, unknown>
} | null>({
  id: viewId.value,
  name: 'Custom View',
  description: 'A custom filtered view of issues',
  filters: {},
})

const issues = ref<unknown[]>([])
const loading = ref(false)

function addIssue() {
  uiStore.openCreateIssueModal()
}
</script>

<template>
  <div v-if="view" class="flex flex-col h-full bg-[#0d0d0d]">
    <!-- View header -->
    <div class="flex items-center justify-between px-4 py-3 border-b border-[#1f1f1f]">
      <div class="flex items-center gap-3">
        <div class="w-8 h-8 rounded-lg bg-indigo-500/20 flex items-center justify-center">
          <Eye class="h-4 w-4 text-indigo-400" />
        </div>
        <div>
          <h1 class="text-lg font-semibold text-white">
            {{ view.name }}
          </h1>
          <p v-if="view.description" class="text-sm text-gray-500">
            {{ view.description }}
          </p>
        </div>
      </div>
      <div class="flex items-center gap-2">
        <button 
          @click="addIssue"
          class="flex items-center gap-1.5 px-3 py-1.5 text-sm bg-indigo-600 hover:bg-indigo-700 text-white rounded transition-colors"
        >
          <Plus class="h-4 w-4" />
          Add issue
        </button>
      </div>
    </div>

    <!-- Content -->
    <div class="flex-1 overflow-auto p-6">
      <div v-if="loading" class="flex items-center justify-center py-16">
        <div class="animate-spin rounded-full h-8 w-8 border-2 border-indigo-500 border-t-transparent"></div>
      </div>

      <div v-else-if="issues.length === 0" class="flex flex-col items-center justify-center py-16">
        <div class="w-16 h-16 rounded-full bg-[#1a1a1a] flex items-center justify-center mb-4">
          <Inbox class="h-8 w-8 text-gray-500" />
        </div>
        <h3 class="text-lg font-medium text-white mb-1">
          No issues match this view
        </h3>
        <p class="text-sm text-gray-500 text-center max-w-sm mb-4">
          Try adjusting your filters or create new issues that match this view's criteria.
        </p>
        <button 
          @click="addIssue"
          class="flex items-center gap-1.5 px-4 py-2 text-sm bg-indigo-600 hover:bg-indigo-700 text-white rounded transition-colors"
        >
          <Plus class="h-4 w-4" />
          Create issue
        </button>
      </div>

      <div v-else>
        <!-- Issue list will go here -->
      </div>
    </div>
  </div>

  <div v-else class="flex items-center justify-center h-full bg-[#0d0d0d]">
    <div class="text-center">
      <p class="text-gray-500">View not found</p>
      <button 
        @click="router.push('/')"
        class="mt-4 px-4 py-2 text-sm text-gray-400 hover:text-white hover:bg-[#1a1a1a] rounded transition-colors"
      >
        Go back home
      </button>
    </div>
  </div>
</template>
