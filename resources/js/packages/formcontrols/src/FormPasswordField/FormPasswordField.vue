<script setup>
    import { ref, computed } from 'vue'
    import { FormFieldError } from '../FormFieldError'
    import { useIdGenerator, useValidationErrorIdGenerator } from '../helpers'
    import { LucideCheck, LucideEye, LucideEyeOff, LucideLock } from '@lucide/vue'

    defineOptions({
        inheritAttrs: true
    })

    const props = defineProps({
        modelValue: [String],
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
            default: 'password'
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
        showRules: {
            type: Boolean,
            default: false
        },
        idSuffix: {
            type: String,
            default: ''
        },
        isLocked: Boolean,
    })

    const { inputId } = useIdGenerator(props.inputType, props.fieldName + props.idSuffix)
    const { valErrorId } = useValidationErrorIdGenerator(props.fieldName)
    const legendId = useIdGenerator('legend', props.fieldName).inputId
    const currentType = ref(props.inputType)
    const hasCapsLockOn = ref(false)

    const hasLowerCase = computed(() => {
        return /[a-z]/.test(props.modelValue ?? '')
    })
    const hasUpperCase = computed(() => {
        return /[A-Z]/.test(props.modelValue ?? '')
    })
    const hasNumber = computed(() => {
        return /[0-9]/.test(props.modelValue ?? '')
    })
    const hasSpecialChar = computed(() => {
        return /[^A-Za-z0-9]/.test(props.modelValue ?? '')
    })
    const IsLongEnough = computed(() => {
        return props.modelValue?.length >= 8
    })

    const optionalRules = computed(() => [
        { id: 'valPwdHasLowerCase', met: hasLowerCase.value, label: 'message.has_lower_case' },
        { id: 'valPwdHasUpperCase', met: hasUpperCase.value, label: 'message.has_upper_case' },
        { id: 'valPwdHasSpecialChar', met: hasSpecialChar.value, label: 'message.has_special_char' },
        { id: 'valPwdHasNumber', met: hasNumber.value, label: 'message.has_number' },
    ])

    function checkCapsLock(event) {
        if (typeof event.getModifierState === 'function') {
            hasCapsLockOn.value = event.getModifierState('CapsLock') ? true : false
        }
    }

    function setFieldType(event) {
        if (currentType.value != event) {
            currentType.value = event
        }
    }
</script>

<template>
    <div class="md-field" :class="{ 'pt-4' : hasOffset }">
        <label :for="inputId" class="md-label">
            {{ $t(props.label) }}
            <LucideLock v-if="isLocked" class="size-4" />
        </label>
        <div class="relative">
            <input
                :disabled="isDisabled || isLocked"
                :name="fieldName"
                :id="inputId"
                :type="currentType"
                class="md-input pr-14"
                :value="modelValue"
                :placeholder="placeholder"
                v-bind="$attrs"
                v-on:input="$emit('update:modelValue', $event.target.value)"
                v-on:keyup="checkCapsLock"
                :aria-describedby="help ? legendId : undefined"
                :aria-invalid="errorMessage != undefined"
                :aria-errormessage="errorMessage != undefined ? valErrorId : undefined"
            />
            <button
                v-if="currentType == 'password'"
                type="button"
                id="btnTogglePassword"
                class="md-icon-btn absolute right-2 top-2"
                @click="setFieldType('text')"
                :title="$t('tooltip.reveal_password')"
                :aria-label="$t('tooltip.reveal_password')"
            >
                <LucideEyeOff />
            </button>
            <button
                v-else
                type="button"
                id="btnTogglePassword"
                class="md-icon-btn absolute right-2 top-2"
                @click="setFieldType('password')"
                :title="$t('tooltip.hide_password')"
                :aria-label="$t('tooltip.hide_password')"
            >
                <LucideEye />
            </button>
        </div>
        <p class="md-help-warning" v-if="hasCapsLockOn">{{ $t('message.caps_lock_is_on') }}</p>
        <FormFieldError v-if="errorMessage != undefined" :error="errorMessage" :field="fieldName" />
        <p class="md-help" v-if="help">{{ $t(help) }}</p>
        <div v-if="showRules" :id="legendId" class="mt-3 grid gap-4 rounded-md bg-md-surface-container px-4 py-3 text-label-sm sm:grid-cols-[1fr_2fr]">
            <div>
                <p class="mb-2 font-medium text-md-on-surface">{{ $t('message.mandatory_rules') }}</p>
                <p class="flex items-center gap-2 text-md-on-surface-variant">
                    <span
                        id="valPwdIsLongEnough"
                        class="inline-flex size-4 items-center justify-center rounded-full border transition-colors duration-300 ease-md"
                        :class="IsLongEnough ? 'is-dot border-transparent bg-md-success text-md-on-success' : 'border-md-outline'"
                    >
                        <LucideCheck v-if="IsLongEnough" class="size-3" stroke-width="3" />
                    </span>
                    {{ $t('message.is_long_enough') }}
                </p>
            </div>
            <div>
                <p class="mb-2 font-medium text-md-on-surface">{{ $t('message.optional_rules_you_should_follow') }}</p>
                <ul class="grid gap-1.5 sm:grid-cols-2">
                    <li v-for="rule in optionalRules" :key="rule.id" class="flex items-center gap-2 text-md-on-surface-variant">
                        <span
                            :id="rule.id"
                            class="inline-flex size-4 items-center justify-center rounded-full border transition-colors duration-300 ease-md"
                            :class="rule.met ? 'is-dot border-transparent bg-md-success text-md-on-success' : 'border-md-outline'"
                        >
                            <LucideCheck v-if="rule.met" class="size-3" stroke-width="3" />
                        </span>
                        {{ $t(rule.label) }}
                    </li>
                </ul>
            </div>
        </div>
    </div>
</template>
