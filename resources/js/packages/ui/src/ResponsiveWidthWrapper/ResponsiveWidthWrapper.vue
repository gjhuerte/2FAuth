<script setup>
    const props = defineProps({
        isActive: {
            type: Boolean,
            default: true
        },
        isCompact: {
            type: Boolean,
            default: false
        },
        isWide: {
            type: Boolean,
            default: false
        },
    })
</script>

<template>
    <div
        v-if="isActive"
        class="mx-auto w-full px-4 sm:px-6"
        :class="[isCompact ? 'pt-3' : 'pt-8 sm:pt-12', isWide ? 'max-w-5xl' : 'max-w-3xl']"
    >
        <slot />
    </div>
    <slot v-else />
</template>
