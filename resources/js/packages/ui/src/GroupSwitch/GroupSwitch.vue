<script setup>
    import { LucideAtSign, LucideSquareSlash, LucideUserCheck, LucideUsers } from '@lucide/vue'
    
    const activeGroup = defineModel('activeGroup')
    const isVisible = defineModel('isVisible')

    const props = defineProps({
        groups: Array,
        useShare: {
            type: Boolean,
            default: false
        },
        useShareAllScope: {
            type: Boolean,
            default: false
        },
    })

    const emit = defineEmits(['active-group-changed'])

    /**
     * Sets the selected group
     */
    function setActiveGroup(id) {
        isVisible.value = false
        activeGroup.value = id
        emit('active-group-changed', id)
    }

</script>

<template>
    <div v-if="isVisible" id="groupSwitch" class="fixed inset-0 z-[1500] bg-md-surface">
        <StackLayout :should-grow="true">
            <template #content>
                <div class="mx-auto w-full max-w-md pb-6 pt-10 animate-enter">
                    <p class="md-overline mb-4 px-2">{{ $t('label.active_group') }}</p>
                    <div class="md-list shadow-sm">
                        <button type="button" class="group-item flex min-h-14 w-full items-center gap-4 border-b border-md-surface px-5 text-left text-body text-md-on-surface transition-colors duration-200 ease-md hover:bg-md-hover" @click="setActiveGroup(0)">
                            <span class="flex-1">{{ $t('label.all_accounts') }}</span>
                            <span v-if="activeGroup == 0" class="size-2 rounded-full bg-md-primary" aria-hidden="true"></span>
                        </button>
                        <button v-if="groups.length > 1" type="button" class="group-item flex min-h-14 w-full items-center gap-4 border-b border-md-surface px-5 text-left text-body text-md-on-surface transition-colors duration-200 ease-md hover:bg-md-hover" @click="setActiveGroup(-1)">
                            <LucideSquareSlash class="text-md-on-surface-variant" />
                            <span class="flex-1">{{ $t('label.group_less_accounts') }}</span>
                        </button>
                        <button v-if="useShare" type="button" class="group-item flex min-h-14 w-full items-center gap-4 border-b border-md-surface px-5 text-left text-body text-md-on-surface transition-colors duration-200 ease-md hover:bg-md-hover" @click="setActiveGroup(-2)">
                            <span class="flex items-center gap-1 text-md-on-surface-variant">
                                <LucideUsers v-if="useShareAllScope" />
                                <LucideUserCheck />
                            </span>
                            <span class="flex-1">{{ $t('label.accounts_I_m_sharing') }}</span>
                        </button>
                        <button v-if="useShare" type="button" class="group-item flex min-h-14 w-full items-center gap-4 px-5 text-left text-body text-md-on-surface transition-colors duration-200 ease-md hover:bg-md-hover" @click="setActiveGroup(-3)">
                            <LucideAtSign class="text-md-on-surface-variant" />
                            <span class="flex-1">{{ $t('label.accounts_shared_with_me') }}</span>
                        </button>
                    </div>
                    <template v-if="groups.length > 1">
                        <p class="md-overline mb-4 mt-8 px-2">{{ $t('message.or_filter_by_group') }}</p>
                        <div class="grid grid-cols-2 gap-3">
                            <template v-for="group in groups" :key="group.id">
                                <button
                                    v-if="group.id > 0"
                                    type="button"
                                    class="group-item md-card md-card-interactive flex min-h-20 items-end p-4 text-left text-title text-md-on-surface hover:scale-[1.02]"
                                    :class="{ 'ring-1 ring-md-primary': activeGroup == group.id }"
                                    @click="setActiveGroup(group.id)"
                                >
                                    <span class="line-clamp-2 break-words">{{ group.name }}</span>
                                </button>
                            </template>
                        </div>
                    </template>
                    <div v-if="$slots.default" class="mt-8 flex justify-center">
                        <slot />
                    </div>
                </div>
            </template>
        </StackLayout>
    </div>
</template>
