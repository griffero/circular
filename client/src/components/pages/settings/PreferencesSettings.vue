<script setup lang="ts">
import { computed, ref } from 'vue'
import { useUiStore } from '@/stores/ui'

const uiStore = useUiStore()

const defaultHomeView = ref('active-issues')
const displayFullNames = ref(false)
const firstDayOfWeek = ref('sunday')
const convertTextEmoticons = ref(true)
const interfaceTheme = computed({
  get: () => (uiStore.darkMode ? 'dark' : 'light'),
  set: (value: string) => {
    uiStore.darkMode = value === 'dark'
  }
})
const usePointerCursors = ref(false)
</script>

<template>
  <div class="p-8 max-w-2xl">
    <h1 class="text-xl font-semibold text-[var(--linear-text)] mb-8">
      Preferences
    </h1>

    <!-- General Section -->
    <section class="mb-10">
      <h2 class="text-[13px] font-medium text-[var(--linear-muted)] uppercase tracking-wider mb-4">
        General
      </h2>
      
      <div class="space-y-1">
        <!-- Default home view -->
        <div class="flex items-center justify-between py-3 border-b border-[var(--linear-border-subtle)]">
          <div>
            <p class="text-[14px] text-[var(--linear-text)]">Default home view</p>
            <p class="text-[13px] text-[var(--linear-muted)]">Select which view to display when launching</p>
          </div>
          <select 
            v-model="defaultHomeView"
            class="bg-[var(--linear-elevated)] border border-[var(--linear-border)] rounded px-3 py-1.5 text-[13px] text-[var(--linear-text)] focus:outline-none focus:border-[var(--linear-accent)]"
          >
            <option value="active-issues">Active issues</option>
            <option value="inbox">Inbox</option>
            <option value="my-issues">My issues</option>
          </select>
        </div>

        <!-- Display full names -->
        <div class="flex items-center justify-between py-3 border-b border-[var(--linear-border-subtle)]">
          <div>
            <p class="text-[14px] text-[var(--linear-text)]">Display full names</p>
            <p class="text-[13px] text-[var(--linear-muted)]">Show full names of users instead of shorter usernames</p>
          </div>
          <button 
            @click="displayFullNames = !displayFullNames"
            :class="[
              'relative w-10 h-6 rounded-full transition-colors',
              displayFullNames ? 'bg-[var(--linear-accent)]' : 'bg-[var(--linear-border)]'
            ]"
          >
            <span 
              :class="[
                'absolute top-1 w-4 h-4 rounded-full bg-white transition-transform',
                displayFullNames ? 'left-5' : 'left-1'
              ]"
            />
          </button>
        </div>

        <!-- First day of the week -->
        <div class="flex items-center justify-between py-3 border-b border-[var(--linear-border-subtle)]">
          <div>
            <p class="text-[14px] text-[var(--linear-text)]">First day of the week</p>
            <p class="text-[13px] text-[var(--linear-muted)]">Used for date pickers</p>
          </div>
          <select 
            v-model="firstDayOfWeek"
            class="bg-[var(--linear-elevated)] border border-[var(--linear-border)] rounded px-3 py-1.5 text-[13px] text-[var(--linear-text)] focus:outline-none focus:border-[var(--linear-accent)]"
          >
            <option value="sunday">Sunday</option>
            <option value="monday">Monday</option>
            <option value="saturday">Saturday</option>
          </select>
        </div>

        <!-- Convert text emoticons -->
        <div class="flex items-center justify-between py-3">
          <div>
            <p class="text-[14px] text-[var(--linear-text)]">Convert text emoticons into emojis</p>
            <p class="text-[13px] text-[var(--linear-muted)]">Strings like :) will be converted to emoji</p>
          </div>
          <button 
            @click="convertTextEmoticons = !convertTextEmoticons"
            :class="[
              'relative w-10 h-6 rounded-full transition-colors',
              convertTextEmoticons ? 'bg-[var(--linear-accent)]' : 'bg-[var(--linear-border)]'
            ]"
          >
            <span 
              :class="[
                'absolute top-1 w-4 h-4 rounded-full bg-white transition-transform',
                convertTextEmoticons ? 'left-5' : 'left-1'
              ]"
            />
          </button>
        </div>
      </div>
    </section>

    <!-- Interface and theme Section -->
    <section class="mb-10">
      <h2 class="text-[13px] font-medium text-[var(--linear-muted)] uppercase tracking-wider mb-4">
        Interface and theme
      </h2>
      
      <div class="space-y-1">
        <!-- Interface theme -->
        <div class="flex items-center justify-between py-3 border-b border-[var(--linear-border-subtle)]">
          <div>
            <p class="text-[14px] text-[var(--linear-text)]">Interface theme</p>
            <p class="text-[13px] text-[var(--linear-muted)]">Select your interface color scheme</p>
          </div>
          <select 
            v-model="interfaceTheme"
            class="bg-[var(--linear-elevated)] border border-[var(--linear-border)] rounded px-3 py-1.5 text-[13px] text-[var(--linear-text)] focus:outline-none focus:border-[var(--linear-accent)]"
          >
            <option value="light">Light</option>
            <option value="dark">Dark</option>
          </select>
        </div>

        <!-- Use pointer cursors -->
        <div class="flex items-center justify-between py-3">
          <div>
            <p class="text-[14px] text-[var(--linear-text)]">Use pointer cursors</p>
            <p class="text-[13px] text-[var(--linear-muted)]">Change the cursor to a pointer when hovering over interactive elements</p>
          </div>
          <button 
            @click="usePointerCursors = !usePointerCursors"
            :class="[
              'relative w-10 h-6 rounded-full transition-colors',
              usePointerCursors ? 'bg-[var(--linear-accent)]' : 'bg-[var(--linear-border)]'
            ]"
          >
            <span 
              :class="[
                'absolute top-1 w-4 h-4 rounded-full bg-white transition-transform',
                usePointerCursors ? 'left-5' : 'left-1'
              ]"
            />
          </button>
        </div>
      </div>
    </section>
  </div>
</template>
