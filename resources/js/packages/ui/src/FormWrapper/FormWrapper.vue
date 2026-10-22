<script setup>
    const props = defineProps({
        title: {
            type: String,
            default: ''
        },
        punchline: {
            type: String,
            default: ''
        },
    })
</script>

<template>
    <ResponsiveWidthWrapper>
        <div class="animate-enter">
            <h1 v-if="title" class="md-page-title">
                {{ $t(title) }}
            </h1>
            <p v-if="punchline" id="punchline" class="mt-3 max-w-prose text-body leading-relaxed text-md-on-surface-variant">
                {{ $t(punchline) }}
            </p>
            <div :class="{ 'mt-8': title || punchline }">
                <slot />
            </div>
        </div>
    </ResponsiveWidthWrapper>
</template>
