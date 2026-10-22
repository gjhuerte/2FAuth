<script setup>
    import ResponsiveWidthWrapper from '../ResponsiveWidthWrapper/ResponsiveWidthWrapper.vue'
    import { LucideGenericIcon } from '../LucideGenericIcon'
    
    const props = defineProps({
        tabs: {
            type: Array
        },
        activeTab: {
            type: String,
            default: ''
        },
        isResponsive: {
            type: Boolean,
            default: true
        }
    })

    const emit = defineEmits(['tab-selected'])
</script>

<template>
    <div class="options-header sticky top-0 z-[1000] border-b border-md-outline-variant bg-md-surface">
        <ResponsiveWidthWrapper :is-active="isResponsive" :is-compact="true">
            <nav class="pt-[env(safe-area-inset-top)]">
                <ul role="menubar" class="tabs flex">
                    <li
                        v-for="tab in props.tabs"
                        :key="tab.view"
                        role="none"
                        class="flex flex-1"
                        :class="{ 'is-active': tab.view === props.activeTab }"
                    >
                        <a
                            :id="tab.id"
                            href="#"
                            role="menuitem"
                            class="md-tab"
                            :aria-current="tab.view === props.activeTab ? 'page' : undefined"
                            @click.prevent="emit('tab-selected', tab.view)"
                        >
                            <LucideGenericIcon :name="tab.icon" :strokeWidth="tab.view === props.activeTab ? 2 : 1.5" class="size-6! sm:hidden" />
                            <span class="text-label-sm font-medium sm:text-label">
                                {{ $t(tab.name) }}
                            </span>
                        </a>
                    </li>
                </ul>
            </nav>
        </ResponsiveWidthWrapper>
    </div>
</template>
