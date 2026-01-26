<script setup lang="ts">
import { ref, watch } from 'vue'
import Modal from '@/components/ui/Modal.vue'
import Button from '@/components/ui/Button.vue'
import Input from '@/components/ui/Input.vue'

const props = defineProps<{
  open: boolean
}>()

const emit = defineEmits<{
  (e: 'close'): void
  (e: 'created', initiative: unknown): void
}>()

const name = ref('')
const description = ref('')
const creating = ref(false)
const error = ref('')

watch(() => props.open, (open) => {
  if (open) {
    name.value = ''
    description.value = ''
    error.value = ''
  }
})

async function handleSubmit() {
  if (!name.value.trim()) return

  creating.value = true
  error.value = ''

  try {
    // TODO: Implement API call when backend supports initiatives
    // For now, show a message that this feature is coming soon
    error.value = 'Initiatives feature coming soon!'
    creating.value = false
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Failed to create initiative'
    creating.value = false
  }
}
</script>

<template>
  <Modal :open="open" @close="emit('close')" size="md" title="Create initiative">
    <form @submit.prevent="handleSubmit" class="space-y-4">
      <div v-if="error" class="p-3 bg-yellow-900/20 border border-yellow-800 rounded-lg text-sm text-yellow-400">
        {{ error }}
      </div>

      <div>
        <label class="block text-xs font-medium text-gray-400 mb-1">Initiative name</label>
        <Input
          v-model="name"
          type="text"
          placeholder="e.g. Q1 Goals"
          required
          autofocus
        />
      </div>

      <div>
        <label class="block text-xs font-medium text-gray-400 mb-1">Description</label>
        <textarea
          v-model="description"
          rows="3"
          placeholder="What is this initiative about?"
          class="w-full px-3 py-2 text-sm rounded-md border border-gray-700 bg-gray-800 text-gray-100 placeholder-gray-500 focus:ring-2 focus:ring-indigo-500 focus:border-transparent resize-none"
        />
      </div>

      <div class="flex justify-end gap-3 pt-4 border-t border-gray-700">
        <Button type="button" variant="ghost" @click="emit('close')">
          Cancel
        </Button>
        <Button type="submit" :loading="creating" :disabled="!name.trim()">
          Create initiative
        </Button>
      </div>
    </form>
  </Modal>
</template>
