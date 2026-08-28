import { describe, it, expect, beforeEach } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useEmojiStore } from './emoji'

/**
 * getUnicodeEmoji decides "is this string itself already an emoji?" by checking
 * every code point. A ZWJ sequence like 🧑‍💻 is several code points joined by
 * U+200D, so the check has to pass per code point rather than per grapheme.
 */
describe('emoji store — unicode detection', () => {
  beforeEach(() => setActivePinia(createPinia()))

  it.each([
    ['👍', 'a single pictograph'],
    ['🎉', 'another single pictograph'],
    ['❤️', 'a pictograph plus variation selector'],
    ['👍🏽', 'a pictograph plus skin-tone modifier'],
    ['🧑‍💻', 'a ZWJ sequence'],
    ['🇨🇱', 'a regional-indicator pair'],
  ])('accepts %s (%s)', (value) => {
    expect(useEmojiStore().getUnicodeEmoji(value)).toBe(value)
  })

  it.each([
    ['a'],
    ['abc'],
    ['café'],
    ['project'],
    [':tada:'],
  ])('does not treat plain text %s as an emoji', (value) => {
    expect(useEmojiStore().getUnicodeEmoji(value)).not.toBe(value)
  })

  it('handles empty and nullish input', () => {
    const store = useEmojiStore()
    expect(store.getUnicodeEmoji('')).toBeNull()
    expect(store.getUnicodeEmoji(null)).toBeNull()
    expect(store.getUnicodeEmoji(undefined)).toBeNull()
  })

  it('rejects a long run of emoji rather than accepting anything pictographic', () => {
    // the length guard exists so a whole sentence of emoji is not mistaken for an icon
    expect(useEmojiStore().getUnicodeEmoji('😀😀😀😀😀😀😀😀')).toBeNull()
  })

  it('reports renderability consistently with detection', () => {
    const store = useEmojiStore()
    expect(store.isRenderableEmoji('👍')).toBe(true)
    expect(store.isRenderableEmoji('not-an-emoji')).toBe(false)
    expect(store.isRenderableEmoji(null)).toBe(false)
  })
})
