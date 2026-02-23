<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import Button from '@/components/ui/Button.vue'
import Input from '@/components/ui/Input.vue'
import { Mail, ArrowRight, CheckCircle, Loader2 } from 'lucide-vue-next'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const email = ref('')
const error = ref('')
const loading = ref(false)
const emailSent = ref(false)

onMounted(async () => {
  // Handle token login from URL (e.g., magic link)
  const token = route.query.token as string
  if (token) {
    loading.value = true
    try {
      await authStore.tokenLogin(token)
      router.replace('/')
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Invalid token'
    } finally {
      loading.value = false
    }
  }
})

async function handleSubmit() {
  error.value = ''
  loading.value = true

  try {
    await authStore.sendMagicLink(email.value)
    emailSent.value = true
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Failed to send magic link'
  } finally {
    loading.value = false
  }
}

function resetForm() {
  emailSent.value = false
  error.value = ''
}
</script>

<template>
  <div class="min-h-screen bg-[var(--linear-bg)] flex items-center justify-center px-4">

    <div class="relative w-full max-w-md">
      <div class="linear-panel p-8 shadow-2xl">
        <!-- Logo / Header -->
        <div class="text-center mb-8">
          <div class="inline-flex items-center justify-center w-14 h-14 rounded-xl bg-[var(--linear-accent)] text-white text-2xl font-bold mb-5">
            ◐
          </div>
          <h1 class="text-2xl font-semibold text-[var(--linear-text)] tracking-tight">
            {{ emailSent ? 'Check your email' : 'Welcome to Circular' }}
          </h1>
          <p class="mt-2 text-sm text-[var(--linear-muted)]">
            {{ emailSent ? `We sent a magic link to ${email}` : 'Enter your email to sign in or create an account' }}
          </p>
        </div>

        <!-- Success State -->
        <div v-if="emailSent" class="space-y-6">
          <div class="flex flex-col items-center py-6">
            <div class="w-16 h-16 rounded-full bg-emerald-500/10 flex items-center justify-center mb-4 border border-emerald-500/20">
              <CheckCircle class="w-8 h-8 text-emerald-400" />
            </div>
            <p class="text-[var(--linear-muted)] text-center text-sm leading-relaxed max-w-xs">
              Click the link in your email to sign in. The link will expire in 15 minutes.
            </p>
          </div>

          <div class="space-y-3">
            <Button 
              variant="ghost" 
              class="w-full" 
              @click="resetForm"
            >
              Use a different email
            </Button>
          </div>
        </div>

        <!-- Form -->
        <form v-else @submit.prevent="handleSubmit" class="space-y-5">
          <div 
            v-if="error" 
            class="p-3 bg-red-500/10 border border-red-500/20 rounded-lg text-sm text-red-300"
          >
            {{ error }}
          </div>

          <div>
            <label for="email" class="block text-sm font-medium text-[var(--linear-text)] mb-2">
              Email address
            </label>
            <div class="relative">
              <Mail class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-[var(--linear-muted)]" />
              <Input
                id="email"
                v-model="email"
                type="email"
                placeholder="you@company.com"
                required
                autocomplete="email"
                class="pl-11"
              />
            </div>
          </div>

          <Button 
            type="submit" 
            :disabled="loading || !email" 
            class="w-full"
          >
            <Loader2 v-if="loading" class="w-4 h-4 mr-2 animate-spin" />
            <span v-else class="flex items-center justify-center gap-2">
              Continue with Email
              <ArrowRight class="w-4 h-4" />
            </span>
          </Button>
        </form>

        <!-- Footer -->
        <p class="mt-8 text-center text-xs text-[var(--linear-muted)]">
          By continuing, you agree to our Terms of Service and Privacy Policy
        </p>
      </div>
    </div>
  </div>
</template>
