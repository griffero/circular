<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useIssuesStore } from '@/stores/issues'
import { User, Filter, LayoutList, Columns3, X, Circle, CheckCircle2, Clock, AlertCircle } from 'lucide-vue-next'
import type { Issue, WorkflowState } from '@/types'
import IssueListItem from '@/components/issues/IssueListItem.vue'
import Dropdown from '@/components/ui/Dropdown.vue'
import DropdownItem from '@/components/ui/DropdownItem.vue'

const authStore = useAuthStore()
const issuesStore = useIssuesStore()
const user = computed(() => authStore.user)

// State
const loading = ref(true)
const activeTab = ref<'assigned' | 'created' | 'subscribed'>('assigned')
const viewMode = ref<'list' | 'board'>('list')

// Filters
const showFilterDropdown = ref(false)
const statusFilter = ref<string | null>(null)
const priorityFilter = ref<number | null>(null)

// Workflow states for filtering
const workflowStates = computed(() => issuesStore.workflowStates)

// Status options for filter
const statusOptions = [
  { value: 'backlog', label: 'Backlog', icon: Circle, color: 'text-gray-400' },
  { value: 'unstarted', label: 'Todo', icon: Circle, color: 'text-gray-400' },
  { value: 'started', label: 'In Progress', icon: Clock, color: 'text-yellow-500' },
  { value: 'completed', label: 'Done', icon: CheckCircle2, color: 'text-green-500' },
  { value: 'canceled', label: 'Canceled', icon: X, color: 'text-red-500' },
]

// Priority options
const priorityOptions = [
  { value: 1, label: 'Urgent', color: 'bg-red-500' },
  { value: 2, label: 'High', color: 'bg-orange-500' },
  { value: 3, label: 'Medium', color: 'bg-yellow-500' },
  { value: 4, label: 'Low', color: 'bg-blue-500' },
  { value: 0, label: 'No priority', color: 'bg-gray-500' },
]

// Get all issues for current user
const allIssues = computed(() => issuesStore.issues)

// Filter issues based on tab and filters
const filteredIssues = computed(() => {
  let issues = allIssues.value

  // Filter by tab
  if (activeTab.value === 'assigned') {
    issues = issues.filter(i => i.assigneeId === user.value?.id)
  } else if (activeTab.value === 'created') {
    issues = issues.filter(i => i.creatorId === user.value?.id)
  }
  // 'subscribed' would need a subscription system - for now show empty

  // Apply status filter
  if (statusFilter.value) {
    issues = issues.filter(i => {
      const state = i.workflowState
      return state?.stateType === statusFilter.value
    })
  }

  // Apply priority filter
  if (priorityFilter.value !== null) {
    issues = issues.filter(i => i.priority === priorityFilter.value)
  }

  return issues
})

const hasIssues = computed(() => filteredIssues.value.length > 0)
const hasActiveFilters = computed(() => statusFilter.value !== null || priorityFilter.value !== null)
const activeFiltersCount = computed(() => {
  let count = 0
  if (statusFilter.value) count++
  if (priorityFilter.value !== null) count++
  return count
})

// Clear filters
function clearFilters() {
  statusFilter.value = null
  priorityFilter.value = null
}

// Load issues
async function loadIssues() {
  loading.value = true
  try {
    // Load all issues - filtering happens client side
    await issuesStore.fetchIssues({})
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadIssues()
})

// Reload when tab changes
watch(activeTab, () => {
  // Issues are already loaded, just re-filter
})
</script>

