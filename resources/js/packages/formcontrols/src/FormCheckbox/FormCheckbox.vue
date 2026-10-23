<script setup>
    import { computed } from 'vue'
    import { useIdGenerator } from '../helpers'
    import { LucideCornerDownRight, LucideLock, LucideCheck } from '@lucide/vue'

    defineOptions({
        inheritAttrs: false
    })

    const props = defineProps({
        modelValue: Boolean,
        fieldName: {
            type: String,
            default: '',
            required: true
        },
        label: {
            type: String,
            default: ''
        },
        labelClass: {
            type: String,
            default: ''
        },
        help: {
            type: String,
            default: ''
        },
        isIndented: Boolean,
        isDisabled: Boolean,
        isLocked: Boolean,
        isWarning: Boolean,
        isDanger: Boolean,
    })

    const emit = defineEmits(['update:modelValue'])
    const legendId = useIdGenerator('legend', props.fieldName).inputId
    const model = computed({
        get() {
            return props.modelValue;
        },
        set(value) {
            emit("update:modelValue", value);
        },
    })
</script>

<template>
    <div
        class="mb-4 flex gap-1"
        :class="{ 'md-rail-warning' : isWarning, 'md-rail-danger' : isDanger }"
    >
        <LucideCornerDownRight
            v-if="isIndented"
            class="mt-3.5 ml-1 shrink-0 text-md-outline"
            :class="{ 'text-md-on-disabled!' : isDisabled || isLocked }"
            aria-hidden="true"
        />
        <div class="flex min-w-0 flex-1 items-center gap-4 rounded-[16px] py-2 pl-3 pr-2">
            <div class="min-w-0 flex-1">
                <label :for="fieldName" class="flex items-center gap-1.5 text-body font-medium" :class="[labelClass, isDisabled || isLocked ? 'text-md-on-disabled' : 'text-md-on-surface']">
                    {{ $t(props.label) }}
                    <LucideLock v-if="isLocked" class="size-4" />
                </label>
                <p :id="legendId" class="mt-0.5 text-label font-normal leading-relaxed" :class="isDisabled || isLocked ? 'text-md-on-disabled' : 'text-md-on-surface-variant'" v-if="help">{{ $t(help) }}</p>
            </div>
            <span class="md-switch">
                <input
                    :id="fieldName"
                    type="checkbox"
                    role="switch"
                    :name="fieldName"
                    v-model="model"
                    :disabled="isDisabled || isLocked"
                    :aria-describedby="help ? legendId : undefined"
                />
                <span class="md-switch-track" aria-hidden="true"></span>
                <span class="md-switch-thumb" aria-hidden="true"><LucideCheck :stroke-width="3" /></span>
            </span>
        </div>
    </div>
</template>
