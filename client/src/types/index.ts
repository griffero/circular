export interface User {
  id: string
  name: string
  displayName?: string
  email: string
  avatarUrl?: string
  timezone?: string
  role: 'owner' | 'admin' | 'member'
  admin?: boolean
  guest?: boolean
  active?: boolean
  linearId?: string
  createdAt?: string
  updatedAt?: string
}

export interface Team {
  id: string
  name: string
  key: string
  description?: string
  color?: string
  icon?: string
  issueCounter?: number
  settings?: Record<string, unknown>
  linearId?: string
  createdAt?: string
  updatedAt?: string
  // Associations
  workflowStates?: WorkflowState[]
  cycles?: Cycle[]
}

export interface TeamMembership {
  id: string
  userId: string
  teamId: string
  role: 'lead' | 'member'
  user?: User
  team?: Team
  createdAt?: string
  updatedAt?: string
}

// Workflow state types (matches Linear's workflow states)
export type WorkflowStateType = 'triage' | 'backlog' | 'unstarted' | 'started' | 'completed' | 'canceled'

export interface WorkflowState {
  id: string
  teamId: string
  name: string
  color: string
  description?: string
  stateType: WorkflowStateType
  position: number
  linearId?: string
  createdAt?: string
  updatedAt?: string
  // Associations
  team?: Team
}

// Cycle/Sprint types
export interface Cycle {
  id: string
  teamId: string
  number: number
  name?: string
  description?: string
  startsAt?: string
  endsAt?: string
  progress: number
  completedAt?: string
  linearId?: string
  createdAt?: string
  updatedAt?: string
  displayName?: string
  active?: boolean
  // Associations
  team?: Team
}

// Project health types (matches Linear)
export type ProjectHealth = 'onTrack' | 'atRisk' | 'offTrack'
export type ProjectState = 'backlog' | 'planned' | 'started' | 'paused' | 'completed' | 'canceled'

export interface Project {
  id: string
  name: string
  slug: string
  slugId?: string
  description?: string
  status: 'active' | 'paused' | 'completed' | 'canceled'
  state?: ProjectState
  health?: ProjectHealth
  progress?: number
  privacy: 'public' | 'private'
  color?: string
  icon?: string
  leadId?: string
  startDate?: string
  targetDate?: string
  settings?: Record<string, unknown>
  linearId?: string
  lead?: User
  teams?: Team[]
  createdAt?: string
  updatedAt?: string
}

export interface ProjectMembership {
  id: string
  userId: string
  projectId: string
  role: 'lead' | 'member'
  user?: User
  project?: Project
  createdAt?: string
  updatedAt?: string
}

// Auth response types
export interface AuthResponse {
  user: User
  teams: Team[]
  projects: Project[]
}

// Issue types
export interface Issue {
  id: string
  teamId: string
  creatorId: string
  assigneeId?: string
  projectId?: string
  parentId?: string
  workflowStateId?: string
  cycleId?: string
  identifier: string
  number: number
  title: string
  description?: string
  descriptionHtml?: string
  status?: IssueStatus // Legacy status (kept for backwards compatibility)
  priority: IssuePriority
  priorityLabel: string
  dueDate?: string
  estimate?: number
  sortOrder: number
  startedAt?: string
  completedAt?: string
  canceledAt?: string
  archivedAt?: string
  linearId?: string
  createdAt: string
  updatedAt: string
  // Associations (when included in response)
  creator?: User
  assignee?: User
  team?: Team
  project?: Project
  labels?: Label[]
  subIssues?: Issue[]
  parent?: Issue
  workflowState?: WorkflowState
  cycle?: Cycle
  attachments?: Attachment[]
  blockingIssues?: Issue[]
  blockedIssues?: Issue[]
}

export type IssueStatus = 'backlog' | 'todo' | 'in_progress' | 'in_review' | 'done' | 'canceled'

export type IssuePriority = 0 | 1 | 2 | 3 | 4

export const PRIORITY_LABELS: Record<IssuePriority, string> = {
  0: 'No priority',
  1: 'Urgent',
  2: 'High',
  3: 'Medium',
  4: 'Low'
}

export const STATUS_LABELS: Record<IssueStatus, string> = {
  backlog: 'Backlog',
  todo: 'Todo',
  in_progress: 'In Progress',
  in_review: 'In Review',
  done: 'Done',
  canceled: 'Canceled'
}

// Map workflow state type to legacy status for backwards compatibility
export const WORKFLOW_STATE_TO_STATUS: Record<WorkflowStateType, IssueStatus> = {
  triage: 'backlog',
  backlog: 'backlog',
  unstarted: 'todo',
  started: 'in_progress',
  completed: 'done',
  canceled: 'canceled'
}

export interface Label {
  id: string
  teamId?: string
  parentId?: string
  name: string
  color: string
  description?: string
  isGroup?: boolean
  linearId?: string
  createdAt: string
  updatedAt: string
  // Associations
  parent?: Label
  children?: Label[]
}

// Attachment types
export type AttachmentType = 'github_pr' | 'github_issue' | 'url' | 'file'

export interface Attachment {
  id: string
  issueId: string
  title?: string
  url: string
  attachmentType?: AttachmentType
  linearId?: string
  createdAt?: string
  updatedAt?: string
}

// Issue relation types
export type IssueRelationType = 'blocks' | 'related' | 'duplicate'

export interface IssueRelation {
  id: string
  issueId: string
  relatedIssueId: string
  relationType: IssueRelationType
  createdAt?: string
  updatedAt?: string
  // Associations
  issue?: Issue
  relatedIssue?: Issue
}

export interface Comment {
  id: string
  issueId: string
  userId: string
  parentId?: string
  body: string
  bodyHtml?: string
  edited: boolean
  editedAt?: string
  createdAt: string
  updatedAt: string
  // Associations
  user?: User
  replies?: Comment[]
}

export interface IssueActivity {
  id: string
  issueId: string
  userId: string
  action: string
  field?: string
  oldValue?: string
  newValue?: string
  createdAt: string
  // Associations
  user?: User
}

// API Error
export interface ApiError {
  error?: string
  errors?: string[]
  message?: string
}
