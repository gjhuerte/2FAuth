<script setup>
    import { LucideAtSign, LucideEllipsis, LucideSquareSlash, LucideStar, LucideUserCheck, LucideUsers } from '@lucide/vue'

    const activeGroup = defineModel('activeGroup')
    const showGroupSwitch = defineModel('showGroupSwitch')
    const showFavoritesOnly = defineModel('showFavoritesOnly')

    const props = defineProps({
        groups: Array,
        filteredCount: {
            type: Number,
            default: null
        },
        useVirtualChips: {
            type: Boolean,
            default: false
        },
        useShare: {
            type: Boolean,
            default: false
        },
        useShareAllScope: {
            type: Boolean,
            default: false
        },
        useFavorites: {
            type: Boolean,
            default: false
        },
        isRightAligned: {
            type: Boolean,
            default: false
        },
    })

    const emit = defineEmits([
        'active-group-changed',
    ])

    /**
     * Sets the selected group
     */
    function setActiveGroup(id) {
        activeGroup.value = id
        emit('active-group-changed', id)
    }

    /**
     * Sets the selected group
     */
    // function toggleFavorite(id) {
    //     activeGroup.value = id
    //     emit('show-favorited-only-toggled', id)
    // }

</script>

<template>
    <div
        id="groupChips"
        class="flex gap-2 overflow-x-auto px-4 py-1 scrollbar-none"
        :class="props.isRightAligned ? 'justify-end' : 'justify-start sm:justify-center'"
    >
        <button type="button" class="md-chip" :aria-pressed="activeGroup == 0" @click="setActiveGroup(-0)" :title="$t('label.all_accounts')">
            {{ $t('label.all') }}
            <span v-if="activeGroup == 0" class="text-label-sm opacity-80">{{ filteredCount }}</span>
        </button>
        <button
            v-if="useFavorites"
            type="button"
            class="md-chip px-2.5"
            :aria-pressed="!!showFavoritesOnly"
            @click="showFavoritesOnly = !showFavoritesOnly"
            :title="$t('tooltip.show_favorites_only')"
            :aria-label="$t('tooltip.show_favorites_only')"
        >
            <LucideStar :class="showFavoritesOnly ? 'fill-md-star text-md-star' : ''" />
        </button>
        <template v-for="group in groups" :key="group.id" >
            <button
                v-if="(group.id != 0 && group.show_in_chips) || (activeGroup > 0 && group.id == activeGroup && group.show_in_chips != true)"
                type="button"
                class="md-chip"
                :aria-pressed="activeGroup == group.id"
                @click="setActiveGroup(group.id)">
                <span class="chip-label truncate">{{ group.name }}</span>
                <span v-if="activeGroup == group.id" class="text-label-sm opacity-80">{{ filteredCount }}</span>
            </button>
        </template>
        <button type="button" class="md-chip px-3" @click="showGroupSwitch = true" :title="$t('tooltip.show_group_selector')" :aria-label="$t('tooltip.show_group_selector')">
            <LucideEllipsis />
        </button>
        <template v-if="useVirtualChips">
            <button v-if="useShare" type="button" class="md-chip" :aria-pressed="activeGroup == -2" @click="setActiveGroup(-2)" :title="$t('label.accounts_I_m_sharing')">
                <LucideUsers v-if="useShareAllScope" />
                <LucideUserCheck />
                <span v-if="activeGroup == -2" class="text-label-sm opacity-80">{{ filteredCount }}</span>
            </button>
            <button v-if="useShare" type="button" class="md-chip" :aria-pressed="activeGroup == -3" @click="setActiveGroup(-3)" :title="$t('label.accounts_shared_with_me')">
                <LucideAtSign />
                <span v-if="activeGroup == -3" class="text-label-sm opacity-80">{{ filteredCount }}</span>
            </button>
            <button type="button" class="md-chip" :aria-pressed="activeGroup == -1" @click="setActiveGroup(-1)" :title="$t('label.group_less_accounts')">
                <LucideSquareSlash />
                <span v-if="activeGroup == -1" class="text-label-sm opacity-80">{{ filteredCount }}</span>
            </button>
        </template>
    </div>
</template>
