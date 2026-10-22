<script setup>
    import twofaccountService from '@/services/twofaccountService'
    import shareService from '@/services/shareService'
    import DestinationGroupSelector from '@/components/DestinationGroupSelector.vue'
    import Toolbar from '@/components/Toolbar.vue'
    import ActionButtons from '@/components/ActionButtons.vue'
    import ExportButtons from '@/components/ExportButtons.vue'
    import { useUserStore } from '@/stores/user'
    import {
        useNotify,
        SearchBox,
        GroupCallToSwitch,
        GroupChips,
        GroupSwitch,
        OtpDisplay,
        Dots,
        DotsController,
        useVisiblePassword
    } from '@2fauth/ui'
    import { useAppSettingsStore } from '@/stores/appSettings'
    import { useBusStore } from '@/stores/bus'
    import { useTwofaccounts } from '@/stores/twofaccounts'
    import { useGroups } from '@/stores/groups'
    import { useSortable, moveArrayElement } from '@vueuse/integrations/useSortable'
    import { useI18n } from 'vue-i18n'
    import { useErrorHandler } from '@2fauth/stores'
    import { LucideArrowRightLeft, LucideChevronUp, LucideCircleAlert, LucideEllipsisVertical, LucideEye, LucideEyeOff, LucideFolderPlus, LucideGripVertical, LucideHistory, LucidePencil, LucideQrCode, LucideSettings2, LucideShare2, LucideTrash2, LucideUserCheck, LucideUserPen, LucideUserPlus, LucideUsers, LucideX } from '@lucide/vue'

    const errorHandler = useErrorHandler()
    const { t } = useI18n()
    const $2fauth = inject('2fauth')
    const router = useRouter()
    const notify = useNotify()
    const user = useUserStore()
    const bus = useBusStore()
    const { copy, copied } = useClipboard({ legacy: true })
    const twofaccounts = useTwofaccounts()
    const groups = useGroups()
    const appSettings = useAppSettingsStore()

    const showOtpInModal = ref(false)
    const showExportFormatSelector = ref(false)
    const showGroupSwitch = ref(false)
    const showDestinationGroupSelector = ref(false)
    const isDragging = ref(false)
    const renewedPeriod = ref(null)
    const revealPassword = ref(null)
    const opacities = ref({})
    const showFooterMenu = ref(false)
    const visibleAccount = ref(null)
    const showActionsFor = ref(null)

    const otpDisplay = ref(null)
    const accountParams = ref({
        otp_type: '',
        account: '',
        service: '',
        icon: '',
        secret: '',
        digits: null,
        algorithm: '',
        period: null,
        counter: null,
        image: ''
    })
    const dotsControllers = ref([])
    const dotsRefs = ref([])

    let stopSortable

    watch(showOtpInModal, (val) => {
        if (val == false) {
            otpDisplay.value?.clearOTP()
        }
    })

    watch(
        () => twofaccounts.items,
        (val) => {
            stopSortable
            if (bus.inManagementMode) {
                setSortable()
            }
        }
    )

    watch(
        () => bus.inManagementMode,
        (val) => {
            stopSortable
            if (val) {
                setSortable()
            }
        }
    )

    /**
     * Returns whether or not the accounts should be displayed
    */
    const showAccounts = computed(() => {
        return !twofaccounts.isEmpty && !showGroupSwitch.value && !showDestinationGroupSelector.value
    })

    onMounted(async () => {
        // This SFC is reached only if the user has some twofaccounts (see the starter middleware).
        // This allows to display accounts without latency.
        //
        // We sync the store with the backend again to
        if (! user.preferences.getOtpOnRequest) {
            updateTotps()
        }
        else {
            twofaccounts.fetch().then(() => {
                if (twofaccounts.backendWasNewer) {
                    notify.info({ text: t('notification.data_refreshed_to_reflect_server_changes'), duration: 10000 })
                }
            })
        }
        groups.fetch()
    })

    // Enables the sortable behaviour of the twofaccounts list
    function setSortable() {
        const { stop } = useSortable('#dv', twofaccounts.filtered, {
            animation: 200,
            handle: '.drag-handle',
            onUpdate: (e) => {
                const movedId = twofaccounts.filtered[e.oldIndex].id
                const inItemsIndex = twofaccounts.items.findIndex(item => item.id == movedId)
                moveArrayElement(twofaccounts.items, inItemsIndex, e.newIndex)

                nextTick(() => {
                    twofaccounts.saveOrder('free')
                })
            }
        })
        stopSortable = stop
    }

    /**
     * Runs some updates after accounts assignement/withdrawal
     */
    function postGroupAssignementUpdate() {
        // we fetch the accounts again to prevent the js collection being
        // desynchronize from the backend php collection
        twofaccounts.fetch()
        twofaccounts.selectNone()
        showDestinationGroupSelector.value = false
        notify.success({ text: t('notification.accounts_moved') })
    }

    /**
     * Shows rotating OTP for the provided account
     */
    function showOTP(account) {
        // Data that should be displayed quickly by the OtpDisplay
        // component are passed using props.
        accountParams.value.otp_type = account.otp_type
        accountParams.value.service = account.service
        accountParams.value.account = account.account
        accountParams.value.icon = account.icon

        visibleAccount.value = account

        nextTick().then(() => {
            showOtpInModal.value = true
            otpDisplay.value.show(account.id);
        })
    }

    /**
     * Shows an OTP in a modal or directly copies it to the clipboard
     */
    function showOrCopy(account) {
        // In Management mode, clicking an account does not show/copy, it selects the account
        if(bus.inManagementMode) {
            selectAccount(account)
        }
        else {
            if (!user.preferences.getOtpOnRequest && account.otp_type.includes('totp')) {
                copyToClipboard(account.otp.password)
            }
            else {
                showOTP(account)
            }
        }
    }

    /**
     * Copies a string to the clipboard
     */
    function copyToClipboard (password) {
        copy(password)

        if (copied) {
            if (user.preferences.kickUserAfter == -1) {
                user.logout({ kicked: true})
            }
            if (user.preferences.clearSearchOnCopy) {
                twofaccounts.filter = ''
            }
            if (user.preferences.viewDefaultGroupOnCopy) {
                user.preferences.activeGroup = user.preferences.defaultGroup == -1 ?
                    user.preferences.activeGroup
                    : user.preferences.defaultGroup
            }
            
            notify.success({ text: t('notification.copied_to_clipboard') })
        }
    }

    /**
     * Gets a fresh OTP from backend and copies it
     */
    async function getAndCopyOTP(account) {
        twofaccountService.getOtpById(account.id).then(response => {
            let otp = response.data
            copyToClipboard(otp.password)

            if (otp.otp_type == 'hotp') {
                let hotpToIncrement = twofaccounts.items.find((acc) => acc.id == account.id)
                
                // TODO : à koi ça sert ?
                if (hotpToIncrement != undefined) {
                    hotpToIncrement.counter = otp.counter
                }
            }
        })
    }

    /**
     * Dragging start
     */
    function onStart() {
        isDragging.value = true
    }

    /**
     * Dragging end
     */
    function onEnd() {
        isDragging.value = false
    }

    /**
     * Turns dots On for all dots components that match the provided period
     */
     function turnDotsOn(period, stepIndex) {
        dotsRefs.value
            .filter((dots) => dots.props.period == period || period == undefined)
            .forEach((dot) => {
                dot.turnOn(stepIndex)
        })

        // The opacity-step-* utilities are defined from 0 to 10 only.
        // TODO: Make the opacity refiner support variable number of steps (not only 10, see step_count)
        opacities.value[period] = 'opacity-step-' + stepIndex
    }

    /**
     * Turns dots Off for all dots components that match the provided period
     */
    function turnDotsOff(period) {
        dotsRefs.value
            .filter((dots) => dots.props.period == period || period == undefined)
            .forEach((dot) => {
                dot.turnOff()
        })
    }

    /**
     * Updates "Always On" OTPs for all TOTP accounts and (re)starts dots controllers
     */
    async function updateTotps(period) {
        let fetchPromise

        if (period == undefined) {
            renewedPeriod.value = -1
            fetchPromise = twofaccountService.getAll(true)
        } else {
            renewedPeriod.value = period
            fetchPromise = twofaccountService.getByIds(twofaccounts.accountIdsWithPeriod(period).join(','), true)
        }
        
        turnDotsOff(period)

        // We replace the current on screen passwords with the next_password to avoid having loaders.
        // The next_password will be confirmed with a new request to be synced with the backend no matter what.
        const totpAccountsWithNextPasswordInThePeriod = twofaccounts.items.filter((account) => account.otp_type.includes('totp') && account.period == period && account.otp.next_password)
        
        if (totpAccountsWithNextPasswordInThePeriod.length > 0) {
            totpAccountsWithNextPasswordInThePeriod.forEach((account) => {
                const index = twofaccounts.items.findIndex(acc => acc.id === account.id)
                if (twofaccounts.items[index].otp.next_password) {
                    twofaccounts.items[index].otp.password = twofaccounts.items[index].otp.next_password
                }
            })
            turnDotsOn(period, 0)
        }

        fetchPromise.then(response => {
            let generatedAt = 0

            // twofaccounts TOTP updates
            response.data.forEach((account) => {
                if (account.otp_type.includes('totp')) {
                    const index = twofaccounts.items.findIndex(acc => acc.id === account.id)
                    if (twofaccounts.items[index] == undefined) {
                        twofaccounts.items.push(account)
                    }
                    else twofaccounts.items[index].otp = account.otp
                    generatedAt = account.otp.generated_at
                }
            })

            // dots controllers restart at new timestamp
            dotsControllers.value.forEach((dotsController) => {
                if (dotsController.props.period == period || period == undefined) {
                    nextTick().then(() => {
                        dotsController.startStepping(generatedAt)
                    })
                }
            })
        })
        .finally(() => {
            renewedPeriod.value = null
        })
    }

    /**
     * Deletes given account
     */
    async function deleteAccount(account) {
        twofaccounts.selectNone()
        selectAccount(account)
        await twofaccounts.deleteSelected()

        if (twofaccounts.isEmpty) {
            bus.inManagementMode = false
            router.push({ name: 'start' })
        }

        nextTick().then(() => {
            showOtpInModal.value = false
            showFooterMenu.value = false
        })
    }

    /**
     * Deletes selected accounts
     */
    async function deleteAccounts() {
        await twofaccounts.deleteSelected()

        if (twofaccounts.isEmpty) {
            bus.inManagementMode = false
            router.push({ name: 'start' })
        }
    }

    /**
     * Exits from the Management mode
     */
    function exitManagementMode()
    {
        bus.inManagementMode = false
        twofaccounts.selectNone()
    }

    /**
     * Saves the active group to the backends
     */
    // TODO : Delegate this to the store or a global watcher
    function saveActiveGroup(newActiveGroupId) {
        // When invoked by GroupSwitch event,  newActiveGroupId should
        // be the same as user.preferences.activeGroup because of the v-model
        // binding.
        // When invoked by OtpDisplay we have to update the user preference too.
        if (user.preferences.activeGroup != newActiveGroupId) {
            user.preferences.activeGroup = newActiveGroupId
        }

        if( user.preferences.rememberActiveGroup) {
            userService.updatePreference('activeGroup', user.preferences.activeGroup)
        }
    }

    /**
     * Initial used as a fallback avatar when an account has no icon
     */
    function initialOf(account) {
        return (account.service || account.account || '?').trim().charAt(0).toUpperCase()
    }

    const isGrid = computed(() => user.preferences.displayMode === 'grid')

    /**
     * Selects an account
     */
    function selectAccount(account) {
        twofaccounts.select(account.id)
    }

    /**
     * Unshare selected accounts
     */
    async function bulkUnshare() {
        if (appSettings.enableSharing && confirm(t('confirmation.bulk_unshare')) === true) {
            twofaccounts.selectedIds.forEach((accountId) => {
                const account = twofaccounts.getById(accountId)

                if (account != undefined && (account.is_shared_with_all || account.is_shared)) {
                    shareService.unshare(accountId).then(response => {
                        try {
                            const index = twofaccounts.items.findIndex(acc => acc.id === accountId)
                            delete twofaccounts.items[index].is_shared
                            delete twofaccounts.items[index].is_shared_with_all
                        } catch (error) {
                            console.error(error)
                        }
                    })
                }
            })
        }
    }

