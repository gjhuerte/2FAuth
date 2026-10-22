<script setup>
    import { computed } from 'vue'
    import { useValidationErrorIdGenerator } from '../helpers'

    const props = defineProps({
        error: {
            type: String,
            required: true
        },
        field: {
            type: String,
            required: true
        },
        alertType: {
            type: String,
            default: 'error',
            // 'is-danger' / 'is-warning' are accepted for backward compatibility
        }
    })

    const { valErrorId } = useValidationErrorIdGenerator(props.field)

    const helpClass = computed(() => {
        return ['warning', 'is-warning'].includes(props.alertType) ? 'md-help-warning' : 'md-help-error'
    })
</script>

<template>
    <div role="alert">
        <p :id="valErrorId" :class="helpClass">
            {{ error }}
        </p>
    </div>
</template>
