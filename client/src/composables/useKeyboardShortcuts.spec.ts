import { describe, it, expect, beforeEach, vi } from 'vitest'
import { defineComponent } from 'vue'
import { mount } from '@vue/test-utils'
import { setActivePinia, createPinia } from 'pinia'
import { useKeyboardShortcuts } from './useKeyboardShortcuts'
import { useUiStore } from '@/stores/ui'

const push = vi.fn()
const currentRoute = { value: { path: '/' } }

vi.mock('vue-router', () => ({
  useRouter: () => ({ push, currentRoute }),
}))

/** Mount a throwaway host so the composable's onMounted listener is installed. */
function mountHost() {
  return mount(
    defineComponent({
      setup() {
        useKeyboardShortcuts()
        return () => null
      },
    }),
    { attachTo: document.body },
  )
}

function press(key: string) {
  document.dispatchEvent(new KeyboardEvent('keydown', { key, bubbles: true }))
}

/** The G-prefix sequence: G, then the destination key. */
function pressG(then: string) {
  press('g')
  press(then)
}

describe('useKeyboardShortcuts — G navigation', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    push.mockClear()
    currentRoute.value = { path: '/' }
    document.body.innerHTML = ''
  })

  it.each([
    ['h', '/'],
    ['i', '/inbox'],
    ['m', '/my-issues'],
    ['p', '/projects'],
    ['s', '/settings'],
  ])('G then %s navigates to %s', (key, path) => {
    const host = mountHost()
    pressG(key)
    expect(push).toHaveBeenCalledWith(path)
    host.unmount()
  })

  it.each([
    ['a', 'active'],
    ['b', 'backlog'],
    ['d', 'board'],
    ['c', 'cycles'],
  ])('G then %s opens the %s view of the team currently in the URL', (key, view) => {
    currentRoute.value = { path: '/team/ENG/backlog' }
    const host = mountHost()
    pressG(key)
    expect(push).toHaveBeenCalledWith(`/team/ENG/${view}`)
    host.unmount()
  })

  it('does not navigate to a team view when no team is in the URL', () => {
    currentRoute.value = { path: '/my-issues' }
    const host = mountHost()
    for (const key of ['a', 'b', 'd', 'c']) {
      pressG(key)
    }
    expect(push).not.toHaveBeenCalled()
    host.unmount()
  })

  it('reads the team from the URL at press time, not at mount time', () => {
    const host = mountHost()

    currentRoute.value = { path: '/team/ENG/active' }
    pressG('d')
    expect(push).toHaveBeenLastCalledWith('/team/ENG/board')

    currentRoute.value = { path: '/team/DESIGN/board' }
    pressG('d')
    expect(push).toHaveBeenLastCalledWith('/team/DESIGN/board')

    host.unmount()
  })

  it('needs the G prefix — a bare key does not navigate', () => {
    currentRoute.value = { path: '/team/ENG/active' }
    const host = mountHost()
    press('d')
    expect(push).not.toHaveBeenCalled()
    host.unmount()
  })

  it('ignores shortcuts while typing in an input', () => {
    const input = document.createElement('input')
    document.body.appendChild(input)
    const host = mountHost()

    input.dispatchEvent(new KeyboardEvent('keydown', { key: 'g', bubbles: true }))
    input.dispatchEvent(new KeyboardEvent('keydown', { key: 'i', bubbles: true }))

    expect(push).not.toHaveBeenCalled()
    host.unmount()
  })

  it('stops listening once the host unmounts', () => {
    const host = mountHost()
    host.unmount()
    pressG('i')
    expect(push).not.toHaveBeenCalled()
  })

  it('lets a pending G win over the bare "c" create-issue shortcut', () => {
    // G then C means "go to cycles". Before the handler order was fixed the
    // single-key create-issue shortcut swallowed it and G+C was unreachable.
    currentRoute.value = { path: '/team/ENG/active' }
    const ui = useUiStore()
    const openCreateIssue = vi.spyOn(ui, 'openCreateIssueModal')
    const host = mountHost()

    pressG('c')

    expect(push).toHaveBeenCalledWith('/team/ENG/cycles')
    expect(openCreateIssue).not.toHaveBeenCalled()
    host.unmount()
  })

  it('still opens the create-issue modal on a bare "c"', () => {
    const ui = useUiStore()
    const openCreateIssue = vi.spyOn(ui, 'openCreateIssueModal')
    const host = mountHost()

    press('c')

    expect(openCreateIssue).toHaveBeenCalled()
    expect(push).not.toHaveBeenCalled()
    host.unmount()
  })
})