<template>
  <div class="h-full flex flex-col bg-[#0d0d0d]">
    <!-- Header -->
    <div class="flex items-center justify-between px-4 py-2 border-b border-[#1f1f1f]">
      <div class="flex items-center gap-1">
        <button 
          @click="activeTab = 'assigned'"
          :class="[
            'px-3 py-1.5 text-sm rounded-md transition-colors',
            activeTab === 'assigned' 
              ? 'bg-[#1a1a1a] text-white' 
              : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
          ]"
        >
          Assigned to me
        </button>
        <button 
          @click="activeTab = 'created'"
          :class="[
            'px-3 py-1.5 text-sm rounded-md transition-colors',
            activeTab === 'created' 
              ? 'bg-[#1a1a1a] text-white' 
              : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
          ]"
        >
          Created by me
        </button>
        <button 
          @click="activeTab = 'subscribed'"
          :class="[
            'px-3 py-1.5 text-sm rounded-md transition-colors',
            activeTab === 'subscribed' 
              ? 'bg-[#1a1a1a] text-white' 
              : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
          ]"
        >
          Subscribed
        </button>
      </div>
      
      <div class="flex items-center gap-2">
        <!-- View mode toggle -->
        <div class="flex items-center gap-0.5 p-0.5 bg-[#1a1a1a] rounded-md">
          <button
            @click="viewMode = 'list'"
            :class="[
              'p-1.5 rounded',
              viewMode === 'list'
                ? 'bg-[#2a2a2a] text-white'
                : 'text-gray-400 hover:text-white'
            ]"
          >
            <LayoutList class="h-4 w-4" />
          </button>
          <button
            @click="viewMode = 'board'"
            :class="[
              'p-1.5 rounded',
              viewMode === 'board'
                ? 'bg-[#2a2a2a] text-white'
                : 'text-gray-400 hover:text-white'
            ]"
          >
            <Columns3 class="h-4 w-4" />
          </button>
        </div>
        
        <!-- Filter dropdown -->
        <Dropdown align="right">
          <template #trigger>
            <button 
              :class="[
                'flex items-center gap-1.5 px-3 py-1.5 text-sm rounded transition-colors',
                hasActiveFilters
                  ? 'bg-indigo-500/20 text-indigo-400 border border-indigo-500/30'
                  : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
              ]"
            >
              <Filter class="h-4 w-4" />
              Filter
              <span v-if="hasActiveFilters" class="text-[11px] bg-indigo-500/30 px-1.5 rounded">
                {{ activeFiltersCount }}
              </span>
            </button>
          </template>
          
          <div class="p-2 min-w-[200px]">
            <div class="text-[11px] font-medium text-gray-500 uppercase tracking-wider px-2 mb-1">Status</div>
            <DropdownItem 
              v-for="status in statusOptions" 
              :key="status.value"
              @click="statusFilter = statusFilter === status.value ? null : status.value"
            >
              <div class="flex items-center justify-between w-full">
                <div class="flex items-center gap-2">
                  <component :is="status.icon" :class="['w-4 h-4', status.color]" />
                  <span>{{ status.label }}</span>
                </div>
                <CheckCircle2 v-if="statusFilter === status.value" class="w-4 h-4 text-indigo-400" />
              </div>
            </DropdownItem>
            
            <div class="border-t border-[#2a2a2a] my-2"></div>
            
            <div class="text-[11px] font-medium text-gray-500 uppercase tracking-wider px-2 mb-1">Priority</div>
            <DropdownItem 
              v-for="priority in priorityOptions" 
              :key="priority.value"
              @click="priorityFilter = priorityFilter === priority.value ? null : priority.value"
            >
              <div class="flex items-center justify-between w-full">
                <div class="flex items-center gap-2">
                  <span :class="['w-2 h-2 rounded-full', priority.color]"></span>
                  <span>{{ priority.label }}</span>
                </div>
                <CheckCircle2 v-if="priorityFilter === priority.value" class="w-4 h-4 text-indigo-400" />
              </div>
            </DropdownItem>
            
            <template v-if="hasActiveFilters">
              <div class="border-t border-[#2a2a2a] my-2"></div>
              <DropdownItem @click="clearFilters" class="text-red-400">
                <X class="w-4 h-4" />
                Clear filters
              </DropdownItem>
            </template>
          </div>
        </Dropdown>
      </div>
    </div>

    <!-- Active filter pills -->
    <div v-if="hasActiveFilters" class="flex items-center gap-2 px-4 py-2 border-b border-[#1f1f1f]">
      <button
        v-if="statusFilter"
        @click="statusFilter = null"
        class="flex items-center gap-1.5 px-2 py-1 bg-[#1a1a1a] hover:bg-[#252525] rounded text-[12px] text-gray-300 transition-colors"
      >
        Status: {{ statusOptions.find(s => s.value === statusFilter)?.label }}
        <X class="w-3 h-3" />
      </button>
      <button
        v-if="priorityFilter !== null"
        @click="priorityFilter = null"
        class="flex items-center gap-1.5 px-2 py-1 bg-[#1a1a1a] hover:bg-[#252525] rounded text-[12px] text-gray-300 transition-colors"
      >
        Priority: {{ priorityOptions.find(p => p.value === priorityFilter)?.label }}
        <X class="w-3 h-3" />
      </button>
      <button
        @click="clearFilters"
        class="text-[12px] text-gray-500 hover:text-white transition-colors"
      >
        Clear all
      </button>
    </div>

    <!-- Content -->
    <div class="flex-1 overflow-auto">
      <div v-if="loading" class="flex items-center justify-center py-16">
        <div class="animate-spin rounded-full h-8 w-8 border-2 border-indigo-500 border-t-transparent"></div>
      </div>

      <div v-else-if="!hasIssues" class="flex flex-col items-center justify-center py-16">
        <div class="w-16 h-16 rounded-full bg-[#1a1a1a] flex items-center justify-center mb-4">
          <User class="h-8 w-8 text-gray-500" />
        </div>
        <h3 class="text-lg font-medium text-white mb-1">
          {{ hasActiveFilters ? 'No matching issues' : 'No issues yet' }}
        </h3>
        <p class="text-sm text-gray-500 text-center max-w-sm">
          {{ hasActiveFilters 
            ? 'Try adjusting your filters to see more results.' 
            : activeTab === 'assigned' 
              ? 'Issues assigned to you will appear here.' 
              : activeTab === 'created'
                ? 'Issues you created will appear here.'
                : 'Subscribe to issues to track them here.'
          }}
        </p>
        <button 
          v-if="hasActiveFilters"
          @click="clearFilters"
          class="mt-4 px-4 py-2 text-sm text-indigo-400 hover:text-indigo-300 transition-colors"
        >
          Clear filters
        </button>
      </div>

      <div v-else class="divide-y divide-[#1f1f1f]">
        <IssueListItem
          v-for="issue in filteredIssues"
          :key="issue.id"
          :issue="issue"
        />
      </div>
    </div>
  </div>
</template>
