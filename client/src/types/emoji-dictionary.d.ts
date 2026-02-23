declare module 'emoji-dictionary' {
  const emojiDictionary: {
    getUnicode: (name: string) => string | null
  }

  export default emojiDictionary
}
