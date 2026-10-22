<script setup>
    import { useIdGenerator, useValidationErrorIdGenerator } from '../helpers'
    import { FormFieldError } from '../FormFieldError'
    import { LucideCheck, LucideLock } from '@lucide/vue'
    import { LucideGenericIcon } from '@2fauth/ui'

    /**
     * MD3 segmented button bound to a single value.
     */
    const props = defineProps({
        modelValue: [String, Number, Boolean],
        choices: {
            type: Array,
            required: true
        },
        fieldName: {
            type: String,
            required: true
        },
        errorMessage: [String],
        hasOffset: Boolean,
        isDisabled: Boolean,
        isLocked: Boolean,
        label: {
            type: String,
            default: ''
        },
        help: {
            type: String,
            default: ''
        },
    })

    const emit = defineEmits(['update:modelValue'])
    const { valErrorId } = useValidationErrorIdGenerator(props.fieldName)
    const legendId = useIdGenerator('legend', props.fieldName).inputId

    function setRadio(event) {
        emit('update:modelValue', event)
    }
</script>

<template>
    <div class="md-field" :class="{ 'pt-4': hasOffset }">
        <span v-if="label" class="md-label" :class="{ 'opacity-50' : isDisabled || isLocked }">
            {{ $t(props.label) }}
            <LucideLock v-if="isLocked" class="size-4" />
        </span>
        <div
            id="rdoGroup"
            role="radiogroup"
            :aria-describedby="help ? legendId : undefined"
            :aria-invalid="errorMessage != undefined"
            :aria-errormessage="errorMessage != undefined ? valErrorId : undefined"
            class="md-segmented w-full sm:w-auto"
        >
            <button
                v-for="choice in choices"
                :key="choice.value"
                :id="useIdGenerator('button',fieldName+choice.value).inputId"
                role="radio"
                type="button"
                class="md-segment"
                :class="{ 'flex-col gap-0 py-2.5': choice.legend }"
                :title="choice.title ? $t(choice.title) : $t(choice.text)"
                :aria-checked="modelValue===choice.value"
                :disabled="isDisabled || isLocked"
                v-on:click.stop="setRadio(choice.value)">
                <input
                    :id="useIdGenerator('radio',choice.value).inputId"
                    type="radio"
                    class="sr-only"
                    tabindex="-1"
                    :checked="modelValue===choice.value"
                    :value="choice.value"
                    :disabled="isDisabled || isLocked"
                />
                <span v-if="choice.legend" class="block text-label-sm font-medium opacity-70">{{ $t(choice.legend) }}</span>
                <span class="inline-flex items-center gap-1.5">
                    <LucideCheck v-if="modelValue===choice.value && !choice.icon" class="size-4" aria-hidden="true" />
                    <LucideGenericIcon :name="choice.icon" v-if="choice.icon" class="size-[1.125rem]" />
                    <span>{{ $t(choice.text) }}</span>
                </span>
            </button>
        </div>
        <FormFieldError v-if="errorMessage != undefined" :error="errorMessage" :field="fieldName" />
        <p :id="legendId" class="md-help" v-if="help">{{ $t(props.help) }}</p>
    </div>
</template>