</script>

<template>
    <div>
        <StackLayout :shouldShrinkSubheader="user.preferences.useGroupChips">
            <template #header>
                <!-- header -->
                <div class="header px-4 pb-3 pt-5 sm:pt-8" v-if="showAccounts || showGroupSwitch">
                    <div class="mx-auto w-full max-w-md">
                        <!-- search -->
                        <SearchBox v-model:keyword="twofaccounts.filter" :placeholder="$t('label.search')" />
                    </div>
                </div>
            </template>
            <template #subheader v-if="! showDestinationGroupSelector">
                <div class="pb-3">
                    <!-- toolbar -->
                    <Toolbar v-if="bus.inManagementMode"
                        v-model:sortOrder="user.preferences.sortOrder"
                        :selectedCount="twofaccounts.selectedCount"
                        @clear-selected="twofaccounts.selectNone()"
                        @select-all="twofaccounts.selectAll()"
                        @sort-asc="twofaccounts.sortAsc()"
                        @sort-desc="twofaccounts.sortDesc()">
                    </Toolbar>
                    <!-- group switch toggle -->
                    <div v-else class="flex justify-center">
                        <button v-if="showGroupSwitch" type="button" id="btnHideGroupSwitch" :title="$t('tooltip.hide_group_selector')" tabindex="1" class="md-btn md-btn-neutral md-btn-sm" @click.stop="showGroupSwitch = !showGroupSwitch">
                            {{ $t('label.select_accounts_to_show') }}
                            <LucideChevronUp />
                        </button>
                        <template v-else>
                            <GroupChips v-if="user.preferences.useGroupChips"
                                class="w-full"
                                v-model:active-group="user.preferences.activeGroup"
                                v-model:show-group-switch="showGroupSwitch"
                                :groups="groups.items"
                                :filteredCount="twofaccounts.filteredCount"
                                :useShare="appSettings.enableSharing"
                                :useShareAllScope="appSettings.enableAllUsersSharingScope"
                                :useVirtualChips="user.preferences.showVirtualChips"
                                @active-group-changed="saveActiveGroup" />
                            <GroupCallToSwitch v-else
                                v-model:show-group-switch="showGroupSwitch"
                                :activeGroup="user.preferences.activeGroup"
                                :currentGroup="groups.current"
                                :filteredCount="twofaccounts.filteredCount"
                                :useShare="appSettings.enableSharing" />
                        </template>
                    </div>
                </div>
            </template>
            <template #content>
                <GroupSwitch
                    v-if="showGroupSwitch"
                    v-model:is-visible="showGroupSwitch"
                    v-model:active-group="user.preferences.activeGroup"
                    :groups="groups.items"
                    :useShare="appSettings.enableSharing"
                    :useShareAllScope="appSettings.enableAllUsersSharingScope"
                    @active-group-changed="saveActiveGroup">
                    <div v-if="groups.items.length < 2" class="flex flex-col items-center gap-4 text-center">
                        <p class="text-body text-md-on-surface-variant">{{ $t('message.no_group_yet') }}</p>
                        <RouterLink :to="{ name: 'createGroup' }" class="md-btn md-btn-tonal">
                            <LucideFolderPlus />
                            {{ $t('link.create_your_first_group') }}
                        </RouterLink>
                    </div>
                </GroupSwitch>
                <DestinationGroupSelector
                    v-if="showDestinationGroupSelector"
                    v-model:showDestinationGroupSelector="showDestinationGroupSelector"
                    v-model:selectedAccountsIds="twofaccounts.selectedIds"
                    :groups="groups.items"
                    @accounts-moved="postGroupAssignementUpdate">
                </DestinationGroupSelector>
                <!-- show accounts list -->
                <div class="accounts-container mx-auto w-full max-w-6xl pb-8 lg:px-6" v-if="showAccounts" :class="{ 'is-edit-mode': bus.inManagementMode }">
                    <!-- accounts -->
                    <div
                        id="dv"
                        class="accounts grid gap-3"
                        :class="isGrid
                            ? 'grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 sm:gap-4'
                            : (bus.inManagementMode ? 'grid-cols-1 lg:grid-cols-2' : 'grid-cols-1 md:grid-cols-2 xl:grid-cols-3')"
                    >
                        <div
                            v-for="account in twofaccounts.filtered"
                            :key="account.id"
                            class="group relative rounded-lg bg-md-surface-container shadow-sm transition-[box-shadow,transform,background-color] duration-300 ease-md hover:shadow-md"
                            :class="[
                                isGrid ? 'tfa-grid flex flex-col items-center px-3 pb-4 pt-5 text-center hover:scale-[1.02]' : 'tfa-list flex items-center gap-3 px-3 py-2.5 sm:px-4',
                                bus.inManagementMode && twofaccounts.selectedIds.includes(account.id) ? 'bg-md-secondary-container ring-2 ring-md-primary' : '',
                            ]"
                        >
                            <!-- checkbox -->
                            <transition name="slideCheckbox">
                                <div
                                    v-if="bus.inManagementMode"
                                    class="tfa-checkbox flex shrink-0 items-center"
                                    :class="isGrid ? 'absolute left-3 top-3' : 'pl-1 pr-1'"
                                >
                                    <input
                                        class="md-checkbox"
                                        :id="'ckb_' + account.id"
                                        :value="account.id"
                                        type="checkbox"
                                        :name="'ckb_' + account.id"
                                        v-model="twofaccounts.selectedIds"
                                        :aria-label="account.service"
                                    />
                                </div>
                            </transition>
                            <!-- Account, service, sharing badges -->
                            <div
                                tabindex="0"
                                class="tfa-cell tfa-content flex min-w-0 flex-1 cursor-pointer items-center gap-3 rounded-md outline-none focus-visible:ring-2 focus-visible:ring-md-primary"
                                :class="{ 'flex-col gap-3': isGrid }"
                                @click.exact="showOrCopy(account)"
                                @keyup.enter="showOrCopy(account)"
                                @click.ctrl="getAndCopyOTP(account)"
                                role="button"
                            >
                                <template v-if="user.preferences.showAccountsIcons">
                                    <img
                                        v-if="account.icon"
                                        role="presentation"
                                        class="tfa-icon md-account-icon transition-transform duration-300 ease-md group-hover:scale-105"
                                        :class="isGrid ? 'size-16 rounded-md p-2' : 'size-11'"
                                        :src="$2fauth.config.subdirectory + '/storage/icons/' + account.icon"
                                        alt=""
                                    >
                                    <img
                                        v-else-if="account.icon == null"
                                        role="presentation"
                                        class="tfa-icon md-account-icon"
                                        :class="isGrid ? 'size-16 rounded-md p-3' : 'size-11 p-2'"
                                        :src="$2fauth.config.subdirectory + '/storage/noicon.svg'"
                                        alt=""
                                    >
                                    <span
                                        v-else
                                        aria-hidden="true"
                                        class="md-account-icon bg-md-primary-container font-medium text-md-on-primary-container"
                                        :class="isGrid ? 'size-16 rounded-md text-title-lg' : 'size-11 text-title'"
                                    >{{ initialOf(account) }}</span>
                                </template>
                                <div class="tfa-text min-w-0 max-w-full" :class="{ 'flex-1': !isGrid }">
                                    <p class="flex items-center gap-1.5 truncate text-title text-md-on-surface" :class="{ 'justify-center': isGrid }">
                                        <span class="truncate">{{ account.service ? account.service : $t('message.no_service') }}</span>
                                        <LucideCircleAlert class="shrink-0 text-md-error" v-if="account.account === $t('error.indecipherable')" />
                                    </p>
                                    <p class="mt-0.5 flex items-center gap-1.5 text-label font-normal text-md-on-surface-variant" :class="{ 'justify-center': isGrid }">
                                        <span v-if="appSettings.enableSharing && account.is_borrowed" :title="$t('tooltip.this_account_is_shared_by_x_with_you', { username: account.borrowed_by })" class="md-badge h-5 shrink-0 px-2">
                                            @{{ bus.inManagementMode ? account.borrowed_by : '' }}
                                        </span>
                                        <span v-else-if="appSettings.enableSharing && account.is_shared" :title="$t('tooltip.this_account_is_shared_with_specific_users')" class="md-badge h-5 shrink-0 px-1.5">
                                            <LucideUserCheck />
                                        </span>
                                        <span v-else-if="appSettings.enableSharing && appSettings.enableAllUsersSharingScope && account.is_shared_with_all" :title="$t('tooltip.this_account_is_shared_with_all')" class="md-badge h-5 shrink-0 px-1.5">
                                            <LucideUsers />
                                        </span>
                                        <span class="truncate">{{ account.account }}</span>
                                    </p>
                                </div>
                            </div>
                            <!-- actions block -->
                            <template v-if="appSettings.enableSharing && user.preferences.getOtpOnRequest == false && !bus.inManagementMode && showActionsFor === account.id">
                                <transition name="popLater">
                                    <div v-if="!bus.inManagementMode" class="action-container flex shrink-0 flex-wrap items-center justify-end gap-1.5" :class="{ 'mt-3 justify-center': isGrid }">
                                        <template v-if="account.is_shared || account.is_shared_with_all">
                                            <RouterLink v-if="account.is_shared" :to="{ name: 'shareAccount', params: { twofaccountId: account.id } }" class="md-icon-btn md-icon-btn-sm md-icon-btn-tonal" :title="$t('tooltip.share_with_new_users')" :aria-label="$t('tooltip.share_with_new_users')">
                                                <LucideUserPlus />
                                            </RouterLink>
                                            <RouterLink :to="{ name: 'accountSharing', params: { twofaccountId: account.id }}" class="md-icon-btn md-icon-btn-sm md-icon-btn-tonal" :title="$t('tooltip.edit_sharing')" :aria-label="$t('tooltip.edit_sharing')">
                                                <LucideUserPen />
                                            </RouterLink>
                                        </template>
                                        <RouterLink v-else :to="{ name: 'accountSharing', params: { twofaccountId: account.id } }" class="md-btn md-btn-tonal md-btn-xs" :title="$t('tooltip.share_this_account')">
                                            <LucideShare2 />
                                            {{ $t('label.share') }}
                                        </RouterLink>
                                        <RouterLink id="lnkTransferOwnership" :to="{ name: 'transferOwnership', params: { twofaccountId: account.id }}" class="md-btn md-btn-tonal md-btn-xs" :title="$t('link.transfer_ownership')">
                                            <LucideArrowRightLeft />
                                            {{ $t('label.transfer') }}
                                        </RouterLink>
                                    </div>
                                </transition>
                            </template>
                            <template v-else>
                                <!-- reveal password button -->
                                <transition name="popLater" v-if="account.otp_type.includes('totp') && user.preferences.showOtpAsDot && user.preferences.revealDottedOTP">
                                    <div v-show="user.preferences.getOtpOnRequest == false && !bus.inManagementMode" class="shrink-0" :class="{ 'absolute left-1.5 top-1.5': isGrid }">
                                        <button
                                            type="button"
                                            class="md-icon-btn md-icon-btn-sm"
                                            @click.stop="revealPassword = revealPassword == account.id ? null : account.id"
                                            :aria-pressed="revealPassword == account.id"
                                            :aria-label="revealPassword == account.id ? $t('tooltip.hide_password') : $t('tooltip.reveal_password')"
                                        >
                                            <LucideEye v-if="revealPassword == account.id" />
                                            <LucideEyeOff v-else />
                                        </button>
                                    </div>
                                </transition>
                                <!-- always On TOTP or HOTP button -->
                                <transition name="popLater">
                                    <div
                                        v-show="user.preferences.getOtpOnRequest == false && !bus.inManagementMode"
                                        class="flex shrink-0 flex-col"
                                        :class="isGrid ? 'mt-3 items-center' : 'items-end'"
                                    >
                                        <template v-if="account.otp != undefined">
                                            <button
                                                type="button"
                                                class="always-on-otp cursor-pointer whitespace-nowrap rounded-sm px-2 font-mono text-title-lg leading-tight font-medium tabular-nums tracking-wide text-md-primary transition-[background-color,transform] duration-200 ease-md hover:bg-md-primary/10 active:scale-95"
                                                @click="copyToClipboard(account.otp.password)"
                                                :title="$t('tooltip.copy_to_clipboard')"
                                            >
                                                {{ useVisiblePassword(
                                                        account.otp.password,
                                                        user.preferences.formatPassword,
                                                        user.preferences.formatPasswordBy,
                                                        user.preferences.showOtpAsDot,
                                                        user.preferences.revealDottedOTP && revealPassword == account.id
                                                    )
                                                }}
                                            </button>
                                            <div v-if="account.otp_type.includes('totp')" class="flex h-3 items-center px-2">
                                                <Dots
                                                    ref="dotsRefs"
                                                    :isCondensed="true"
                                                    :period="account.period" />
                                            </div>
                                            <button
                                                v-if="user.preferences.showNextOtp"
                                                type="button"
                                                class="always-on-otp cursor-pointer whitespace-nowrap rounded-xs px-2 font-mono text-label-sm tabular-nums text-md-on-surface-variant transition-[background-color,opacity] duration-300 ease-md hover:bg-md-primary/10"
                                                :class="opacities[account.period]"
                                                @click="copyToClipboard(account.otp.next_password)"
                                                :title="$t('tooltip.copy_next_password')"
                                            >
                                                {{ useVisiblePassword(
                                                        account.otp.next_password,
                                                        user.preferences.formatPassword,
                                                        user.preferences.formatPasswordBy,
                                                        user.preferences.showOtpAsDot,
                                                        user.preferences.revealDottedOTP && revealPassword == account.id
                                                    )
                                                }}
                                            </button>
                                        </template>
                                        <!-- get hotp button -->
                                        <button v-else type="button" class="md-btn md-btn-tonal md-btn-xs" @click="showOTP(account)" :title="$t('tooltip.import_this_account')">
                                            {{ $t('label.generate') }}
                                        </button>
                                    </div>
                                </transition>
                            </template>
                            <!-- Manage mode buttons -->
                            <transition name="fadeInOut">
                                <div class="tfa-edit flex shrink-0 items-center gap-1" :class="{ 'mt-3': isGrid }" v-if="bus.inManagementMode && appSettings.enableSharing && user.preferences.activeGroup == -2">
                                    <!-- new user share button -->
                                    <RouterLink v-if="account.is_shared" :to="{ name: 'shareAccount', params: { twofaccountId: account.id } }" class="md-icon-btn md-icon-btn-sm" :title="$t('tooltip.share_with_new_users')" :aria-label="$t('tooltip.share_with_new_users')">
                                        <LucideUserPlus />
                                    </RouterLink>
                                    <!-- manage sharing button -->
                                    <RouterLink :to="{ name: 'accountSharing', params: { twofaccountId: account.id }}" class="md-icon-btn md-icon-btn-sm" :title="$t('tooltip.edit_sharing')" :aria-label="$t('tooltip.edit_sharing')">
                                        <LucideUserPen />
                                    </RouterLink>
                                </div>
                                <div class="tfa-edit flex shrink-0 items-center gap-0.5" :class="{ 'mt-3': isGrid }" v-else-if="bus.inManagementMode && ! account.is_borrowed">
                                    <!-- edit button -->
                                    <RouterLink :to="{ name: 'editAccount', params: { twofaccountId: account.id }}" class="md-icon-btn md-icon-btn-sm" :title="$t('tooltip.edit_account')" :aria-label="$t('link.edit')">
                                        <LucidePencil />
                                    </RouterLink>
                                    <!-- show qrcode button -->
                                    <RouterLink :to="{ name: 'showQRcode', params: { twofaccountId: account.id }}" class="md-icon-btn md-icon-btn-sm" :title="$t('tooltip.show_qrcode')" :aria-label="$t('tooltip.show_qrcode')">
                                        <LucideQrCode />
                                    </RouterLink>
                                    <!-- log generation button -->
                                    <RouterLink :to="{ name: 'otpLogs', params: { twofaccountId: account.id }}" class="md-icon-btn md-icon-btn-sm" :title="$t('link.otp_generation_log')" :aria-label="$t('link.otp_generation_log')">
                                        <LucideHistory />
                                    </RouterLink>
                                </div>
                            </transition>
                            <!-- drag handle -->
                            <transition name="fadeInOut">
                                <div
                                    v-if="bus.inManagementMode"
                                    class="drag-handle tfa-dots flex shrink-0 cursor-grab touch-none items-center rounded-full p-1.5 text-md-on-surface-variant hover:bg-md-on-surface/8 active:cursor-grabbing"
                                    :class="{ 'absolute right-2 top-2': isGrid }"
                                >
                                    <LucideGripVertical />
                                </div>
                            </transition>
                            <!-- actions block toggling -->
                            <transition name="popLater">
                                <div
                                    v-if="appSettings.enableSharing && user.preferences.getOtpOnRequest == false && !bus.inManagementMode && ! account.is_borrowed"
                                    class="shrink-0"
                                    :class="{ 'absolute right-1.5 top-1.5': isGrid }"
                                >
                                    <button
                                        type="button"
                                        class="md-icon-btn md-icon-btn-sm"
                                        @click="showActionsFor = showActionsFor === account.id ? null : account.id"
                                        :aria-expanded="showActionsFor === account.id"
                                        :aria-label="$t('label.actions')"
                                    >
                                        <LucideX v-if="showActionsFor === account.id" />
                                        <LucideEllipsisVertical v-else />
                                    </button>
                                </div>
                            </transition>
                        </div>
                    </div>
                </div>
            </template>
            <template #footer v-if="showGroupSwitch">
                <VueFooter :show-buttons="true">
                    <!-- Create group buttons -->
                    <RouterLink class="md-btn md-btn-tonal" :to="{ name: 'createGroup' }" :title="$t('tooltip.create_new_group')">
                        <LucideFolderPlus />
                        {{ $t('label.new') }}
                    </RouterLink>
                    <!-- Manage group buttons -->
                    <RouterLink class="md-btn md-btn-tonal" :to="{ name: 'groups' }"  :title="$t('tooltip.manage_your_groups')">
                        <LucideSettings2 />
                        {{ $t('link.manage') }}
                    </RouterLink>
                    <NavigationButton action="close" :use-link-tag="false" @closed="showGroupSwitch = false" />
                </VueFooter>
            </template>
            <template #footer v-else-if="! showDestinationGroupSelector">
                <VueFooter v-if="bus.inManagementMode && !showDestinationGroupSelector">
                    <template #default>
                        <ActionButtons
                            v-model:inManagementMode="bus.inManagementMode"
                            :areDisabled="twofaccounts.hasNoneSelected"
                            :canUnshare="twofaccounts.hasOnlySharedSelected"
                            :showUnshare="appSettings.enableSharing"
                            :canDelete="!twofaccounts.hasBorrowedSelected"
                            :canExport="!twofaccounts.hasBorrowedSelected"
                            @move-button-clicked="showDestinationGroupSelector = true"
                            @delete-button-clicked="deleteAccounts"
                            @export-button-clicked="showExportFormatSelector = true"
                            @unshare-button-clicked="bulkUnshare">
                        </ActionButtons>
                    </template>
                    <template #subpart>
                        <button type="button" id="lnkExitEdit" class="md-btn md-btn-text md-btn-sm" @click.stop="exitManagementMode">{{ $t('label.done') }}</button>
                    </template>
                </VueFooter>
                <VueFooter v-else>
                    <template #default>
                        <ActionButtons v-model:inManagementMode="bus.inManagementMode" />
                    </template>
                </VueFooter>
            </template>
        </StackLayout>
        <!-- export modal -->
        <Modal v-model:is-active="showExportFormatSelector">
            <ExportButtons
                @export-twofauth-format="twofaccounts.export()"
                @export-otpauth-format="twofaccounts.export('otpauth')">
            </ExportButtons>
        </Modal>
        <!-- otp modal -->
        <Modal v-model:is-active="showOtpInModal" v-model:show-footer-menu="showFooterMenu">
            <template #default>
                <OtpDisplay
                    ref="otpDisplay"
                    :accountParams="accountParams"
                    :preferences="user.preferences"
                    :twofaccountService="twofaccountService"
                    :iconPathPrefix="$2fauth.config.subdirectory"
                    @please-close-me="showOtpInModal = false; showFooterMenu = false"
                    @please-clear-search="twofaccounts.filter = ''"
                    @kickme="user.logout({ kicked: true})"
                    @please-update-activeGroup="saveActiveGroup"
                    @otp-copied-to-clipboard="notify.success({ text: t('notification.copied_to_clipboard') })"
                    @error="(error) => errorHandler.show(error)"
                />
            </template>
            <template v-if="showOtpInModal && ! visibleAccount.is_borrowed" #footer-submenu>
                <ul class="flex flex-col">
                    <!-- manage sharing link -->
                    <li v-if="appSettings.enableSharing">
                        <router-link id="lnkManageSharing" :to="{ name: 'accountSharing', params: { twofaccountId: visibleAccount.id }}" class="md-menu-item">
                            <LucideUserPen />
                            {{ $t('link.manage_sharing') }}
                        </router-link>
                    </li>
                    <!-- transfer ownership link -->
                    <li v-if="appSettings.enableSharing">
                        <router-link id="lnkTransferOwnership" :to="{ name: 'transferOwnership', params: { twofaccountId: visibleAccount.id }}" class="md-menu-item">
                            <LucideArrowRightLeft />
                            {{ $t('link.transfer_ownership') }}
                        </router-link>
                    </li>
                    <!-- otp generation log link -->
                    <li>
                        <router-link id="lnkRead" :to="{ name: 'otpLogs', params: { twofaccountId: visibleAccount.id }}" class="md-menu-item">
                            <LucideHistory />
                            {{ $t('link.otp_generation_log') }}
                        </router-link>
                    </li>
                    <!-- action buttons -->
                    <li class="mt-1 flex items-center justify-center gap-2 border-t border-md-outline-variant/60 pt-2">
                        <router-link id="lnkQrCode" :to="{ name: 'showQRcode', params: { twofaccountId: visibleAccount.id }}" class="md-icon-btn md-icon-btn-tonal" :title="$t('tooltip.show_qrcode')" :aria-label="$t('tooltip.show_qrcode')">
                            <LucideQrCode />
                        </router-link>
                        <router-link id="lnkEdit" :to="{ name: 'editAccount', params: { twofaccountId: visibleAccount.id }}" class="md-icon-btn md-icon-btn-tonal" :title="$t('tooltip.edit_account')" :aria-label="$t('tooltip.edit_account')">
                            <LucidePencil />
                        </router-link>
                        <button id="btnDelete" type="button" @click="deleteAccount(visibleAccount)" class="md-icon-btn bg-md-error-container text-md-on-error-container hover:bg-md-error-container/80" :title="$t('tooltip.delete_account')" :aria-label="$t('tooltip.delete_account')">
                            <LucideTrash2 />
                        </button>
                    </li>
                </ul>
            </template>
            <template #footer-subpart>
                <span v-if="showOtpInModal && appSettings.enableSharing && visibleAccount.is_borrowed" class="text-label text-md-on-surface-variant">
                    {{ $t('message.shared_by_x', { username: visibleAccount.borrowed_by }) }}
                </span>
                <button v-else type="button" id="btnActions" @click="showFooterMenu = !showFooterMenu" class="md-btn md-btn-neutral md-btn-sm" :aria-expanded="showFooterMenu" aria-haspopup="menu">
                    {{ $t('label.actions') }}
                    <LucideChevronUp class="transition-transform duration-300 ease-md" :class="{ 'rotate-180': !showFooterMenu }" />
                </button>
            </template>
        </Modal>
        <!-- dots controllers -->
        <span v-if="!user.preferences.getOtpOnRequest">
            <DotsController
                v-for="period in twofaccounts.periods"
                ref="dotsControllers"
                :key="period.period"
                :autostart="false"
                :period="period.period"
                :generated_at="period.generated_at"
                @stepping-ended="updateTotps(period.period)"
                @stepping-started="turnDotsOn(period.period, $event)"
                @stepped-up="turnDotsOn(period.period, $event)"
            ></DotsController>
        </span>
    </div>
</template>
