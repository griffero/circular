<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useUiStore } from '@/stores/ui'
import IssueList from '@/components/issues/IssueList.vue'
import type { Issue } from '@/types'

type MyIssuesTab = 'assigned' | 'created' | 'subscribed'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()
const uiStore = useUiStore()

function resolveTab(view: unknown): MyIssuesTab {
  if (view === 'created' || view === 'subscribed') {
    return view
  }
  return 'assigned'
}

const activeTab = ref<MyIssuesTab>(resolveTab(route.query.view))

watch(
  () => route.query.view,
  (view) => {
    const nextTab = resolveTab(view)
    if (activeTab.value !== nextTab) {
      activeTab.value = nextTab
    }
  }
)

watch(
  activeTab,
  (tab) => {
    if (route.query.view === tab) return
    router.replace({
      path: '/my-issues',
      query: {
        ...route.query,
        view: tab,
      },
    })
  },
  { immediate: true }
)

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

  if (activeTab.value === 'subscribed') {
    return {
      subscribed: true,
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

  if (activeTab.value === 'subscribed') {
    return {
      title: 'No subscribed issues',
      description: 'Issues you follow will appear here.',
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

    <IssueList
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
