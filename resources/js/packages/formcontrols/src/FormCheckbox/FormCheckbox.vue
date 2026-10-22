<script setup>
    import { computed } from 'vue'
    import { useIdGenerator } from '../helpers'
    import { LucideCornerDownRight, LucideLock } from '@lucide/vue'

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
            class="mt-2.5 ml-1 shrink-0 text-md-outline"
            :class="{ 'opacity-50' : isDisabled || isLocked }"
            aria-hidden="true"
        />
        <div class="flex items-start gap-4 rounded-md py-2 pl-3 pr-2">
            <input
                :id="fieldName"
                type="checkbox"
                :name="fieldName"
                class="md-checkbox mt-0.5"
                v-model="model"
                :disabled="isDisabled || isLocked"
                :aria-describedby="help ? legendId : undefined"
            />
            <div class="min-w-0" :class="{ 'opacity-50' : isDisabled || isLocked }">
                <label :for="fieldName" class="flex items-center gap-1.5 text-body font-medium text-md-on-surface" :class="labelClass">
                    {{ $t(props.label) }}
                    <LucideLock v-if="isLocked" class="size-4 text-md-on-surface-variant" />
                </label>
                <p :id="legendId" class="mt-0.5 text-label font-normal leading-relaxed text-md-on-surface-variant" v-if="help">{{ $t(help) }}</p>
            </div>
        </div>
    </div>
</template>
