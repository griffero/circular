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
  <div class="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 flex items-center justify-center px-4">
    <!-- Subtle grid pattern -->
    <div class="absolute inset-0 bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAiIGhlaWdodD0iNDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PGRlZnM+PHBhdHRlcm4gaWQ9ImdyaWQiIHdpZHRoPSI0MCIgaGVpZ2h0PSI0MCIgcGF0dGVyblVuaXRzPSJ1c2VyU3BhY2VPblVzZSI+PHBhdGggZD0iTSAwIDEwIEwgNDAgMTAgTSAxMCAwIEwgMTAgNDAgTSAwIDIwIEwgNDAgMjAgTSAyMCAwIEwgMjAgNDAgTSAwIDMwIEwgNDAgMzAgTSAzMCAwIEwgMzAgNDAiIGZpbGw9Im5vbmUiIHN0cm9rZT0icmdiYSgyNTUsMjU1LDI1NSwwLjAyKSIgc3Ryb2tlLXdpZHRoPSIxIi8+PC9wYXR0ZXJuPjwvZGVmcz48cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBmaWxsPSJ1cmwoI2dyaWQpIi8+PC9zdmc+')] opacity-40" />

    <div class="relative w-full max-w-md">
      <!-- Card -->
      <div class="bg-slate-800/50 backdrop-blur-xl border border-slate-700/50 rounded-2xl p-8 shadow-2xl">
        <!-- Logo / Header -->
        <div class="text-center mb-8">
          <div class="inline-flex items-center justify-center w-14 h-14 rounded-xl bg-gradient-to-br from-indigo-500 to-purple-600 text-white text-2xl font-bold mb-5 shadow-lg shadow-indigo-500/25">
            ◐
          </div>
          <h1 class="text-2xl font-semibold text-white tracking-tight">
            {{ emailSent ? 'Check your email' : 'Welcome to Circular' }}
          </h1>
          <p class="mt-2 text-sm text-slate-400">
            {{ emailSent ? `We sent a magic link to ${email}` : 'Enter your email to sign in or create an account' }}
          </p>
        </div>

        <!-- Success State -->
        <div v-if="emailSent" class="space-y-6">
          <div class="flex flex-col items-center py-6">
            <div class="w-16 h-16 rounded-full bg-emerald-500/10 flex items-center justify-center mb-4">
              <CheckCircle class="w-8 h-8 text-emerald-400" />
            </div>
            <p class="text-slate-300 text-center text-sm leading-relaxed max-w-xs">
              Click the link in your email to sign in. The link will expire in 15 minutes.
            </p>
          </div>

          <div class="space-y-3">
            <Button 
              variant="ghost" 
              class="w-full text-slate-400 hover:text-white" 
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
            class="p-3 bg-red-500/10 border border-red-500/20 rounded-lg text-sm text-red-400"
          >
            {{ error }}
          </div>

          <div>
            <label for="email" class="block text-sm font-medium text-slate-300 mb-2">
              Email address
            </label>
            <div class="relative">
              <Mail class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-500" />
              <Input
                id="email"
                v-model="email"
                type="email"
                placeholder="you@company.com"
                required
                autocomplete="email"
                class="pl-11 bg-slate-900/50 border-slate-600/50 text-white placeholder:text-slate-500 focus:border-indigo-500 focus:ring-indigo-500/20"
              />
            </div>
          </div>

          <Button 
            type="submit" 
            :disabled="loading || !email" 
            class="w-full bg-gradient-to-r from-indigo-500 to-purple-600 hover:from-indigo-600 hover:to-purple-700 text-white font-medium py-2.5 rounded-lg transition-all duration-200 shadow-lg shadow-indigo-500/25 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Loader2 v-if="loading" class="w-4 h-4 mr-2 animate-spin" />
            <span v-else class="flex items-center justify-center gap-2">
              Continue with Email
              <ArrowRight class="w-4 h-4" />
            </span>
          </Button>
        </form>

        <!-- Footer -->
        <p class="mt-8 text-center text-xs text-slate-500">
          By continuing, you agree to our Terms of Service and Privacy Policy
        </p>
      </div>

      <!-- Decorative elements -->
      <div class="absolute -top-20 -right-20 w-40 h-40 bg-purple-500/20 rounded-full blur-3xl" />
      <div class="absolute -bottom-20 -left-20 w-40 h-40 bg-indigo-500/20 rounded-full blur-3xl" />
    </div>
  </div>
</template>
