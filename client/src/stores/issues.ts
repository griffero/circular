import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { Issue, IssueStatus, IssuePriority, Label, Comment, WorkflowState, Cycle, WorkflowStateType } from '@/types'
import { api } from '@/api/client'
import { useAuthStore } from './auth'

export interface IssueFilters {
  teamId?: string
  projectId?: string
  assigneeId?: string
  creatorId?: string
  myIssues?: boolean
  cycleId?: string
  workflowStateId?: string
  status?: IssueStatus
  statuses?: IssueStatus[]
  priority?: IssuePriority
  q?: string
  sort?: 'created_at' | 'updated_at' | 'priority' | 'due_date'
  direction?: 'asc' | 'desc'
  perPage?: number
}

// Optimistic update tracking
interface PendingUpdate {
  id: string
  originalData: Issue
  timestamp: number
}

export const useIssuesStore = defineStore('issues', () => {
  const issues = ref<Issue[]>([])
  const currentIssue = ref<Issue | null>(null)
  const labels = ref<Label[]>([])
  const comments = ref<Comment[]>([])
  const workflowStates = ref<WorkflowState[]>([])
  const cycles = ref<Cycle[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  // Track pending optimistic updates
  const pendingUpdates = ref<Map<string, PendingUpdate>>(new Map())

  const authStore = useAuthStore()

  // Helper to get effective status from workflow state
  const getEffectiveStatus = (issue: Issue): IssueStatus => {
    if (issue.workflowState?.stateType) {
      const stateTypeToStatus: Record<WorkflowStateType, IssueStatus> = {
        triage: 'backlog',
        backlog: 'backlog',
        unstarted: 'todo',
        started: 'in_progress',
        completed: 'done',
        canceled: 'canceled'
      }
      return stateTypeToStatus[issue.workflowState.stateType] || issue.status || 'backlog'
    }
    return issue.status || 'backlog'
  }

  // Filtered issues by status (supports both legacy status and workflow state)
  const issuesByStatus = computed(() => {
    const grouped: Record<IssueStatus, Issue[]> = {
      backlog: [],
      todo: [],
      in_progress: [],
      in_review: [],
      done: [],
      canceled: []
    }
    for (const issue of issues.value) {
      const status = getEffectiveStatus(issue)
      grouped[status].push(issue)
    }
    return grouped
  })

  // Group issues by workflow state (for teams using dynamic states)
  const issuesByWorkflowState = computed(() => {
    const grouped: Record<string, Issue[]> = {}
    for (const state of workflowStates.value) {
      grouped[state.id] = issues.value.filter(i => i.workflowStateId === state.id)
    }
    return grouped
  })

  const openIssues = computed(() => 
    issues.value.filter(i => {
      const status = getEffectiveStatus(i)
      return !['done', 'canceled'].includes(status)
    })
  )

  const closedIssues = computed(() => 
    issues.value.filter(i => {
      const status = getEffectiveStatus(i)
      return ['done', 'canceled'].includes(status)
    })
  )

  async function fetchIssues(filters: IssueFilters = {}) {
    try {
      loading.value = true
      error.value = null

      const params = new URLSearchParams()
      if (filters.teamId) params.append('team_id', filters.teamId)
      if (filters.projectId) params.append('project_id', filters.projectId)
      if (filters.assigneeId) params.append('assignee_id', filters.assigneeId)
      if (filters.creatorId) params.append('creator_id', filters.creatorId)
      if (filters.myIssues) params.append('my_issues', 'true')
      if (filters.cycleId) params.append('cycle_id', filters.cycleId)
      if (filters.workflowStateId) params.append('workflow_state_id', filters.workflowStateId)
      if (filters.status) params.append('status', filters.status)
      if (filters.statuses && filters.statuses.length > 0) params.append('statuses', filters.statuses.join(','))
      if (filters.priority !== undefined) params.append('priority', String(filters.priority))
      if (filters.q) params.append('q', filters.q)
      if (filters.sort) params.append('sort', filters.sort)
      if (filters.direction) params.append('direction', filters.direction)
      if (filters.perPage) params.append('per_page', String(filters.perPage))

      const url = `/api/v1/issues?${params.toString()}`
      const data = await api.get<{ issues: Issue[] }>(url)
      issues.value = data.issues
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to fetch issues'
    } finally {
      loading.value = false
    }
  }

  // Fetch workflow states for a team
  async function fetchWorkflowStates(teamId: string) {
    try {
      const data = await api.get<{ workflow_states: WorkflowState[] }>(`/api/v1/teams/${teamId}/workflow_states`)
      workflowStates.value = data.workflow_states
    } catch (err) {
      console.error('Failed to fetch workflow states:', err)
    }
  }

  // Fetch cycles for a team  
  async function fetchCycles(teamId: string) {
    try {
      const data = await api.get<{ cycles: Cycle[] }>(`/api/v1/teams/${teamId}/cycles`)
      cycles.value = data.cycles
    } catch (err) {
      console.error('Failed to fetch cycles:', err)
    }
  }

  async function fetchIssue(issueId: string) {
    try {
      loading.value = true
      error.value = null

      const data = await api.get<{ issue: Issue }>(`/api/v1/issues/${issueId}`)
      currentIssue.value = data.issue
      return data.issue
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to fetch issue'
      return null
    } finally {
      loading.value = false
    }
  }

  async function createIssue(issueData: {
    teamId: string
    title: string
    description?: string
    status?: IssueStatus
    priority?: IssuePriority
    assigneeId?: string
    projectId?: string
    dueDate?: string
    labelIds?: string[]
  }) {
    // Create optimistic issue
    const optimisticId = `optimistic-${Date.now()}`
    const optimisticIssue: Issue = {
      id: optimisticId,
      teamId: issueData.teamId,
      creatorId: authStore.user?.id || '',
      assigneeId: issueData.assigneeId,
      projectId: issueData.projectId,
      identifier: '...',
      number: 0,
      title: issueData.title,
      description: issueData.description,
      status: issueData.status || 'backlog',
      priority: issueData.priority ?? 0,
      priorityLabel: '',
      dueDate: issueData.dueDate,
      sortOrder: 0,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    }

    // Add optimistically
    issues.value.unshift(optimisticIssue)

    try {
      error.value = null

      const data = await api.post<{ issue: Issue }>(
        '/api/v1/issues',
        {
          teamId: issueData.teamId,
          issue: {
            title: issueData.title,
            description: issueData.description,
            status: issueData.status || 'backlog',
            priority: issueData.priority ?? 0,
            assigneeId: issueData.assigneeId,
            projectId: issueData.projectId,
            dueDate: issueData.dueDate,
            labelIds: issueData.labelIds
          }
        }
      )

      // Replace optimistic issue with real one
      const index = issues.value.findIndex(i => i.id === optimisticId)
      if (index !== -1) {
        issues.value[index] = data.issue
      }

      return data.issue
    } catch (err) {
      // Remove optimistic issue on failure
      issues.value = issues.value.filter(i => i.id !== optimisticId)
      error.value = err instanceof Error ? err.message : 'Failed to create issue'
      throw err
    }
  }

  async function updateIssue(issueId: string, updates: Partial<{
    title: string
    description: string
    status: IssueStatus
    workflowStateId: string | null
    cycleId: string | null
    priority: IssuePriority
    assigneeId: string | null
    projectId: string | null
    dueDate: string | null
    labelIds: string[]
    sortOrder: number
  }>) {
    // Find the issue to update
    const issueIndex = issues.value.findIndex(i => i.id === issueId)
    if (issueIndex === -1) return null

    const originalIssue = { ...issues.value[issueIndex] }

    // Track pending update for rollback
    pendingUpdates.value.set(issueId, {
      id: issueId,
      originalData: originalIssue,
      timestamp: Date.now()
    })

    // Apply optimistic update
    const optimisticUpdate: Issue = {
      ...originalIssue,
      ...updates,
      updatedAt: new Date().toISOString()
    }
    issues.value[issueIndex] = optimisticUpdate

    if (currentIssue.value?.id === issueId) {
      currentIssue.value = optimisticUpdate
    }

    try {
      error.value = null

      const data = await api.patch<{ issue: Issue }>(
        `/api/v1/issues/${issueId}`,
        {
          issue: {
            title: updates.title,
            description: updates.description,
            status: updates.status,
            workflowStateId: updates.workflowStateId,
            cycleId: updates.cycleId,
            priority: updates.priority,
            assigneeId: updates.assigneeId,
            projectId: updates.projectId,
            dueDate: updates.dueDate,
            labelIds: updates.labelIds,
            sortOrder: updates.sortOrder
          }
        }
      )

      // Update with server response
      const newIndex = issues.value.findIndex(i => i.id === issueId)
      if (newIndex !== -1) {
        issues.value[newIndex] = data.issue
      }
      if (currentIssue.value?.id === issueId) {
        currentIssue.value = data.issue
      }

      // Clear pending update
      pendingUpdates.value.delete(issueId)

      return data.issue
    } catch (err) {
      // Rollback optimistic update
      const pending = pendingUpdates.value.get(issueId)
      if (pending) {
        const rollbackIndex = issues.value.findIndex(i => i.id === issueId)
        if (rollbackIndex !== -1) {
          issues.value[rollbackIndex] = pending.originalData
        }
        if (currentIssue.value?.id === issueId) {
          currentIssue.value = pending.originalData
        }
        pendingUpdates.value.delete(issueId)
      }

      error.value = err instanceof Error ? err.message : 'Failed to update issue'
      throw err
    }
  }

  async function deleteIssue(issueId: string) {
    // Find and store the issue for potential rollback
    const issueIndex = issues.value.findIndex(i => i.id === issueId)
    const deletedIssue = issueIndex !== -1 ? issues.value[issueIndex] : null

    // Optimistically remove
    issues.value = issues.value.filter(i => i.id !== issueId)
    if (currentIssue.value?.id === issueId) {
      currentIssue.value = null
    }

    try {
      error.value = null

      await api.delete(`/api/v1/issues/${issueId}`)
    } catch (err) {
      // Rollback: restore the deleted issue
      if (deletedIssue) {
        issues.value.splice(issueIndex, 0, deletedIssue)
      }

      error.value = err instanceof Error ? err.message : 'Failed to delete issue'
      throw err
    }
  }

  // Labels
  async function fetchLabels(teamId?: string) {
    try {
      const params = teamId ? `?team_id=${teamId}` : ''
      const data = await api.get<{ labels: Label[] }>(`/api/v1/labels${params}`)
      labels.value = data.labels
    } catch (err) {
      console.error('Failed to fetch labels:', err)
    }
  }

  async function createLabel(labelData: { name: string; color: string; description?: string; teamId?: string }) {
    try {
      const data = await api.post<{ label: Label }>(
        '/api/v1/labels',
        { label: labelData }
      )
      labels.value.push(data.label)
      return data.label
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to create label'
      throw err
    }
  }

  // Comments
  async function fetchComments(issueId: string) {
    try {
      const data = await api.get<{ comments: Comment[] }>(`/api/v1/issues/${issueId}/comments`)
      comments.value = data.comments
    } catch (err) {
      console.error('Failed to fetch comments:', err)
    }
  }

  async function createComment(issueId: string, body: string, parentId?: string) {
    // Optimistic comment
    const optimisticId = `optimistic-comment-${Date.now()}`
    const optimisticComment: Comment = {
      id: optimisticId,
      issueId,
      userId: authStore.user?.id || '',
      parentId,
      body,
      edited: false,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      user: authStore.user || undefined
    }

    comments.value.push(optimisticComment)

    try {
      const data = await api.post<{ comment: Comment }>(
        `/api/v1/issues/${issueId}/comments`,
        { comment: { body, parentId } }
      )

      // Replace optimistic with real
      const index = comments.value.findIndex(c => c.id === optimisticId)
      if (index !== -1) {
        comments.value[index] = data.comment
      }

      return data.comment
    } catch (err) {
      // Remove optimistic comment
      comments.value = comments.value.filter(c => c.id !== optimisticId)
      error.value = err instanceof Error ? err.message : 'Failed to create comment'
      throw err
    }
  }

  // Real-time updates from ActionCable
  function handleIssueCreated(issue: Issue) {
    // Don't add if it's our own optimistic issue that was just confirmed
    const exists = issues.value.some(i => i.id === issue.id)
    if (!exists) {
      issues.value.unshift(issue)
    }
  }

  function handleIssueUpdated(issue: Issue) {
    // Skip if we have a pending update (we're waiting for our own request)
    if (pendingUpdates.value.has(issue.id)) {
      return
    }

    const index = issues.value.findIndex(i => i.id === issue.id)
    if (index !== -1) {
      issues.value[index] = issue
    }
    if (currentIssue.value?.id === issue.id) {
      currentIssue.value = issue
    }
  }

  function handleIssueDeleted(issueId: string) {
    issues.value = issues.value.filter(i => i.id !== issueId)
    if (currentIssue.value?.id === issueId) {
      currentIssue.value = null
    }
  }

  function handleCommentCreated(comment: Comment) {
    // Don't add if it already exists (from optimistic update)
    const exists = comments.value.some(c => c.id === comment.id)
    if (!exists) {
      comments.value.push(comment)
    }
  }

  function handleCommentUpdated(comment: Comment) {
    const index = comments.value.findIndex(c => c.id === comment.id)
    if (index !== -1) {
      comments.value[index] = comment
    }
  }

  function handleCommentDeleted(commentId: string) {
    comments.value = comments.value.filter(c => c.id !== commentId)
  }

  function reset() {
    issues.value = []
    currentIssue.value = null
    labels.value = []
    comments.value = []
    workflowStates.value = []
    cycles.value = []
    error.value = null
    pendingUpdates.value.clear()
  }

  return {
    // State
    issues,
    currentIssue,
    labels,
    comments,
    workflowStates,
    cycles,
    loading,
    error,

    // Computed
    issuesByStatus,
    issuesByWorkflowState,
    openIssues,
    closedIssues,

    // Actions
    fetchIssues,
    fetchIssue,
    createIssue,
    updateIssue,
    deleteIssue,
    fetchLabels,
    createLabel,
    fetchComments,
    createComment,
    fetchWorkflowStates,
    fetchCycles,

    // Real-time handlers
    handleIssueCreated,
    handleIssueUpdated,
    handleIssueDeleted,
    handleCommentCreated,
    handleCommentUpdated,
    handleCommentDeleted,

    // Helpers
    getEffectiveStatus,

    reset
  }
})
