import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { setActivePinia, createPinia } from 'pinia'
import IssueListItem from './IssueListItem.vue'
import LinearStatusIcon from '@/components/icons/LinearStatusIcon.vue'
import LinearPriorityIcon from '@/components/icons/LinearPriorityIcon.vue'
import type { Issue, IssuePriority, WorkflowStateType } from '@/types'

const push = vi.fn()
vi.mock('vue-router', () => ({
  useRouter: () => ({ push }),
}))

function makeIssue(overrides: Partial<Issue> = {}): Issue {
  return {
    id: 'issue-1',
    identifier: 'PAY-8884',
    title: 'Reconcile settlement batches',
    priority: 2,
    status: 'todo',
    ...overrides,
  } as Issue
}

const mountItem = (issue: Issue) =>
  mount(IssueListItem, {
    props: { issue },
    global: { stubs: { Avatar: true, OriginBadge: true } },
  })

describe('IssueListItem', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    push.mockClear()
  })

  it('renders the measured Linear glyphs, not generic icons', () => {
    const w = mountItem(makeIssue())
    expect(w.findComponent(LinearStatusIcon).exists()).toBe(true)
    expect(w.findComponent(LinearPriorityIcon).exists()).toBe(true)
  })

  it('passes the workflow state through so the glyph matches the real state', () => {
    const w = mountItem(
      makeIssue({
        workflowState: { id: 'ws-1', name: 'In Review', stateType: 'started' as WorkflowStateType },
      } as Partial<Issue>),
    )
    const icon = w.findComponent(LinearStatusIcon)
    expect(icon.props('name')).toBe('In Review')
    expect(icon.props('type')).toBe('started')
  })

  it('keeps the priority slot at priority 0 instead of collapsing the row', () => {
    // Linear always draws something here; an empty slot would shift the identifier.
    const w = mountItem(makeIssue({ priority: 0 as IssuePriority }))
    const icon = w.findComponent(LinearPriorityIcon)
    expect(icon.exists()).toBe(true)
    expect(icon.props('priority')).toBe(0)
  })

  it.each([0, 1, 2, 3, 4])('renders priority %s', (priority) => {
    const w = mountItem(makeIssue({ priority: priority as IssuePriority }))
    expect(w.findComponent(LinearPriorityIcon).props('priority')).toBe(priority)
  })

  it('styles the identifier with the tabular-figure class, not a mono font', () => {
    const w = mountItem(makeIssue())
    const id = w.find('.issue-identifier')
    expect(id.exists()).toBe(true)
    expect(id.text()).toContain('PAY-8884')
    expect(w.html()).not.toContain('font-mono')
  })

  it('emits the issue and routes to it on click', async () => {
    const issue = makeIssue()
    const w = mountItem(issue)
    await w.trigger('click')
    expect(w.emitted('click')?.[0]).toEqual([issue])
    expect(push).toHaveBeenCalledWith('/issue/issue-1')
  })

  it('falls back to the plain status when there is no workflow state', () => {
    const w = mountItem(makeIssue({ status: 'done', workflowState: undefined }))
    // no name/type to hand over — the icon has to cope rather than crash
    const icon = w.findComponent(LinearStatusIcon)
    expect(icon.exists()).toBe(true)
    expect(icon.find('svg').exists()).toBe(true)
  })
})
