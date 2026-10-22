<script setup>
    import { useNotify, SearchBox } from '@2fauth/ui'
    import twofaccountService from '@/services/twofaccountService'
    import shareService from '@/services/shareService'
    import TwofaccountMedia from '@/components/TwofaccountMedia.vue'
    import { asArray } from '@/composables/helpers'
    import { useI18n } from 'vue-i18n'
    import { useTwofaccounts } from '@/stores/twofaccounts'
    import { useAppSettingsStore } from '@/stores/appSettings'
    import { LucideUsers, LucideCirclePlus, LucideInfo } from '@lucide/vue'

    const props = defineProps({
        twofaccountId: [Number, String]
    })

    const notify = useNotify()
    const { t } = useI18n()
    const twofaccounts = useTwofaccounts()
    const twofaccount = ref(twofaccounts.items.find(account => account.id == props.twofaccountId))
    const appSettings = useAppSettingsStore()

    const activeScopeRef = useTemplateRef('activeScopeRef')

    const isFetching = ref(false)
    const usershares = ref([])
    const userFilter = ref('')
    const shareButtonRefs = ref([])
    const sharingScopes = [
        { id: 'ShareWithAll', label: 'label.share_with_all' },
        { id: 'NotShared', label: 'label.not_shared' },
        { id: 'ShareWithUsers', label: 'label.share_with_specific_users' }
    ]
    const activeSharingScope = ref('NotShared')

    const visibleUsershares = computed(() => {
        return usershares.value.filter(
            user => {
                return user.name.toLowerCase().includes(userFilter.value.toLowerCase())
            }
        )
    })

    const availableSharingScopes = computed(() => {
        return appSettings.enableAllUsersSharingScope
            ? sharingScopes
            : sharingScopes.filter(scope => scope.id != 'ShareWithAll')
    })

    const activeScopeLabel = computed(() => {
        return availableSharingScopes.value.find((scope) => scope.id == activeSharingScope.value).label
    })

    const isSharedWithAll = computed(() => {
        return activeSharingScope.value == 'ShareWithAll'
    })

    const isNotShared = computed(() => {
        return activeSharingScope.value == 'NotShared'
    })

    const isSharedWithUsers = computed(() => {
        return activeSharingScope.value == 'ShareWithUsers'
    })

    onMounted(() => {
        isFetching.value = true
        activeSharingScope.value = 'NotShared'

        twofaccountService.get(props.twofaccountId).then(response => {
            twofaccount.value = response.data
        })

        shareService.getShares(props.twofaccountId).then(response => {
            if (appSettings.enableAllUsersSharingScope && response?.data?.is_shared_with_all) {
                activeSharingScope.value = 'ShareWithAll'
            }
            else {
                usershares.value = asArray(response?.data?.specific_users)
                if (usershares.value.length > 0) {
                    activeSharingScope.value = 'ShareWithUsers'
                }
                else activeSharingScope.value = 'NotShared'
            }
        })
        .finally(() => {
            isFetching.value = false
            toggleSharingButton(activeSharingScope.value)
        })
    })

    /**
     * 
     * @param userId
     */
    function unshareUser(userId) {
        if (confirm(t('confirmation.are_you_sure')) === true) {
            shareService.unshareWithUser(props.twofaccountId, userId).then(response => {
                usershares.value = usershares.value.filter(user => user.id != userId)
            })
        }
    }

    /**
     * 
     * @param newScope 
     */
    function confirmToggleSharing(newScope) {
        if ((activeSharingScope.value == "NotShared" && newScope == "ShareWithUsers")
            || (newScope == "NotShared" && activeSharingScope.value == "ShareWithUsers" && usershares.value.length == 0)) {
            toggleSharing(newScope)
        }
        else if (confirm(t('confirmation.toggle_sharing_setting')) === true) {
            toggleSharing(newScope)
        }
    }

    /**
     * 
     * @param newScope 
     */
    function toggleSharing(newScope) {
        isFetching.value = true
        let sharePromise

        switch (newScope) {
            case "ShareWithAll":
                sharePromise = shareService.shareWithAll(props.twofaccountId)
                break

            case "NotShared":
                sharePromise = shareService.unshare(props.twofaccountId)
                break

            case "ShareWithUsers":
                if (activeSharingScope.value == "ShareWithAll") {
                    sharePromise = shareService.unshare(props.twofaccountId)
                }
                else sharePromise = Promise.resolve(true)
                break

            default:
                notify.alert({ text: t('error.unsupported_sharing_scope') })
                return
        }

        sharePromise.then(response => {
            activeSharingScope.value = newScope

            if (newScope != "ShareWithUsers") {
                usershares.value = []
            }
            
            toggleSharingButton(newScope)
        })
        .finally(() => {
            isFetching.value = false
        })
    }

    /**
     * 
     * @param newScope 
     */
    function toggleSharingButton(newScope) {
        const btnRef = shareButtonRefs.value.find((btn) => btn.id == 'btn' + newScope)

        activeScopeRef.value.style.setProperty('transform', `translateX(${btnRef.offsetLeft}px)`)
        activeScopeRef.value.style.setProperty('width', `${btnRef.offsetWidth}px`)
        activeScopeRef.value.textContent = btnRef.textContent
    }

</script>

