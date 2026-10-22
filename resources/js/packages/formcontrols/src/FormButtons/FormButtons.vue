<script setup>
    import { VueButton } from '../VueButton'

    const props = defineProps({
            showCancelButton: {
                type: Boolean,
                default: false
            },
            isBusy: {
                type: Boolean,
                default: false
            },
            isDisabled: {
                type: Boolean,
                default: false
            },
            submitLabel: {
                type: String,
                default: 'label.submit'
            },
            cancelLabel: {
                type: String,
                default: 'label.cancel'
            },
            color: {
                type: String,
                default: 'filled'
            },
            submitId: {
                type: String,
                default: 'btnSubmit'
            },
            cancelId: {
                type: String,
                default: 'btnCancel'
            },
            isFullWidth: {
                type: Boolean,
                default: false
            },
    })

    const emit = defineEmits(['submit', 'cancel'])
</script>

<template>
    <div class="mt-8 flex flex-wrap items-center gap-3" :class="{ 'flex-col-reverse items-stretch': isFullWidth }">
        <VueButton @click="emit('submit')" :id="submitId" nativeType="submit" :color="color" :isLoading="isBusy" :disabled="isDisabled" size="lg" :isFullWidth="isFullWidth">
            {{ $t(submitLabel) }}
        </VueButton>
        <VueButton v-if="showCancelButton" @click="emit('cancel')" :id="cancelId" nativeType="button" color="text" size="lg" :isFullWidth="isFullWidth">
            {{ $t(cancelLabel) }}
        </VueButton>
    </div>
</template>
