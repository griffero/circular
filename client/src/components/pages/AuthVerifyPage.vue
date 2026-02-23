<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { Loader2, CheckCircle, XCircle } from 'lucide-vue-next'
import Button from '@/components/ui/Button.vue'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const status = ref<'loading' | 'success' | 'error'>('loading')
const error = ref('')

onMounted(async () => {
  const token = route.query.token as string

  if (!token) {
    status.value = 'error'
    error.value = 'No token provided'
    return
  }

  try {
    await authStore.verifyMagicLink(token)
    status.value = 'success'
    
    // Redirect to home after a short delay
    setTimeout(() => {
      router.replace('/')
    }, 1500)
  } catch (err) {
    status.value = 'error'
    error.value = err instanceof Error ? err.message : 'Invalid or expired magic link'
  }
})
</script>

<template>
  <div class="min-h-screen bg-[var(--linear-bg)] flex items-center justify-center px-4">

    <div class="relative w-full max-w-md">
      <div class="linear-panel p-8 shadow-2xl">
        <!-- Logo -->
        <div class="text-center mb-8">
          <div class="inline-flex items-center justify-center w-14 h-14 rounded-xl bg-[var(--linear-accent)] text-white text-2xl font-bold mb-5">
            ◐
          </div>
        </div>

        <!-- Loading State -->
        <div v-if="status === 'loading'" class="text-center py-8">
          <Loader2 class="w-12 h-12 text-[var(--linear-accent)] animate-spin mx-auto mb-4" />
          <h2 class="text-xl font-semibold text-[var(--linear-text)] mb-2">Verifying your link</h2>
          <p class="text-[var(--linear-muted)] text-sm">Please wait while we sign you in...</p>
        </div>

        <!-- Success State -->
        <div v-else-if="status === 'success'" class="text-center py-8">
          <div class="w-16 h-16 rounded-full bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center mx-auto mb-4">
            <CheckCircle class="w-8 h-8 text-emerald-400" />
          </div>
          <h2 class="text-xl font-semibold text-[var(--linear-text)] mb-2">You're signed in!</h2>
          <p class="text-[var(--linear-muted)] text-sm">Redirecting you to the app...</p>
        </div>

        <!-- Error State -->
        <div v-else class="text-center py-8">
          <div class="w-16 h-16 rounded-full bg-red-500/10 border border-red-500/20 flex items-center justify-center mx-auto mb-4">
            <XCircle class="w-8 h-8 text-red-400" />
          </div>
          <h2 class="text-xl font-semibold text-[var(--linear-text)] mb-2">Link expired or invalid</h2>
          <p class="text-[var(--linear-muted)] text-sm mb-6">{{ error }}</p>
          
          <Button 
            @click="router.push('/login')"
            class="px-6"
          >
            Request new link
          </Button>
        </div>
      </div>
    </div>
  </div>
</template>
