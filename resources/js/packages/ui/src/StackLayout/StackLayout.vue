<script setup>

    const props = defineProps({
        isVerticalCentered: {
            type: Boolean,
            default: false
        },
        shouldGrow: {
            type: Boolean,
            default: true
        },
        shouldShrinkSubheader: {
            type: Boolean,
            default: false
        },
    })
</script>

<template>
    <div class="stack flex flex-col" :class="{ 'h-dvh': shouldGrow }">
        <div v-if="$slots.header" class="stack-header shrink-0">
            <slot name="header" />
        </div>
        <div v-if="$slots.subheader" class="stack-subheader min-h-8" :class="{ 'shrink-0' : shouldShrinkSubheader }">
            <slot name="subheader" />
        </div>
        <div
            v-if="$slots.content"
            class="stack-content-wrapper overflow-y-auto"
            :class="{ 'flex flex-col justify-center': isVerticalCentered, 'flex-1': shouldGrow }"
        >
            <div class="stack-content px-4 lg:px-0">
                <slot name="content" />
            </div>
        </div>
        <div v-if="$slots.footer" class="stack-footer shrink-0">
            <slot name="footer" />
        </div>
    </div>
</template>
