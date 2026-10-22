<script setup>
    import { FormFieldError } from '../FormFieldError'
    import { useIdGenerator, useValidationErrorIdGenerator } from '../helpers'
    import { LucideCornerDownRight, LucideLock } from '@lucide/vue'

    defineOptions({
        inheritAttrs: false
    })

    const props = defineProps({
        modelValue: [String, Number, Boolean],
        label: {
            type: String,
            default: ''
        },
        fieldName: {
            type: String,
            default: '',
            required: true
        },
        errorMessage: [String],
        placeholder: {
            type: String,
            default: ''
        },
        help: {
            type: String,
            default: ''
        },
        fontSize: {
            type: String,
            default: 'is-small'
        },
        hasOffset: {
            type: Boolean,
            default: false
        },
        isDisabled: {
            type: Boolean,
            default: false
        },
        maxLength: {
            type: Number,
            default: null
        },
        isIndented: Boolean,
        isLocked: Boolean,
        leftIcon: {
            type: String,
            default: ''
        },
        rightIcon: {
            type: String,
            default: ''
        },
        idSuffix: {
            type: String,
            default: ''
        }
    })

    const { inputId } = useIdGenerator(props.inputType, props.fieldName + props.idSuffix)
    const { valErrorId } = useValidationErrorIdGenerator(props.fieldName)
    const legendId = useIdGenerator('legend', props.fieldName).inputId
</script>

<template>
    <div class="md-field" :class="{ 'pt-4' : hasOffset, 'md-field-indent' : isIndented }">
        <LucideCornerDownRight
            v-if="isIndented"
            class="mt-9 ml-1 shrink-0 text-md-outline"
            :class="{ 'opacity-50' : isDisabled || isLocked }"
            aria-hidden="true"
        />
        <div class="min-w-0 flex-1">
            <label v-if="label" :for="inputId" class="md-label">
                {{ $t(props.label) }}
                <LucideLock v-if="isLocked" class="size-4" />
            </label>
            <textarea
                :disabled="isDisabled || isLocked"
                :name="fieldName"
                :id="inputId"
                class="md-textarea"
                :class="{ 'text-body font-sans': fontSize !== 'is-small' }"
                :value="modelValue"
                :placeholder="placeholder"
                v-bind="$attrs"
                v-on:input="$emit('update:modelValue', $event.target.value)"
                v-on:change="$emit('change:modelValue', $event.target.value)"
                :maxlength="maxLength"
                :aria-describedby="help ? legendId : undefined"
                :aria-invalid="errorMessage != undefined"
                :aria-errormessage="errorMessage != undefined ? valErrorId : undefined"
            />
            <FormFieldError v-if="errorMessage != undefined" :error="errorMessage" :field="fieldName" />
            <p :id="legendId" class="md-help" v-if="help">{{ $t(help) }}</p>
        </div>
    </div>
</template>
