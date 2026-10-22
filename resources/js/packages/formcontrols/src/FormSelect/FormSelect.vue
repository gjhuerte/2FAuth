<script setup>
    import { FormFieldError } from '../FormFieldError'
    import { useIdGenerator, useValidationErrorIdGenerator } from '../helpers'
    import { LucideChevronDown, LucideCornerDownRight, LucideLoaderCircle, LucideLock } from '@lucide/vue'

    const model = defineModel()
    const props = defineProps({
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
        options: {
            type: Array,
            required: true
        },
        help: {
            type: String,
            default: ''
        },
        isIndented: Boolean,
        isDisabled: Boolean,
        isLocked: Boolean,
        isLoading: {
            type: Boolean,
            default: false
        },
        idSuffix: {
            type: String,
            default: ''
        },
    })

    const { inputId } = useIdGenerator('select', props.fieldName + props.idSuffix)
    const { valErrorId } = useValidationErrorIdGenerator(props.fieldName)
    const legendId = useIdGenerator('legend', props.fieldName + props.idSuffix).inputId
</script>

<template>
    <div class="md-field" :class="{ 'md-field-indent' : isIndented }">
        <LucideCornerDownRight
            v-if="isIndented"
            class="mt-9 ml-1 shrink-0 text-md-outline"
            :class="{ 'opacity-50' : isDisabled || isLocked }"
            aria-hidden="true"
        />
        <div class="min-w-0">
            <label :for="inputId" class="md-label" :class="{ 'opacity-50' : isDisabled || isLocked }">
                {{ $t(props.label) }}
                <LucideLock v-if="isLocked" class="size-4" />
            </label>
            <div class="flex flex-wrap items-center gap-3">
                <div class="relative min-w-56 max-w-full">
                    <select
                        :id="inputId"
                        :name="fieldName"
                        v-model="model"
                        class="md-select"
                        :disabled="isDisabled || isLocked || isLoading"
                        :aria-describedby="help ? legendId : undefined"
                        :aria-invalid="errorMessage != undefined"
                        :aria-errormessage="errorMessage != undefined ? valErrorId : undefined"
                    >
                        <option v-for="option in options" :key="option.value" :value="option.value">
                            {{ $t(option.text) }}
                        </option>
                    </select>
                    <span class="pointer-events-none absolute inset-y-0 right-4 flex items-center text-md-on-surface-variant" aria-hidden="true">
                        <LucideLoaderCircle v-if="isLoading" class="animate-spin-md" />
                        <LucideChevronDown v-else />
                    </span>
                </div>
                <slot></slot>
            </div>
            <FormFieldError v-if="errorMessage != undefined" :error="errorMessage" :field="fieldName" />
            <p :id="legendId" class="md-help" v-if="help">{{ $t(help) }}</p>
        </div>
    </div>
</template>
