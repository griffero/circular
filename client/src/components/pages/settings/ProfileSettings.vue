<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { api } from '@/api/client'
import Button from '@/components/ui/Button.vue'
import type { User } from '@/types'

const authStore = useAuthStore()
const user = computed(() => authStore.user)

const fullName = ref(user.value?.name || '')
const displayName = ref(user.value?.displayName || '')
const timezone = ref(user.value?.timezone || 'UTC')
const saving = ref(false)
const saveError = ref('')
const saveSuccess = ref(false)

watch(user, (nextUser) => {
  fullName.value = nextUser?.name || ''
  displayName.value = nextUser?.displayName || ''
  timezone.value = nextUser?.timezone || 'UTC'
}, { immediate: true })

async function handleSave() {
  if (!user.value) return

  saving.value = true
  saveError.value = ''
  saveSuccess.value = false

  try {
    const payload = {
      user: {
        name: fullName.value.trim(),
        displayName: displayName.value.trim() || null,
        timezone: timezone.value.trim() || 'UTC',
      },
    }

    const response = await api.patch<{ user: User }>(`/api/v1/users/${user.value.id}`, payload)
    if (response.user) {
      authStore.setCurrentUser(response.user)
      saveSuccess.value = true
    }
  } catch (err) {
    saveError.value = err instanceof Error ? err.message : 'Failed to update profile'
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div class="p-8 max-w-2xl">
    <h1 class="text-xl font-semibold text-[var(--linear-text)] mb-8">
      Profile
    </h1>

    <form @submit.prevent="handleSave" class="space-y-6">
      <div
        v-if="saveError"
        class="p-3 rounded-lg border border-red-500/40 bg-red-500/10 text-sm text-red-300"
      >
        {{ saveError }}
      </div>

      <div
        v-if="saveSuccess"
        class="p-3 rounded-lg border border-emerald-500/40 bg-emerald-500/10 text-sm text-emerald-300"
      >
        Profile updated.
      </div>

      <!-- Avatar -->
      <div class="flex items-center gap-4 pb-6 border-b border-[var(--linear-border)]">
        <div class="w-16 h-16 rounded-full bg-[var(--linear-accent)]/80 flex items-center justify-center">
          <span class="text-2xl font-medium text-white">
            {{ user?.name?.charAt(0)?.toUpperCase() || '?' }}
          </span>
        </div>
        <div>
          <Button
            type="button"
            variant="secondary"
            size="sm"
            disabled
          >
            Upload photo
          </Button>
          <p class="mt-1 text-[12px] text-[var(--linear-muted)]">
            Avatar upload is not available in this slice.
          </p>
        </div>
      </div>

      <!-- Full name -->
      <div>
        <label class="block text-[14px] text-[var(--linear-text)] mb-2">
          Full name
        </label>
        <input
          v-model="fullName"
          type="text"
          class="w-full bg-[var(--linear-elevated)] border border-[var(--linear-border)] rounded px-3 py-2 text-[14px] text-[var(--linear-text)] placeholder-[var(--linear-muted)] focus:outline-none focus:border-[var(--linear-accent)]"
          placeholder="Your full name"
        />
      </div>

      <!-- Display name -->
      <div>
        <label class="block text-[14px] text-[var(--linear-text)] mb-2">
          Display name
        </label>
        <input
          v-model="displayName"
          type="text"
          class="w-full bg-[var(--linear-elevated)] border border-[var(--linear-border)] rounded px-3 py-2 text-[14px] text-[var(--linear-text)] placeholder-[var(--linear-muted)] focus:outline-none focus:border-[var(--linear-accent)]"
          placeholder="Display name"
        />
        <p class="mt-1 text-[12px] text-[var(--linear-muted)]">
          This could be your first name, or a nickname
        </p>
      </div>

      <!-- Timezone -->
      <div>
        <label class="block text-[14px] text-[var(--linear-text)] mb-2">
          Timezone
        </label>
        <input
          v-model="timezone"
          type="text"
          class="w-full bg-[var(--linear-elevated)] border border-[var(--linear-border)] rounded px-3 py-2 text-[14px] text-[var(--linear-text)] placeholder-[var(--linear-muted)] focus:outline-none focus:border-[var(--linear-accent)]"
          placeholder="UTC"
        />
      </div>

      <!-- Email (read-only) -->
      <div>
        <label class="block text-[14px] text-[var(--linear-text)] mb-2">
          Email
        </label>
        <input
          :value="user?.email"
          type="email"
          disabled
          class="w-full bg-[var(--linear-surface)] border border-[var(--linear-border)] rounded px-3 py-2 text-[14px] text-[var(--linear-muted)] cursor-not-allowed"
        />
      </div>

      <!-- Save button -->
      <div class="pt-4">
        <Button
          type="submit"
          :loading="saving"
          :disabled="saving"
        >
          Save changes
        </Button>
      </div>
    </form>
  </div>
</template>
