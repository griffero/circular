<script setup lang="ts">
/**
 * Workflow-state icon, drawn with the geometry Linear uses.
 *
 * Measured from the running app (linear.app, dark theme, 2026-08-27): a 14x14
 * viewBox, an outer ring at r=6 / stroke-width 1.5, and an inner arc that is a
 * fat dashed stroke used as a pie fill. Backlog is the only dashed ring;
 * completed and cancelled states fill the circle and punch a glyph out of it in
 * the surrounding background colour.
 */
import { computed } from 'vue'
import type { WorkflowStateType } from '@/types'

const props = withDefaults(
  defineProps<{
    /** Workflow state name, e.g. "In Review". Drives the exact colour and fill. */
    name?: string | null
    type?: WorkflowStateType | null
    size?: number
    /** Background the check/cross glyph is punched out of. */
    glyphBg?: string
  }>(),
  { size: 14, glyphBg: 'var(--linear-elevated)' },
)

type Visual = {
  color: string
  dash: string
  dashOffset: number
  /** 0 = empty ring, 1 = solid */
  fill: number
  glyph?: 'check' | 'cross' | 'triage'
}

const SOLID_RING = { dash: '3.14 0', dashOffset: -0.7 }

/* Colours read off the live app, per state name. */
const BY_NAME: Record<string, Visual> = {
  Triage: { color: 'lch(66% 80 48)', dash: '2 0', dashOffset: 3.2, fill: 0, glyph: 'triage' },
  Backlog: { color: '#bec2c8', dash: '1.4 1.74', dashOffset: 0.65, fill: 0 },
  Icebox: { color: '#bec2c8', dash: '1.4 1.74', dashOffset: 0.65, fill: 0 },
  Todo: { color: '#e2e2e2', ...SOLID_RING, fill: 0 },
  'To do': { color: '#e2e2e2', ...SOLID_RING, fill: 0 },
  'This week': { color: '#e2e2e2', ...SOLID_RING, fill: 0 },
  Next: { color: '#e2e2e2', ...SOLID_RING, fill: 0 },
  Spec: { color: 'lch(80% 90 85)', ...SOLID_RING, fill: 0.25 },
  'In Progress': { color: 'lch(80% 90 85)', ...SOLID_RING, fill: 0.5 },
  'In Development': { color: 'lch(80% 90 85)', ...SOLID_RING, fill: 0.5 },
  'In Review': { color: '#f2994a', ...SOLID_RING, fill: 0.75 },
  Shipped: { color: '#f2994a', ...SOLID_RING, fill: 0.75 },
  Maintenance: { color: '#f2994a', ...SOLID_RING, fill: 0.75 },
  Staging: { color: '#26b5ce', ...SOLID_RING, fill: 1, glyph: 'check' },
  Production: { color: 'lch(60% 64.37 141.95)', ...SOLID_RING, fill: 1, glyph: 'check' },
  Done: { color: 'lch(60% 64.37 141.95)', ...SOLID_RING, fill: 1, glyph: 'check' },
  Completed: { color: 'lch(60% 64.37 141.95)', ...SOLID_RING, fill: 1, glyph: 'check' },
  Launched: { color: 'lch(60% 64.37 141.95)', ...SOLID_RING, fill: 1, glyph: 'check' },
  Canceled: { color: '#95a2b3', ...SOLID_RING, fill: 1, glyph: 'cross' },
  Duplicate: { color: '#95a2b3', ...SOLID_RING, fill: 1, glyph: 'cross' },
}

const BY_TYPE: Record<WorkflowStateType, Visual> = {
  triage: BY_NAME.Triage,
  backlog: BY_NAME.Backlog,
  unstarted: BY_NAME.Todo,
  started: BY_NAME['In Progress'],
  completed: BY_NAME.Done,
  canceled: BY_NAME.Canceled,
}

const CHECK =
  'M10.951 4.24896C11.283 4.58091 11.283 5.11909 10.951 5.45104L5.95104 10.451C5.61909 10.783 5.0809 10.783 4.74896 10.451L2.74896 8.45104C2.41701 8.11909 2.41701 7.5809 2.74896 7.24896C3.0809 6.91701 3.61909 6.91701 3.95104 7.24896L5.35 8.64792L9.74896 4.24896C10.0809 3.91701 10.6191 3.91701 10.951 4.24896Z'
const CROSS =
  'M3.73657 3.73657C4.05199 3.42114 4.56339 3.42114 4.87881 3.73657L5.93941 4.79716L7 5.85775L9.12117 3.73657C9.4366 3.42114 9.94801 3.42114 10.2634 3.73657C10.5789 4.05199 10.5789 4.56339 10.2634 4.87881L8.14225 7L10.2634 9.12118C10.5789 9.4366 10.5789 9.94801 10.2634 10.2634C9.94801 10.5789 9.4366 10.5789 9.12117 10.2634L7 8.14225L4.87881 10.2634C4.56339 10.5789 4.05199 10.5789 3.73657 10.2634C3.42114 9.94801 3.42114 9.4366 3.73657 9.12118L4.79716 8.06059L5.85775 7L3.73657 4.87881C3.42114 4.56339 3.42114 4.05199 3.73657 3.73657Z'
const TRIAGE =
  'M8.0126 7.98223V9.50781C8.0126 9.92901 8.52329 10.1548 8.85102 9.87854L11.8258 7.37066C12.0581 7.17486 12.0581 6.82507 11.8258 6.62927L8.85102 4.12139C8.52329 3.84509 8.0126 4.07092 8.0126 4.49212V6.01763H5.98739V4.49218C5.98739 4.07098 5.4767 3.84515 5.14897 4.12146L2.17419 6.62933C1.94194 6.82513 1.94194 7.17492 2.17419 7.37072L5.14897 9.8786C5.4767 10.1549 5.98739 9.92907 5.98739 9.50787V7.98223H8.0126Z'

const visual = computed<Visual>(
  () => (props.name ? BY_NAME[props.name] : undefined) ?? (props.type ? BY_TYPE[props.type] : undefined) ?? BY_NAME.Backlog,
)

const solid = computed(() => visual.value.fill >= 1)
const innerRadius = computed(() => (solid.value ? 3 : 2))
const innerWidth = computed(() => (solid.value ? 6 : 4))
const innerDash = computed(() => (solid.value ? 18.84955592153876 : 12.189379495928398))
const innerOffset = computed(() => innerDash.value * (1 - visual.value.fill))
const glyphPath = computed(() => {
  if (visual.value.glyph === 'check') return CHECK
  if (visual.value.glyph === 'cross') return CROSS
  if (visual.value.glyph === 'triage') return TRIAGE
  return null
})
</script>

<template>
  <svg :width="size" :height="size" viewBox="0 0 14 14" aria-hidden="true" focusable="false">
    <circle
      cx="7"
      cy="7"
      r="6"
      fill="none"
      :stroke="visual.color"
      stroke-width="1.5"
      :stroke-dasharray="visual.dash"
      :stroke-dashoffset="visual.dashOffset"
    />
    <circle
      cx="7"
      cy="7"
      :r="innerRadius"
      fill="none"
      :stroke="visual.color"
      :stroke-width="innerWidth"
      :stroke-dasharray="`${innerDash} ${innerDash * 2}`"
      :stroke-dashoffset="innerOffset"
      transform="rotate(-90 7 7)"
    />
    <path
      v-if="glyphPath"
      stroke="none"
      :fill="visual.glyph === 'triage' ? visual.color : glyphBg"
      :d="glyphPath"
    />
  </svg>
</template>
