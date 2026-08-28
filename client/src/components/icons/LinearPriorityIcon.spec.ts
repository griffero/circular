import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import LinearPriorityIcon from './LinearPriorityIcon.vue'
import type { IssuePriority } from '@/types'

const mountIcon = (priority: IssuePriority, size?: number) =>
  mount(LinearPriorityIcon, { props: size === undefined ? { priority } : { priority, size } })

/** [short, medium, tall] bar opacities, in the order Linear draws them. */
function barOpacities(priority: IssuePriority): number[] {
  return mountIcon(priority)
    .findAll('rect')
    .map((r) => Number(r.attributes('fill-opacity') ?? 1))
}

describe('LinearPriorityIcon', () => {
  it('reserves the slot at "no priority" instead of collapsing it', () => {
    // Linear keeps the column so the identifier next to it cannot shift.
    const none = mountIcon(0)
    expect(none.findAll('rect')).toHaveLength(3)
    expect(none.attributes('width')).toBe('16')
  })

  it('draws "no priority" as three flat dashes, not bars', () => {
    const rects = mountIcon(0).findAll('rect')
    expect(rects.map((r) => r.attributes('height'))).toEqual(['1.5', '1.5', '1.5'])
    // all three sit on the same baseline
    expect(new Set(rects.map((r) => r.attributes('y'))).size).toBe(1)
  })

  it('draws urgent as a filled square, not bars', () => {
    const urgent = mountIcon(1)
    expect(urgent.findAll('rect')).toHaveLength(0)
    expect(urgent.find('path').attributes('fill')).toBe('#f2994a')
  })

  it.each([
    [2, 'High', [1, 1, 1]],
    [3, 'Medium', [1, 1, 0.4]],
    [4, 'Low', [1, 0.4, 0.4]],
  ])('dims the tallest bars first: priority %s (%s)', (priority, _label, expected) => {
    expect(barOpacities(priority as IssuePriority)).toEqual(expected)
  })

  it('steps the bars up in height from left to right', () => {
    const heights = mountIcon(2)
      .findAll('rect')
      .map((r) => Number(r.attributes('height')))
    expect(heights).toEqual([6, 9, 12])
    expect(heights[0]).toBeLessThan(heights[1])
    expect(heights[1]).toBeLessThan(heights[2])
  })

  it('places the bars on the measured 1.5 / 6.5 / 11.5 grid', () => {
    const xs = mountIcon(2)
      .findAll('rect')
      .map((r) => r.attributes('x'))
    expect(xs).toEqual(['1.5', '6.5', '11.5'])
  })

  it('inherits the surrounding text colour so it can be themed by context', () => {
    expect(mountIcon(2).attributes('fill')).toBe('currentColor')
  })

  it('honours an explicit size without changing the viewBox', () => {
    const sized = mountIcon(2, 24)
    expect(sized.attributes('width')).toBe('24')
    expect(sized.attributes('height')).toBe('24')
    expect(sized.attributes('viewBox')).toBe('0 0 16 16')
  })

  it('is hidden from assistive tech — priority is labelled in text alongside', () => {
    const w = mountIcon(2)
    expect(w.attributes('aria-hidden')).toBe('true')
    expect(w.attributes('focusable')).toBe('false')
  })

  it('renders every priority level without throwing', () => {
    for (const p of [0, 1, 2, 3, 4] as IssuePriority[]) {
      expect(mountIcon(p).find('svg').exists()).toBe(true)
    }
  })
})
