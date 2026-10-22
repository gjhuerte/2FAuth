<script setup>
    import twofaccountService from '@/services/twofaccountService'
    import groupService from '@/services/groupService'
    import { LucideFolderMinus } from '@lucide/vue'

    const props = defineProps({
        showDestinationGroupSelector: Boolean,
        selectedAccountsIds: Array,
        groups: Array
    })
    const destinationGroupId = ref(null)

    const emit = defineEmits(['update:showDestinationGroupSelector', 'accounts-moved'])

    /**
     * Move accounts selected from the Edit mode to another group or withdraw them
     */
    async function moveAccounts() {
        // Backend will associate all provided accounts with the selected group in the same move
        // or withdraw the accounts if destination is 'no group' (id = 0)
        if (destinationGroupId.value === 0) {
            await twofaccountService.withdraw(props.selectedAccountsIds)
        }
        else await groupService.assign(props.selectedAccountsIds, destinationGroupId.value, { returnError: true })

        emit('accounts-moved')
    }

</script>

<template>
    <!-- Group selector -->
    <StackLayout>
        <template #content>
            <div class="mx-auto w-full max-w-md pb-6 pt-10 animate-enter">
                <h2 class="md-section-title mb-6 text-center">{{ $t('message.move_selected_to') }}</h2>
                <div class="md-list shadow-sm" role="radiogroup">
                    <template v-for="group in groups" :key="group.id">
                        <button
                            v-if="group.id > 0"
                            type="button"
                            role="radio"
                            :aria-checked="destinationGroupId === group.id"
                            class="flex min-h-14 w-full items-center gap-4 border-b border-md-surface px-5 text-left text-body text-md-on-surface transition-colors duration-200 ease-md hover:bg-md-hover aria-checked:bg-md-secondary-container aria-checked:text-md-on-secondary-container"
                            @click="destinationGroupId = group.id"
                        >
                            <span class="flex size-5 shrink-0 items-center justify-center rounded-full border" :class="destinationGroupId === group.id ? 'border-md-primary' : 'border-md-on-surface-variant'">
                                <span v-if="destinationGroupId === group.id" class="size-2.5 rounded-full bg-md-primary"></span>
                            </span>
                            <span class="truncate">{{ group.name }}</span>
                        </button>
                    </template>
                </div>
                <p class="my-4 text-center text-label text-md-on-surface-variant">{{ $t('message.or') }}</p>
                <button
                    type="button"
                    role="radio"
                    :aria-checked="destinationGroupId === 0"
                    class="md-card md-card-interactive flex w-full items-center gap-4 p-4 text-left text-body text-md-on-surface aria-checked:bg-md-secondary-container aria-checked:text-md-on-secondary-container"
                    @click="destinationGroupId = 0"
                >
                    <LucideFolderMinus class="text-md-on-surface-variant" />
                    {{ $t('label.remove_from_group') }}
                </button>
                <div class="mt-6 text-center">
                    <RouterLink :to="{ name: 'groups' }" class="md-link">{{ $t('link.manage_groups') }}</RouterLink>
                </div>
            </div>
        </template>
        <template #footer>
            <VueFooter>
                <template #default>
                    <!-- Move to selected group button -->
                    <button type="button" class="md-btn md-btn-filled md-btn-lg" :disabled="destinationGroupId === null" @click="moveAccounts">{{ $t('label.apply') }}</button>
                    <NavigationButton action="cancel" :useLinkTag="false" @canceled="$emit('update:showDestinationGroupSelector', false)" />
                </template>
            </VueFooter>
        </template>
    </StackLayout>
</template>
