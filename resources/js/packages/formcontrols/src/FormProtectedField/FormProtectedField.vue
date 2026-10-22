<script setup>
    import { ref, computed } from 'vue'
    import { useIdGenerator, useValidationErrorIdGenerator } from '../helpers'
    import { LucideCornerDownRight, LucideLock, LucideLockOpen } from '@lucide/vue'
    import { FormFieldError } from '../FormFieldError'

    defineOptions({
        inheritAttrs: false
    })

    const props = defineProps({
        modelValue: String,
        modelModifiers: { default: () => ({}) },
        enableProtection: {
            type: Boolean,
            default: false
        },
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
        isExpanded: {
            type: Boolean,
            default: true
        },
        maxLength: {
            type: Number,
            default: null
        },
        idSuffix: {
            type: String,
            default: ''
        },
        isIndented: Boolean,
        isLocked: Boolean,
    })

    const { inputId } = useIdGenerator(props.inputType, props.fieldName + props.idSuffix)
    const { valErrorId } = useValidationErrorIdGenerator(props.fieldName)
    const legendId = useIdGenerator('legend', props.fieldName).inputId

    const isProtected = ref(props.enableProtection)
    const hasBeenTrimmed = ref(false)
    const componentKey = ref(0);

    const disabled = computed(() => {
        return (props.isDisabled || props.isLocked || (props.enableProtection == true && isProtected.value == true)) ? true : false
    })

    const emit = defineEmits(['update:modelValue'])

    /**
     * Removes spaces from the input string
     */
    function emitValue(e) {
        const value = e.target.value.replace(/\s+/g, '')

        emit('update:modelValue', value)
    }

    function alertOnSpace(e) {
        let value = e.target.value
        hasBeenTrimmed.value = value.includes(' ')

        emit('update:modelValue', value)
    }

    function forceRefresh(e) {
        hasBeenTrimmed.value = e.target.value.includes(' ')
        componentKey.value += 1
    }

</script>

<template>
    <div class="md-field" :class="{ 'md-field-indent' : isIndented, 'pt-4' : hasOffset }">
        <LucideCornerDownRight
            v-if="isIndented"
            class="mt-9 ml-1 shrink-0 text-md-outline"
            :class="{ 'opacity-50' : isDisabled || isLocked }"
            aria-hidden="true"
        />
        <div class="min-w-0" :class="{ 'flex-1' : isExpanded }">
            <label :for="inputId" class="md-label" :class="{ 'opacity-50' : isDisabled || isLocked }">
                {{ $t(props.label) }}
                <LucideLock v-if="isLocked" class="size-4" />
            </label>
            <div class="relative">
                <input
                    :key="componentKey"
                    :disabled="disabled"
                    :id="inputId"
                    :type="inputType"
                    class="md-input font-mono text-label tracking-wide"
                    :class="{ 'pr-14' : enableProtection && ! isLocked }"
                    :value="modelValue"
                    :placeholder="placeholder"
                    v-bind="$attrs"
                    v-on:input="alertOnSpace"
                    v-on:change="emitValue"
                    v-on:blur="forceRefresh"
                    :maxlength="maxLength"
                    :aria-describedby="help ? legendId : undefined"
                    :aria-invalid="errorMessage != undefined"
                    :aria-errormessage="errorMessage != undefined ? valErrorId : undefined"
                />
                <template v-if="enableProtection && ! isLocked">
                    <button
                        v-if="isProtected"
                        type="button"
                        class="field-lock md-icon-btn absolute right-2 top-2"
                        @click.stop="isProtected = false"
                        :title="$t('tooltip.unlock')"
                        :aria-label="$t('tooltip.unlock')"
                    >
                        <LucideLock />
                    </button>
                    <button
                        v-else
                        type="button"
                        class="field-unlock md-icon-btn absolute right-2 top-2 text-md-error"
                        @click.stop="isProtected = true"
                        :title="$t('tooltip.lock')"
                        :aria-label="$t('tooltip.lock')"
                    >
                        <LucideLockOpen />
                    </button>
                </template>
            </div>
            <FormFieldError v-if="hasBeenTrimmed" :error="$t('error.spaces_are_ignored')" :field="'spaces'" alertType="warning" />
            <FormFieldError v-if="errorMessage != undefined" :error="errorMessage" :field="fieldName" />
            <p :id="legendId" class="md-help" v-if="help">{{ $t(help) }}</p>
        </div>
    </div>
</template>
