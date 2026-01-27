<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import Avatar from './Avatar.vue'

interface Props {
  userId: string
  name: string
  email?: string
  avatarUrl?: string | null
  displayName?: string | null
  showAvatar?: boolean
  avatarSize?: 'xs' | 'sm' | 'md' | 'lg'
  showName?: boolean
  class?: string
}

const props = withDefaults(defineProps<Props>(), {
  showAvatar: true,
  avatarSize: 'sm',
  showName: true
})

const router = useRouter()

const displayedName = computed(() => props.displayName || props.name)

function goToProfile() {
  router.push(`/profile/${props.userId}`)
}
</script>

<template>
  <button
    @click.stop="goToProfile"
    :class="[
      'inline-flex items-center gap-1.5 hover:text-white transition-colors',
      props.class
    ]"
  >
    <Avatar
      v-if="showAvatar"
      :name="name"
      :src="avatarUrl"
      :size="avatarSize"
    />
    <span v-if="showName" class="hover:underline">{{ displayedName }}</span>
  </button>
</template>
