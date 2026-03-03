<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useUiStore } from '@/stores/ui'
import IssueList from '@/components/issues/IssueList.vue'
import type { Issue } from '@/types'

const router = useRouter()
const authStore = useAuthStore()
const uiStore = useUiStore()

const activeTab = ref<'assigned' | 'created' | 'subscribed'>('assigned')

const baseFilters = computed(() => {
  if (activeTab.value === 'assigned') {
    return {
      myIssues: true,
      sort: 'updated_at' as const,
      direction: 'desc' as const,
    }
  }

  if (activeTab.value === 'created' && authStore.user?.id) {
    return {
      creatorId: authStore.user.id,
      sort: 'updated_at' as const,
      direction: 'desc' as const,
    }
  }

  return {
    sort: 'updated_at' as const,
    direction: 'desc' as const,
  }
})

const emptyState = computed(() => {
  if (activeTab.value === 'assigned') {
    return {
      title: 'No assigned issues',
      description: 'Issues assigned to you will appear here.',
    }
  }

  return {
    title: 'No created issues',
    description: 'Issues you create will appear here.',
  }
})

function handleIssueClick(issue: Issue) {
  router.push(`/issue/${issue.id}`)
}

function handleCreateIssue() {
  uiStore.openCreateIssueModal()
}
</script>

<template>
  <div data-testid="my-issues-ready" class="h-full flex flex-col bg-[var(--linear-bg)]">
    <div class="flex items-center gap-1 px-4 py-2 border-b border-[var(--linear-border-subtle)]">
      <button
        @click="activeTab = 'assigned'"
        :class="[
          'px-3 py-1.5 text-sm rounded-md transition-colors',
          activeTab === 'assigned'
            ? 'bg-[var(--linear-elevated)] text-[var(--linear-text)]'
            : 'text-[var(--linear-muted)] hover:text-[var(--linear-text)] hover:bg-[var(--linear-elevated)]'
        ]"
      >
        Assigned to me
      </button>
      <button
        @click="activeTab = 'created'"
        :class="[
          'px-3 py-1.5 text-sm rounded-md transition-colors',
          activeTab === 'created'
            ? 'bg-[var(--linear-elevated)] text-[var(--linear-text)]'
            : 'text-[var(--linear-muted)] hover:text-[var(--linear-text)] hover:bg-[var(--linear-elevated)]'
        ]"
      >
        Created by me
      </button>
      <button
        @click="activeTab = 'subscribed'"
        :class="[
          'px-3 py-1.5 text-sm rounded-md transition-colors',
          activeTab === 'subscribed'
            ? 'bg-[var(--linear-elevated)] text-[var(--linear-text)]'
            : 'text-[var(--linear-muted)] hover:text-[var(--linear-text)] hover:bg-[var(--linear-elevated)]'
        ]"
      >
        Subscribed
      </button>
    </div>

    <div v-if="activeTab === 'subscribed'" class="flex-1 flex items-center justify-center p-6 text-center">
      <div>
        <h3 class="text-sm font-medium text-[var(--linear-text)] mb-1">Subscribed issues are not available yet</h3>
        <p class="text-xs text-[var(--linear-muted)]">Issue subscriptions are excluded from this slice and tracked in parity exclusions.</p>
      </div>
    </div>

    <IssueList
      v-else
      :key="activeTab"
      :base-filters="baseFilters"
      :show-filters="true"
      :empty-title="emptyState.title"
      :empty-description="emptyState.description"
      @issue-click="handleIssueClick"
      @create-issue="handleCreateIssue"
    />
  </div>
</template>
