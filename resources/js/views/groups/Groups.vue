<script setup>
    import { useGroups } from '@/stores/groups'
    import { useBusStore } from '@/stores/bus'
    import { useUserStore } from '@/stores/user'
    import { LucideBookmarkCheck, LucideCirclePlus, LucideGripVertical, LucideInfo, LucidePencil, LucideTrash2 } from '@lucide/vue'
    import { useSortable, moveArrayElement } from '@vueuse/integrations/useSortable'

    const router = useRouter()
    const groups = useGroups()
    const bus = useBusStore()
    const user = useUserStore()

    const isFetching = ref(false)

    // Enables the sortable behaviour of the groups list
    const { start, stop } = useSortable('#dv', groups.withoutTheAllGroup, {
        animation: 200,
        handle: '.drag-handle',
        onUpdate: (e) => {
            const movedId = groups.withoutTheAllGroup[e.oldIndex].id
            const inItemsIndex = groups.items.findIndex(item => item.id == movedId)
            moveArrayElement(groups.items, inItemsIndex, e.newIndex + 1, e)

            nextTick(() => {
                groups.saveOrder()
            })
        }
    })

    watch(
        () => groups.isEmpty,
        (val) => {
            if (val == false) {
                nextTick(() => {
                    start()
                })
            }
            else stop()
        }
    )

    onMounted(() => {
        // We want the store to be up-to-date to manage the groups
        isFetching.value = groups.isEmpty

        groups.fetch()
        .finally(() => {
            isFetching.value = false
        })
    })

    // We use the beforeRouteLeave with the bus store to pass the group
    // name to the edit view to prevent a new request in the editGroup component.
    // This could be achieved using <a> anchor with a @click event here but then
    // the link won't have a href which is poor design for accessibility.
    onBeforeRouteLeave((to, from) => {
        if (to.name == 'editGroup') {
            bus.editedGroupName = groups.items.find(g => g.id == to.params.groupId)?.name
        }
    })

</script>

<template>
    <StackLayout>
        <template #content>
            <ResponsiveWidthWrapper>
                <div class="flex flex-wrap items-end justify-between gap-4">
                    <div>
                        <h1 class="md-page-title">
                            {{ $t('heading.groups') }}
                        </h1>
                        <p class="mt-2 max-w-prose text-body text-md-on-surface-variant">
                            {{ $t('message.manage_groups_legend')}}
                        </p>
                    </div>
                    <RouterLink class="md-btn md-btn-tonal" :to="{ name: 'createGroup' }">
                        <LucideCirclePlus /> {{ $t('link.create_group') }}
                    </RouterLink>
                </div>
                <div v-if="!groups.isEmpty" class="mt-8 animate-enter pb-8">
                    <ul id="dv" class="flex flex-col gap-2">
                        <li v-for="group in groups.withoutTheAllGroup" :key="group.id" class="group-item md-card flex items-center gap-3 px-4 py-3 hover:shadow-md sm:px-5">
                            <span class="inline-flex size-10 shrink-0 items-center justify-center rounded-md bg-md-secondary-container text-title text-md-on-secondary-container" aria-hidden="true">
                                {{ group.name.charAt(0).toUpperCase() }}
                            </span>
                            <div class="tfa-content min-w-0 flex-1">
                                <p class="truncate text-title text-md-on-surface">{{ group.name }}</p>
                                <p class="text-label font-normal text-md-on-surface-variant">
                                    {{ $t('message.x_accounts', { count: group.twofaccounts_count }) }}
                                </p>
                            </div>
                            <span v-if="user.preferences.useGroupChips && group.show_in_chips" class="md-badge shrink-0 px-1.5" :title="$t('field.show_in_chips')">
                                <LucideBookmarkCheck />
                            </span>
                            <div class="flex shrink-0 items-center gap-0.5">
                                <!-- edit button -->
                                <RouterLink :to="{ name: 'editGroup', params: { groupId: group.id }}" class="md-icon-btn md-icon-btn-sm" :title="$t('tooltip.edit_group')" :aria-label="$t('tooltip.edit_group')">
                                    <LucidePencil />
                                </RouterLink>
                                <!-- delete icon -->
                                <button type="button" class="md-icon-btn md-icon-btn-sm hover:bg-md-error/10 hover:text-md-error" @click="groups.remove(group.id)" :title="$t('tooltip.delete')" :aria-label="$t('tooltip.delete')">
                                    <LucideTrash2 />
                                </button>
                                <span class="drag-handle is-draggable ml-1 inline-flex cursor-grab touch-none items-center rounded-full p-1.5 text-md-on-surface-variant hover:bg-md-on-surface/8 active:cursor-grabbing">
                                    <LucideGripVertical />
                                </span>
                            </div>
                        </li>
                    </ul>
                    <p class="mt-4 flex items-center justify-end gap-1.5 text-label-sm text-md-on-surface-variant">
                        <LucideInfo class="size-4!" />
                        {{ $t('message.deleting_group_does_not_delete_accounts')}}
                    </p>
                </div>
                <Spinner :isVisible="isFetching && groups.isEmpty" type="list-loading" />
            </ResponsiveWidthWrapper>
        </template>
        <template #footer>
            <VueFooter>
                <template #default>
                    <NavigationButton action="close" @closed="router.push({ name: 'accounts' })" :current-page-title="$t('title.groups')" />
                </template>
            </VueFooter>
        </template>
    </StackLayout>
</template>
