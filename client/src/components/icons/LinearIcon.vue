<script setup lang="ts">
import { computed } from 'vue'
import { linearIconMap, type LinearIconName } from './linearIconMap'

const props = defineProps<{
  name: LinearIconName
}>()

const icon = computed(() => linearIconMap[props.name])
</script>

<template>
  <svg
    v-if="icon"
    :viewBox="icon.viewBox"
    :width="icon.width"
    :height="icon.height"
    fill="currentColor"
    aria-hidden="true"
    focusable="false"
    v-html="icon.body"
  />
</template>
