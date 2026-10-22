<script setup>
    import { LucideChevronDown } from '@lucide/vue'

    const showGroupSwitch = defineModel('showGroupSwitch')

    const props = defineProps({
        currentGroup: {
            type: String,
            default: null
        },
        activeGroup: {
            type: Number,
            default: 0
        },
        filteredCount: {
            type: Number,
            default: null
        },
        useShare: {
            type: Boolean,
            default: false
        },
    })

</script>

<template>
    <button
        type="button"
        id="btnShowGroupSwitch"
        :title="$t('tooltip.show_group_selector')"
        tabindex="1"
        class="md-btn md-btn-neutral md-btn-sm max-w-full"
        @click.stop="showGroupSwitch = !showGroupSwitch"
        :aria-expanded="showGroupSwitch"
    >
        <span class="truncate">
            <template v-if="parseInt(activeGroup) == -1">{{ $t('label.group_less') }}</template>
            <template v-else-if="useShare && parseInt(activeGroup) == -2">{{ $t('label.shared_by_me') }}</template>
            <template v-else-if="useShare && parseInt(activeGroup) == -3">{{ $t('label.shared_with_me') }}</template>
            <template v-else-if="currentGroup">{{ currentGroup }}</template>
            <template v-else>{{ $t('label.all') }}</template>
        </span>
        <span class="md-badge h-5 px-2">{{ filteredCount }}</span>
        <LucideChevronDown class="transition-transform duration-300 ease-md" :class="{ 'rotate-180': showGroupSwitch }" />
    </button>
</template>
