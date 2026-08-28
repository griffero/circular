import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import LinearStatusIcon from './LinearStatusIcon.vue'

/**
 * These lock in the measurements recorded in docs/linear-parity-measurements.md.
 * If a value here changes, the icon has drifted away from the real Linear glyph
 * and the doc needs re-measuring — not the test loosening.
 */

const ring = (w: ReturnType<typeof mount>) => w.findAll('circle')[0]
const pie = (w: ReturnType<typeof mount>) => w.findAll('circle')[1]
const mountIcon = (props: Record<string, unknown>) => mount(LinearStatusIcon, { props })

/** Fraction of the pie that is painted, derived from the dash offset. */
function filledFraction(w: ReturnType<typeof mount>): number {
  const el = pie(w)
  const dash = Number(el.attributes('stroke-dasharray')!.split(' ')[0])
  const offset = Number(el.attributes('stroke-dashoffset'))
  return Number((1 - offset / dash).toFixed(3))
}

describe('LinearStatusIcon', () => {
  it('draws the measured outer ring geometry', () => {
    const w = mountIcon({ name: 'Todo' })
    expect(ring(w).attributes('r')).toBe('6')
    expect(ring(w).attributes('stroke-width')).toBe('1.5')
    expect(w.attributes('viewBox')).toBe('0 0 14 14')
  })

  it('defaults to a 14px box and honours an explicit size', () => {
    expect(mountIcon({ name: 'Todo' }).attributes('width')).toBe('14')
    const sized = mountIcon({ name: 'Todo', size: 20 })
    expect(sized.attributes('width')).toBe('20')
    expect(sized.attributes('height')).toBe('20')
    // the viewBox never changes, so the glyph scales rather than reflows
    expect(sized.attributes('viewBox')).toBe('0 0 14 14')
  })

  it('dashes the ring for Backlog and only for Backlog', () => {
    expect(ring(mountIcon({ name: 'Backlog' })).attributes('stroke-dasharray')).toBe('1.4 1.74')
    expect(ring(mountIcon({ name: 'Todo' })).attributes('stroke-dasharray')).toBe('3.14 0')
    expect(ring(mountIcon({ name: 'In Progress' })).attributes('stroke-dasharray')).toBe('3.14 0')
  })

  it.each([
    ['Backlog', 0],
    ['Todo', 0],
    ['Spec', 0.25],
    ['In Progress', 0.5],
    ['In Review', 0.75],
    ['Done', 1],
  ])('fills %s to %s of the pie', (name, fraction) => {
    expect(filledFraction(mountIcon({ name }))).toBeCloseTo(fraction, 3)
  })

  it('switches to the solid inner disc once a state is complete', () => {
    // partial states use r=2/stroke=4; solid ones use r=3/stroke=6
    const partial = pie(mountIcon({ name: 'In Progress' }))
    expect(partial.attributes('r')).toBe('2')
    expect(partial.attributes('stroke-width')).toBe('4')

    const solid = pie(mountIcon({ name: 'Done' }))
    expect(solid.attributes('r')).toBe('3')
    expect(solid.attributes('stroke-width')).toBe('6')
  })

  it('punches the check and cross out of the disc in the background colour', () => {
    const done = mountIcon({ name: 'Done', glyphBg: 'rebeccapurple' })
    expect(done.find('path').exists()).toBe(true)
    expect(done.find('path').attributes('fill')).toBe('rebeccapurple')

    const canceled = mountIcon({ name: 'Canceled', glyphBg: 'rebeccapurple' })
    expect(canceled.find('path').attributes('fill')).toBe('rebeccapurple')

    // the two glyphs are genuinely different shapes
    expect(done.find('path').attributes('d')).not.toBe(canceled.find('path').attributes('d'))
  })

  it('draws the triage arrows in the state colour, not the background', () => {
    const w = mountIcon({ name: 'Triage', glyphBg: 'rebeccapurple' })
    const fill = w.find('path').attributes('fill')
    expect(fill).not.toBe('rebeccapurple')
    expect(fill).toBe(ring(w).attributes('stroke'))
  })

  it('leaves states with no glyph as a bare ring and pie', () => {
    expect(mountIcon({ name: 'In Progress' }).find('path').exists()).toBe(false)
  })

  it.each([
    ['Done', 'Completed'],
    ['Done', 'Launched'],
    ['Canceled', 'Duplicate'],
    ['Backlog', 'Icebox'],
    ['Todo', 'Next'],
  ])('renders %s and its alias %s identically', (a, b) => {
    expect(mountIcon({ name: b }).html()).toBe(mountIcon({ name: a }).html())
  })

  it('falls back to stateType when the name is unknown', () => {
    const byType = mountIcon({ name: 'Some Custom State', type: 'started' })
    expect(byType.html()).toBe(mountIcon({ name: 'In Progress' }).html())
  })

  it('falls back to Backlog when it knows neither name nor type', () => {
    expect(mountIcon({}).html()).toBe(mountIcon({ name: 'Backlog' }).html())
    expect(mountIcon({ name: null, type: null }).html()).toBe(mountIcon({ name: 'Backlog' }).html())
  })

  it('is hidden from assistive tech — the state is already named in text', () => {
    const w = mountIcon({ name: 'Done' })
    expect(w.attributes('aria-hidden')).toBe('true')
    expect(w.attributes('focusable')).toBe('false')
  })
})
