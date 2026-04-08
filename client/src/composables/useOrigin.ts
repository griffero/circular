export function isFromLinear(entity: { linearId?: string }): boolean {
  return !!entity.linearId
}

export function isCircularNative(entity: { linearId?: string }): boolean {
  return !entity.linearId
}

export function isEditable(entity: { linearId?: string }): boolean {
  return isCircularNative(entity)
}
