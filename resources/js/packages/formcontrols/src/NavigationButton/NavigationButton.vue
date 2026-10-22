<script setup>
    import { computed } from 'vue'

    const props = defineProps({
        currentPageTitle: {
            type: String,
            default: ''
        },
        previousPageTitle: {
            type: String,
            default: ''
        },
        action: {
            type: String,
            default: 'close'
        },
        useLinkTag: {
            type: Boolean,
            default: true
        },
        isText: {
            type: Boolean,
            default: false
        },
        isCapture: {
            type: Boolean,
            default: false
        },
        isRounded: {
            type: Boolean,
            default: true
        },
    })

    const classes = computed(() => {
        if (props.isCapture) return 'md-btn md-btn-tertiary md-btn-lg shadow-lg'
        if (props.isText) return 'md-btn md-btn-text'
        return 'md-btn md-btn-tonal'
    })

    const emit = defineEmits(['closed', 'goback', 'canceled'])
</script>

<template>
    <!-- back / close / cancel button -->
    <template v-if="useLinkTag">
        <a
            v-if="action == 'close'"
            id="lnkClose"
            href="#"
            @click.prevent="$emit('closed')"
            :class="classes"
            role="button"
            :aria-label="$t('tooltip.close_the_x_page', { pagetitle: currentPageTitle })"
        >
            {{ $t('label.close') }}
        </a>
        <a
            v-else-if="action == 'back'"
            id="lnkBack"
            href="#"
            @click.prevent="$emit('goback')"
            :class="classes"
            role="button"
            :aria-label="$t('tooltip.go_back_to_the_x_page', { pagetitle: previousPageTitle })"
        >
            {{ $t('label.back') }}
        </a>
        <a
            v-else-if="action == 'cancel'"
            id="lnkCancel"
            href="#"
            @click.prevent="$emit('canceled')"
            :class="classes"
            role="button"
        >
            {{ $t('label.cancel') }}
        </a>
    </template>
    <template v-else>
        <button
            v-if="action == 'close'"
            id="btnClose"
            :class="classes"
            @click="$emit('closed')"
            type="button"
        >
            {{ $t('label.close') }}
        </button>
        <button
            v-if="action == 'cancel'"
            id="btnCancel"
            :class="classes"
            @click="$emit('canceled')"
            type="button"
        >
            {{ $t('label.cancel') }}
        </button>
    </template>
</template>
