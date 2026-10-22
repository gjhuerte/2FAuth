<script setup>
    import { LucideArrowDownAZ, LucideArrowUpAZ, LucideSquareCheck, LucideX } from '@lucide/vue';

    const sortOrder = defineModel('sortOrder')

    const props = defineProps({
        selectedCount: Number
    })

    const emit = defineEmits(['sort-asc', 'sort-desc'])

    /**
     * 
     * @param sortOrder string
     */
    function setSortOrder(newOrder) {
        sortOrder.value = newOrder
        emit('sort-' + newOrder)
    }

</script>

<template>
    <div class="toolbar mx-auto flex w-fit max-w-full flex-wrap items-center justify-center gap-1 rounded-full bg-md-surface-container-high px-2 py-1 shadow-sm animate-enter">
        <!-- selected label -->
        <span class="px-3 text-label text-md-on-surface" aria-live="polite">{{ $t('message.x_selected', { count: selectedCount }) }}</span>
        <!-- deselect all -->
        <button
            type="button"
            id="btnUnselectAll"
            @click="$emit('clear-selected')"
            class="clear-selection md-icon-btn md-icon-btn-sm"
            :class="{ 'invisible': selectedCount == 0 }"
            :title="$t('tooltip.clear_selection')"
            :aria-label="$t('tooltip.clear_selection')"
        >
            <LucideX />
        </button>
        <span class="mx-1 h-5 w-px bg-md-outline-variant" aria-hidden="true"></span>
        <!-- select all button -->
        <button type="button" id="btnSelectAll" @click="$emit('select-all')" class="md-btn md-btn-text md-btn-xs" :title="$t('tooltip.select_all')">
            <LucideSquareCheck />
            <span>{{ $t('label.check_all') }}</span>
        </button>
        <!-- sort asc/desc buttons -->
        <div class="md-segmented ml-1 h-8 border-md-outline-variant" role="group">
            <button type="button" id="btnSortAscending" @click="setSortOrder('asc')" class="md-segment min-h-8 px-3 py-0" :aria-checked="sortOrder == 'asc'" role="radio" :title="$t('tooltip.sort_ascending')" :aria-label="$t('tooltip.sort_ascending')">
                <LucideArrowDownAZ class="size-4!" />
            </button>
            <button type="button" id="btnSortDescending" @click="setSortOrder('desc')" class="md-segment min-h-8 px-3 py-0" :aria-checked="sortOrder == 'desc'" role="radio" :title="$t('tooltip.sort_descending')" :aria-label="$t('tooltip.sort_descending')">
                <LucideArrowUpAZ class="size-4!" />
            </button>
        </div>
    </div>
</template>
