<script setup>
    import { useTemplateRef, onMounted, onUnmounted } from 'vue'
    import { LucideSearch, LucideX } from '@lucide/vue'

    const keyword = defineModel('keyword')
    const props = defineProps({
        hasNoBackground: {
            type: Boolean,
            default: false
        },
        placeholder: String,
        isSmall: {
            type: Boolean,
            default: false
        },
    })
    const searchInputRef = useTemplateRef('searchInput')
    const emit = defineEmits(['cleared'])

    onMounted(() => {
        document.addEventListener('keydown', ctrlFHandler)
        document.addEventListener('keypress', anyPrintableKeyHandler)
    })

    onUnmounted(() => {
        document.removeEventListener('keydown', ctrlFHandler)
        document.removeEventListener('keypress', anyPrintableKeyHandler)
    })

    /**
     * Attach an event listen for ctrl+F
     */
    function ctrlFHandler(e) {
        if (e.key === "f" && (e.ctrlKey || e.metaKey)) {
            e.preventDefault()
            searchInputRef.value?.focus()
        }
    }

    /**
     * Clear the search field
     */
    function clearSearch() {
        keyword.value = ''
        emit('cleared')
    }

    /**
     * Attach an event listen for any key press to automatically focus on search
     * without having to ctrl+F
     */
    function anyPrintableKeyHandler(e) {
        if (e.key === 'Enter' || e.code === 'Space' || e.key === " ") {
            return
        }

        keyword.value = e.key
        searchInputRef.value?.setSelectionRange(1, 1)
        searchInputRef.value?.focus()
        e.preventDefault()
    }
</script>

<template>
    <div role="search" class="relative w-full">
        <LucideSearch class="pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 text-md-on-surface-variant" aria-hidden="true" />
        <input
            v-model="keyword"
            @keyup.esc.prevent="(event) => { clearSearch(); event.target.blur() }"
            @keyup.enter.prevent="(event) => event.target.blur()"
            @keypress.stop
            ref="searchInput"
            id="txtSearch"
            type="search"
            tabindex="1"
            :aria-label="$t('label.search')"
            :title="$t('tooltip.search')"
            :placeholder="placeholder"
            class="md-search"
            :class="{ 'h-10 text-label': isSmall, 'pr-12': keyword != '' }">
        <button
            type="button"
            v-if="keyword != ''"
            id="btnClearSearch"
            tabindex="1"
            :title="$t('tooltip.clear_search')"
            :aria-label="$t('tooltip.clear_search')"
            class="clear-selection md-icon-btn md-icon-btn-sm absolute right-2 top-1/2 -translate-y-1/2"
            @click="clearSearch"
        >
            <LucideX />
        </button>
    </div>
</template>
