<script setup>
    import { computed } from 'vue'
    import { LucideLoaderCircle } from '@lucide/vue'

    /**
     * MD3 button. `color` accepts a variant name (filled, tonal, outlined,
     * text, neutral, elevated, danger, danger-tonal, danger-text, tertiary)
     * and, for backward compatibility, the former Bulma modifiers.
     */
    const props = defineProps({
        label: {
            type: String,
            default: '[[label]]'
        },
        color: {
            type: String,
            default: 'filled'
        },
        size: {
            type: String,
            default: 'md',
            validator: (value) => ['xs', 'sm', 'md', 'lg'].includes(value)
        },
        isFullWidth: {
            type: Boolean,
            default: false
        },
        isLoading: {
            type: Boolean,
            default: false
        },
        isDisabled: {
            type: Boolean,
            default: false
        },
        nativeType: {
            type: String,
            default: 'submit',
            required: true
        }
    })

    const legacyVariants = {
        'is-link': 'filled',
        'is-primary': 'filled',
        'is-info': 'filled',
        'is-text': 'text',
        'is-ghost': 'text',
        'is-danger': 'danger',
        'is-dark': 'tonal',
        'is-white': 'tonal',
        'is-light': 'tonal',
        '': 'tonal',
    }

    const classes = computed(() => {
        const variant = legacyVariants[props.color] ?? props.color

        return [
            'md-btn',
            `md-btn-${variant}`,
            props.size !== 'md' ? `md-btn-${props.size}` : null,
            props.isFullWidth ? 'w-full' : null,
        ]
    })
</script>

<template>
    <button
        :type="nativeType"
        :disabled="isLoading || isDisabled"
        :aria-busy="isLoading ? 'true' : undefined"
        :class="classes">
        <LucideLoaderCircle v-if="isLoading" class="md-btn-spinner" aria-hidden="true" />
        <slot>
            {{ $t(props.label) }}
        </slot>
    </button>
</template>
