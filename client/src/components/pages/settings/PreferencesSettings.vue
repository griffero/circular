<script setup lang="ts">
import { ref } from 'vue'
import { useUiStore } from '@/stores/ui'

const uiStore = useUiStore()

const defaultHomeView = ref('active-issues')
const displayFullNames = ref(false)
const firstDayOfWeek = ref('sunday')
const convertTextEmoticons = ref(true)
const interfaceTheme = ref('system')
const usePointerCursors = ref(false)
</script>

<template>
  <div class="p-8 max-w-2xl">
    <h1 class="text-xl font-semibold text-white mb-8">
      Preferences
    </h1>

    <!-- General Section -->
    <section class="mb-10">
      <h2 class="text-[13px] font-medium text-gray-400 uppercase tracking-wider mb-4">
        General
      </h2>
      
      <div class="space-y-1">
        <!-- Default home view -->
        <div class="flex items-center justify-between py-3 border-b border-[#222]">
          <div>
            <p class="text-[14px] text-white">Default home view</p>
            <p class="text-[13px] text-gray-500">Select which view to display when launching</p>
          </div>
          <select 
            v-model="defaultHomeView"
            class="bg-[#1a1a1a] border border-[#333] rounded px-3 py-1.5 text-[13px] text-white focus:outline-none focus:border-indigo-500"
          >
            <option value="active-issues">Active issues</option>
            <option value="inbox">Inbox</option>
            <option value="my-issues">My issues</option>
          </select>
        </div>

        <!-- Display full names -->
        <div class="flex items-center justify-between py-3 border-b border-[#222]">
          <div>
            <p class="text-[14px] text-white">Display full names</p>
            <p class="text-[13px] text-gray-500">Show full names of users instead of shorter usernames</p>
          </div>
          <button 
            @click="displayFullNames = !displayFullNames"
            :class="[
              'relative w-10 h-6 rounded-full transition-colors',
              displayFullNames ? 'bg-indigo-600' : 'bg-[#333]'
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
        <div class="flex items-center justify-between py-3 border-b border-[#222]">
          <div>
            <p class="text-[14px] text-white">First day of the week</p>
            <p class="text-[13px] text-gray-500">Used for date pickers</p>
          </div>
          <select 
            v-model="firstDayOfWeek"
            class="bg-[#1a1a1a] border border-[#333] rounded px-3 py-1.5 text-[13px] text-white focus:outline-none focus:border-indigo-500"
          >
            <option value="sunday">Sunday</option>
            <option value="monday">Monday</option>
            <option value="saturday">Saturday</option>
          </select>
        </div>

        <!-- Convert text emoticons -->
        <div class="flex items-center justify-between py-3">
          <div>
            <p class="text-[14px] text-white">Convert text emoticons into emojis</p>
            <p class="text-[13px] text-gray-500">Strings like :) will be converted to emoji</p>
          </div>
          <button 
            @click="convertTextEmoticons = !convertTextEmoticons"
            :class="[
              'relative w-10 h-6 rounded-full transition-colors',
              convertTextEmoticons ? 'bg-indigo-600' : 'bg-[#333]'
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
      <h2 class="text-[13px] font-medium text-gray-400 uppercase tracking-wider mb-4">
        Interface and theme
      </h2>
      
      <div class="space-y-1">
        <!-- Interface theme -->
        <div class="flex items-center justify-between py-3 border-b border-[#222]">
          <div>
            <p class="text-[14px] text-white">Interface theme</p>
            <p class="text-[13px] text-gray-500">Select or customize your interface color scheme</p>
          </div>
          <select 
            v-model="interfaceTheme"
            class="bg-[#1a1a1a] border border-[#333] rounded px-3 py-1.5 text-[13px] text-white focus:outline-none focus:border-indigo-500"
          >
            <option value="system">System preference</option>
            <option value="light">Light</option>
            <option value="dark">Dark</option>
          </select>
        </div>

        <!-- Use pointer cursors -->
        <div class="flex items-center justify-between py-3">
          <div>
            <p class="text-[14px] text-white">Use pointer cursors</p>
            <p class="text-[13px] text-gray-500">Change the cursor to a pointer when hovering over any interactive elements</p>
          </div>
          <button 
            @click="usePointerCursors = !usePointerCursors"
            :class="[
              'relative w-10 h-6 rounded-full transition-colors',
              usePointerCursors ? 'bg-indigo-600' : 'bg-[#333]'
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