<template>
    <StackLayout>
        <template #content>
            <ResponsiveWidthWrapper>
                <h1 class="md-page-title">
                    {{ $t('heading.sharing_setting') }}
                </h1>
                <div class="mb-6 mt-2 text-body leading-relaxed text-md-on-surface-variant">
                    <p>{{ $t('message.share_account_with_other_users')}}</p>
                    <p>{{ $t('message.shared_account_can_be_viewed_not_full_controlled')}}</p>
                </div>
                <TwofaccountMedia :twofaccount="twofaccount" />
                <!-- sharing scope selector -->
                <div class="toggle-wrapper mb-6 inline-flex max-w-full rounded-full bg-md-surface-container-highest p-1 shadow-inner">
                    <div class="toggle relative">
                        <div class="toggle-buttons flex gap-1">
                            <button
                                v-for="sharingScope in availableSharingScopes"
                                :key="sharingScope.id"
                                ref="shareButtonRefs"
                                :id="'btn' + sharingScope.id"
                                type="button"
                                @click="confirmToggleSharing(sharingScope.id)"
                                class="relative z-[1] h-10 cursor-pointer whitespace-nowrap rounded-full px-4 text-label text-md-on-surface-variant transition-colors duration-200 ease-md hover:bg-md-on-surface/8"
                            >
                                {{ $t(sharingScope.label) }}
                            </button>
                        </div>
                        <label
                            ref="activeScopeRef"
                            class="toggle-active pointer-events-none absolute left-0 top-0 z-[2] inline-flex h-10 items-center justify-center whitespace-nowrap rounded-full px-4 text-label shadow-md transition-[transform,width,background-color] duration-300 ease-md"
                            :class="activeSharingScope == 'NotShared' ? 'bg-md-inverse-surface text-md-inverse-on-surface' : 'bg-md-primary text-md-on-primary'"
                            :aria-busy="isFetching"
                        >{{ $t(activeScopeLabel) }}</label>
                    </div>
                </div>
                <div v-if="isFetching == false" class="animate-enter pb-8">
                    <template v-if="isSharedWithUsers">
                        <RouterLink class="md-btn md-btn-tonal mb-4" :to="{ name: 'shareAccount', params: { twofaccountId: props.twofaccountId } }">
                            <LucideCirclePlus /> {{ $t('link.add_users') }}
                        </RouterLink>
                        <p v-if="usershares.length == 0" class="md-card text-body text-md-on-surface-variant">
                            {{ $t('message.add_your_first_user_to_share_this_account_with') }}
                        </p>
                        <template v-if="usershares.length > 0">
                            <div v-if="usershares.length > 5" class="mb-3">
                                <SearchBox v-model:keyword="userFilter" :hasNoBackground="true" :isSmall="true" />
                            </div>
                            <ul class="md-list">
                                <li v-for="user in visibleUsershares" :key="user.id" class="md-list-item">
                                    <span class="inline-flex size-10 shrink-0 items-center justify-center rounded-full bg-md-primary-container text-title text-md-on-primary-container" aria-hidden="true">
                                        {{ user.name.charAt(0).toUpperCase() }}
                                    </span>
                                    <div class="min-w-0 flex-1">
                                        <p class="truncate text-title text-md-on-surface">{{ user.name }}</p>
                                        <p class="text-label-sm text-md-on-surface-variant">{{ $t('message.shared_since_x', { date: user.is_shared_since }) }}</p>
                                    </div>
                                    <!-- revoke icon -->
                                    <button type="button" class="md-btn md-btn-danger-text md-btn-xs" @click="unshareUser(user.id)" :title="$t('tooltip.revoke')">
                                        {{ $t('label.revoke') }}
                                    </button>
                                </li>
                            </ul>
                        </template>
                    </template>
                    <div v-else-if="appSettings.enableAllUsersSharingScope && isSharedWithAll == true" class="md-card flex gap-4">
                        <span class="inline-flex size-11 shrink-0 items-center justify-center rounded-md bg-md-primary-container text-md-on-primary-container">
                            <LucideUsers />
                        </span>
                        <div>
                            <p class="text-title text-md-on-surface">{{ $t('message.is_shared_with_all_users') }}</p>
                            <p class="mt-1 text-label font-normal text-md-on-surface-variant">{{ $t('message.is_shared_with_all_users_legend') }}</p>
                        </div>
                    </div>
                    <div v-else class="md-card flex flex-col gap-2 text-body text-md-on-surface-variant">
                        <p v-if="appSettings.enableAllUsersSharingScope">{{ $t('message.all_users_meaning') }}</p>
                        <p>{{ $t('message.selected_users_meaning') }}</p>
                    </div>
                    <p class="mt-4 flex items-center justify-end gap-1.5 text-label-sm text-md-on-surface-variant">
                        <LucideInfo class="size-4!" />
                        {{ $t('message.you_can_toggle_sharing_setting_at_any_time')}}
                    </p>
                </div>
                <Spinner v-else :isVisible="true" type="list-loading" />
            </ResponsiveWidthWrapper>
        </template>
        <template #footer>
            <VueFooter>
                <template #default>
                    <NavigationButton action="close" @closed="router.push({ name: 'accounts' })" :current-page-title="$t('title.accountSharing')" />
                </template>
            </VueFooter>
        </template>
    </StackLayout>
</template>
