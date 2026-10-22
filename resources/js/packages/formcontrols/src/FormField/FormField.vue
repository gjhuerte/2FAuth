<script setup>
    import { useIdGenerator, useValidationErrorIdGenerator } from '../helpers'
    import { LucideCornerDownRight, LucideLock } from '@lucide/vue'
    import { FormFieldError } from '../FormFieldError'
    import { LucideGenericIcon } from '@2fauth/ui'

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
        inputType: {
            type: String,
            default: 'text'
        },
        placeholder: {
            type: String,
            default: ''
        },
        help: {
            type: String,
            default: ''
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
        iconSize: {
            type: Number,
            default: 20
        },
        iconColor: {
            type: String,
            default: 'currentColor'
        },
        iconStrokeWidth: {
            type: Number,
            default: 2
        },
        idSuffix: {
            type: String,
            default: ''
        },
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
            <label v-if="props.label" :for="inputId" class="md-label" :class="{ 'opacity-50' : isDisabled || isLocked }">
                {{ $t(props.label) }}
                <LucideLock v-if="isLocked" class="size-4" />
            </label>
            <div class="relative">
                <input
                    :disabled="isDisabled || isLocked"
                    :id="inputId"
                    :name="fieldName"
                    :type="inputType"
                    class="md-input"
                    :class="{ 'pl-12' : leftIcon, 'pr-12': rightIcon }"
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
                <span v-if="leftIcon" class="pointer-events-none absolute inset-y-0 left-4 flex items-center text-md-on-surface-variant">
                    <LucideGenericIcon :name="leftIcon" :stroke-width="iconStrokeWidth" :size="iconSize" :color="iconColor" />
                </span>
                <span v-if="rightIcon" class="pointer-events-none absolute inset-y-0 right-4 flex items-center text-md-on-surface-variant">
                    <LucideGenericIcon :name="rightIcon" :stroke-width="iconStrokeWidth" :size="iconSize" :color="iconColor" />
                </span>
            </div>
            <FormFieldError v-if="errorMessage != undefined" :error="errorMessage" :field="fieldName" />
            <p :id="legendId" class="md-help" v-if="help">{{ $t(help) }}</p>
        </div>
    </div>
</template>
