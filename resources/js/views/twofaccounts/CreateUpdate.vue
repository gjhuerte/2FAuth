<script setup>
    import Form from '@/components/formElements/Form'
    import QrContentDisplay from '@/components/QrContentDisplay.vue'
    import { FormProtectedField } from '@2fauth/formcontrols'
    import twofaccountService from '@/services/twofaccountService'
    import iconService from '@/services/iconService'
    import { useUserStore } from '@/stores/user'
    import { useTwofaccounts } from '@/stores/twofaccounts'
    import { useGroups } from '@/stores/groups'
    import { useBusStore } from '@/stores/bus'
    import { useNotify, OtpDisplay } from '@2fauth/ui'
    import { useI18n } from 'vue-i18n'
    import { useErrorHandler } from '@2fauth/stores'
    import {
        LucideHardDriveUpload,
        LucideImageUp,
        LucideQrCode,
        LucideWandSparkles,
        LucideRefreshCw,
        LucideChevronDown,
        LucidePlay,
        LucideX,
    } from '@lucide/vue'

    const errorHandler = useErrorHandler()
    const { t } = useI18n()
    const $2fauth = inject('2fauth')
    const router = useRouter()
    const route = useRoute()
    const user = useUserStore()
    const twofaccounts = useTwofaccounts()
    const bus = useBusStore()
    const notify = useNotify()
    const form = reactive(new Form({
        service: '',
        account: '',
        otp_type: '',
        icon: '',
        group_id: defineDefaultGroup(),
        secret: '',
        algorithm: '',
        digits: null,
        counter: null,
        period: null,
        image: '',
    }))
    const qrcodeForm = reactive(new Form({
        qrcode: null
    }))
    const iconForm = reactive(new Form({
        icon: null
    }))
    const iconCollections = [
        { text: 'selfh.st', value: 'selfh', hasVariant: true },
        { text: 'dashboardicons.com', value: 'dashboardicons', hasVariant: true },
        { text: '2fa.directory', value: 'tfa', hasVariant: false },
    ]
    const iconCollectionVariants = {
        selfh: [
            { text: 'label.regular', value: 'regular' },
            { text: 'label.light', value: 'light' },
            { text: 'label.dark', value: 'dark' },
        ],
        dashboardicons: [
            { text: 'label.regular', value: 'regular' },
            { text: 'label.light', value: 'light' },
            { text: 'label.dark', value: 'dark' },
        ],
        tfa: [
            { text: 'label.regular', value: 'regular' },
        ]
    }
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
    const otp_types = [
        { text: 'TOTP', value: 'totp' },
        { text: 'HOTP', value: 'hotp' },
        { text: 'STEAM', value: 'steamtotp' },
    ]
    const digitsChoices = [
        { text: '6', value: 6 },
        { text: '7', value: 7 },
        { text: '8', value: 8 },
        { text: '9', value: 9 },
        { text: '10', value: 10 },
    ]
    const algorithms = [
        { text: 'sha1', value: 'sha1' },
        { text: 'sha256', value: 'sha256' },
        { text: 'sha512', value: 'sha512' },
        { text: 'md5', value: 'md5' },
    ]
    const uri = ref()
    const tempIcon = ref('')
    const showQuickForm = ref(false)
    const showAlternatives = ref(false)
    const showOtpInModal = ref(false)
    const showAdvancedForm = ref(false)
    const ShowTwofaccountInModal = ref(false)
    const showSpinner = ref(false)
    const fetchingLogo = ref(false)
    const iconCollection = ref(user.preferences.iconCollection)
    const iconCollectionVariant = ref(user.preferences.iconVariant)
    const iconPack = ref(user.preferences.iconPack ?? '/')
    const iconPacks = ref([
        { text: 'label.no_available_icon_packs', value: '/' }
    ])
    const hasSomeIconPack = ref(false)
    const isLoading = ref(false)

    // $refs
    const iconInput = ref(null)
    const OtpDisplayForAutoSave = ref(null)
    const OtpDisplayForQuickForm = ref(null)
    const OtpDisplayForAdvancedForm = ref(null)
    const qrcodeInputLabel = ref(null)
    const qrcodeInput = ref(null)
    const iconInputLabel = ref(null)
    
    const props = defineProps({
        twofaccountId: [Number, String]
    })

    const isEditMode = computed(() => {
        return props.twofaccountId != undefined
    })

    const groups = computed(() => {
        return useGroups().items.map((item) => {
            return { text: item.id > 0 ? item.name : '- ' + t('label.no_group') + ' -', value: item.id }
        })
    })

    onMounted(() => {
        if (route.name == 'editAccount') {
            showSpinner.value = true

            twofaccountService.get(props.twofaccountId).then(response => {
                form.fill(response.data)
                if (form.group_id == null) {
                    form.group_id = 0
                }
                form.setOriginal()
                // set account icon as temp icon
                tempIcon.value = form.icon
                showAdvancedForm.value = true
            })
            .finally(() => {
                showSpinner.value = false
            })
        }
        else if( bus.decodedUri ) {
            // The Start|Capture view provided an uri via the bus store.
            uri.value = bus.decodedUri
            bus.decodedUri = null
            showSpinner.value = true

            if (user.preferences.AutoSaveQrcodedAccount) {
                // The user wants the account to be saved automatically.
                // We save it now and we show him a fresh otp
                twofaccountService.storeFromUri(uri.value).then(response => {
                    showOTP(response.data)
                })
                .catch(error => {
                    if( error.response.data.errors.uri ) {
                        showAlternatives.value = true
                        showAdvancedForm.value = true
                    }
                })
                .finally(() => {
                    showSpinner.value = false
                })
            }
            else {
                // We prefill and show the quick form
                twofaccountService.preview(uri.value).then(response => {
                    form.fill(response.data)
                    tempIcon.value = response.data.icon ? response.data.icon : ''
                    showQuickForm.value = true
                    nextTick().then(() => {
                        OtpDisplayForQuickForm.value.show()
                    })
                })
                .catch(error => {
                    if( error.response.data.errors.uri ) {
                        showAlternatives.value = true
                        showAdvancedForm.value = true
                    }
                })
                .finally(() => {
                    showSpinner.value = false
                })
            }
        } else {
            showAdvancedForm.value = true
        }

        refreshIconPackList()
    })

    watch(iconCollection, (val) => {
        iconCollectionVariant.value = Object.prototype.hasOwnProperty.call(iconCollectionVariants, val)
            ? iconCollectionVariants[val][0].value
            : ''
    })

    watch(tempIcon, (val) => {
        if( showQuickForm.value ) {
            nextTick().then(() => {
                OtpDisplayForQuickForm.value.icon = val
            })
        }
    })

    watch(ShowTwofaccountInModal, (val) => {
        if (val == false) {
            OtpDisplayForAdvancedForm.value?.clearOTP()
            OtpDisplayForQuickForm.value?.clearOTP()
        }
    })

    watch(showOtpInModal, (val) => {
        if (val == false) {
            OtpDisplayForAutoSave.value?.clearOTP()
            router.push({ name: 'accounts' })
        }
    })

    watch(
        () => form.otp_type,
        (to, from) => {
            if (to === 'steamtotp') {
                form.service = 'Steam'
                fetchLogo()
            }
            else if (from === 'steamtotp') {
                form.service = ''
                deleteTempIcon()
            }
        }
    )

    /** */
    function defineDefaultGroup() {
        if (user.preferences.defaultGroup == -1) {
            return user.preferences.activeGroup <= 0 ? 0 : user.preferences.activeGroup
        }

        return user.preferences.defaultGroup
        
    }

    /**
     * Wrapper to call the appropriate function at form submit
     */
     function handleSubmit() {
        isEditMode.value ? updateAccount() : createAccount()
    }

    /**
     * Submits the form to the backend to store the new account
     */
    async function createAccount() {
        // set current temp icon as account icon
        form.icon = tempIcon.value

        const { data } = await form.post('/api/v1/twofaccounts')

        if (form.errors.any() === false) {
            twofaccounts.items.push(data)
            twofaccounts.sortDefault()
            
            notify.success({ text: t('notification.account_created') })
            router.push({ name: 'accounts' });
        }
    }

    /**
     * Submits the form to the backend to save the edited account
     */
    async function updateAccount() {
        // Set new icon and delete old one
        if( tempIcon.value !== form.icon ) {
            let oldIcon = ''
            oldIcon = form.icon
            form.icon = tempIcon.value
            tempIcon.value = oldIcon
            deleteTempIcon()
        }

        const { data } = await form.put('/api/v1/twofaccounts/' + props.twofaccountId)

        if( form.errors.any() === false ) {
            const index = twofaccounts.items.findIndex(acc => acc.id === data.id)
            twofaccounts.items.splice(index, 1, data)
            twofaccounts.sortDefault()

            notify.success({ text: t('notification.account_updated') })
            router.push({ name: 'accounts' })
        }
    }

    /**
     * Shows an OTP generated with the infos filled in the form
     * in order to preview or validated the password/the form data
     */
    function previewOTP() {
        form.clear()
        ShowTwofaccountInModal.value = true
        OtpDisplayForAdvancedForm.value.show()
    }

    /**
     * Shows rotating OTP for the provided account
     */
    function showOTP(otp) {
        // Data that should be displayed quickly by the OtpDisplay
        // component are passed using props.
        accountParams.value.otp_type = otp.otp_type
        accountParams.value.service = otp.service
        accountParams.value.account = otp.account
        accountParams.value.icon = otp.icon

        nextTick().then(() => {
            showOtpInModal.value = true
            OtpDisplayForAutoSave.value.show(otp.id);
        })
    }

    /**
     * Exits the view with user confirmation
     */
    function cancelCreation() {
        if (form.hasChanged() || tempIcon.value != form.icon) {
            if (confirm(t('confirmation.cancel_creation')) === true) {
                if (!isEditMode.value || tempIcon.value != form.icon) {
                    deleteTempIcon()
                }
                router.push({name: 'accounts'})
            }
        }
        else router.push({name: 'accounts'})
    }

    /**
     * Uploads the submited image resource to the backend
     */
    function uploadIcon() {
        // clean possible already uploaded temp icon
        deleteTempIcon()
        iconForm.icon = iconInput.value.files[0]

        iconForm.upload('/api/v1/icons', { returnError: true })
        .then(response => {
            tempIcon.value = response.data.filename
            if (showQuickForm.value) {
                form.icon = tempIcon.value
            }
        })
        .catch(error => {
            if (error.response.status !== 422) {
                notify.alert({ text: error.response.data.message})
            }
        })
    }

    /**
     * Deletes the temp icon from backend
     */
    function deleteTempIcon() {
        if (isEditMode.value) {
            if (tempIcon.value) {
                if (tempIcon.value !== form.icon) {
                    iconService.deleteIcon(tempIcon.value)
                }
                tempIcon.value = ''
            }
        }
        else if (tempIcon.value) {
            iconService.deleteIcon(tempIcon.value)
            tempIcon.value = ''
            if (showQuickForm.value) {
                form.icon = ''
            }
        }
    }

    /**
     * Increments the HOTP counter of the form after a preview
     * 
     * @param {object} payload 
     */
    function incrementHotp(payload) {
        // The quick form or the preview feature has incremented the HOTP counter so we get the new value from
        // the OtpDisplay component.
        // This could desynchronized the HOTP verification server and our local counter if the user never verified the HOTP but this
        // is acceptable (and HOTP counter can be edited by the way)
        form.counter = payload.nextHotpCounter
        
        //form.uri = payload.nextUri
    }
    
    /**
     * Maps errors received by the OtpDisplay to the form errors instance
     * 
     * @param {object} errorResponse 
     */
    function mapDisplayerErrors(errorResponse) {
        form.errors.set(form.extractErrors(errorResponse))
    }

    /**
     * Sends a QR code to backend for decoding and prefill the form with the qr data
     */
    function uploadQrcode() {
        qrcodeForm.qrcode = qrcodeInput.value.files[0]

        // First we get the uri encoded in the qrcode
        qrcodeForm.upload('/api/v1/qrcode/decode', { returnError: true })
        .then(response => {
            uri.value = response.data.data
            
            // Then the otp described by the uri
            twofaccountService.preview(uri.value, { returnError: true }).then(response => {
                form.fill(response.data)
                form.group_id = 0 // group_id is not in the response payload
                tempIcon.value = response.data.icon ? response.data.icon : null
            })
            .catch(error => {
                if( error.response.status === 422 ) {
                    if( error.response.data.errors.uri ) {
                        showAlternatives.value = true
                    }
                    else notify.alert({ text: t(error.response.data.message) })
                } else {
                    errorHandler.show(error)
                }
            })
        })
        .catch(error => {
            if (error.response.status !== 422) {
                notify.alert({ text: error.response.data.message})
            }
        })
    }

    /**
     * Tries to get the official logo/icon of the Service filled in the form
     */
    function fetchLogo() {
        if (user.preferences.getOfficialIcons) {
            fetchingLogo.value = true

            if (user.preferences.iconSource == 'logolib') {
                iconService.getLogo(form.service, iconCollection.value, iconCollectionVariant.value, { returnError: true })
                .then(response => {
                    if (response.status === 201) {
                        // clean possible already uploaded temp icon
                        deleteTempIcon()
                        tempIcon.value = response.data.filename;
                    }
                    else notify.warn( {text: t('error.no_icon_for_this_variant') })
                })
                .catch(() => {
                    notify.warn({ text: t('error.no_icon_for_this_variant') })
                })
                .finally(() => {
                    fetchingLogo.value = false
                })
            }
            else {
                iconService.getLogoFromPack(form.service, iconPack.value, { returnError: true })
                .then(response => {
                    if (response.status === 201) {
                        // clean possible already uploaded temp icon
                        deleteTempIcon()
                        tempIcon.value = response.data.filename;
                    }
                    else notify.warn( {text: t('error.no_match_in_the_icon_pack') })
                })
                .catch(error => {
                    if (error.response.status === 422) {
                        form.clear()
                        form.errors.set(form.extractErrors(error.response))
                    }
                    else notify.warn({ text: t('error.no_match_in_the_icon_pack') })
                })
                .finally(() => {
                    fetchingLogo.value = false
                })
            }
        }
    }

    /**
     * Strips html tags to prevent code injection
     * 
     * @param {*} str 
     */
    function strip_tags(str) {
        return str.replace(/(<([^> ]+)>)/ig, "")
    }

    /**
     * Saves the active group to the backends
     */
    // TODO : Delegate this to the store or a global watcher
    // TODO : make this method unique, see Accounts.vue
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
     * Refreshes the list of available icon packs
     */
    function refreshIconPackList() {
        isLoading.value = true

        iconService.getIconPacks().then(response => {
            iconPacks.value = []
            response.data.forEach((pack) => {
                iconPacks.value.push({
                    text: pack.name,
                    value: pack.name
                })
            })

            if (iconPacks.value.length == 0) {
                hasSomeIconPack.value = false
                iconPack.value = '/'
                iconPacks.value.push({ text: 'label.no_available_icon_packs', value: '/' })
            }
            else {
                hasSomeIconPack.value = true

                iconPack.value = user.preferences.iconPack == null || !iconPacks.value.some((pack) => pack.value === user.preferences.iconPack)
                    ? iconPacks.value[0].value
                    : user.preferences.iconPack
            }
        })
        .finally(() => {
            isLoading.value = false
        })
    }

</script>

<template>
    <StackLayout>
        <template #content>
            <!-- otp display modal (when auto-save is enabled) -->
            <Modal v-if="user.preferences.AutoSaveQrcodedAccount" v-model="showOtpInModal">
                <OtpDisplay
                    ref="OtpDisplayForAutoSave"
                    :accountParams="accountParams"
                    :preferences="user.preferences"
                    :twofaccountService="twofaccountService"
                    :iconPathPrefix="$2fauth.config.subdirectory"
                    @please-close-me="router.push({ name: 'accounts' })"
                    @please-update-activeGroup="saveActiveGroup"
                    @otp-copied-to-clipboard="notify.success({ text: t('notification.copied_to_clipboard') })"
                    @error="(error) => errorHandler.show(error)"
                />
            </Modal>
            <!-- Quick form (right after a qr code upload) -->
            <div v-if="!isEditMode && showQuickForm" class="modal modal-otp is-active fixed inset-0 z-[2000] flex flex-col overflow-y-auto px-4 py-6" role="dialog" aria-modal="true">
                <div class="modal-background fixed inset-0 bg-md-surface/80 backdrop-blur-xl"></div>
                <section class="modal-slot relative m-auto w-full max-w-md overflow-hidden rounded-xl bg-md-surface-container px-6 py-10 text-center shadow-xl animate-enter sm:rounded-2xl sm:px-10">
                    <div aria-hidden="true" class="pointer-events-none absolute -top-24 left-1/2 size-56 -translate-x-1/2 rounded-full bg-md-primary/20 blur-3xl"></div>
                    <form class="relative" @submit.prevent="createAccount" @keydown="form.onKeydown($event)">
                        <div class="relative">
                            <FormFieldError v-if="iconForm.errors.hasAny('icon')" :error="iconForm.errors.get('icon')" :field="'icon'" />
                            <label
                                for="filUploadIcon"
                                v-if="!tempIcon"
                                class="add-icon-button absolute left-1/2 top-0 z-10 flex size-20 -translate-x-1/2 cursor-pointer items-center justify-center rounded-lg text-md-on-surface-variant transition-colors duration-200 ease-md hover:bg-md-primary/10 hover:text-md-primary"
                                :title="$t('label.choose_image')"
                            >
                                <input id="filUploadIcon" class="file-input sr-only" type="file" accept="image/*" v-on:change="uploadIcon" ref="iconInput">
                                <LucideImageUp class="size-8!" />
                            </label>
                            <button
                                v-if="tempIcon"
                                type="button"
                                class="delete-icon-button md-icon-btn md-icon-btn-sm absolute left-1/2 top-0 z-10 ml-7 -mt-2 bg-md-error-container text-md-on-error-container hover:bg-md-error-container/80"
                                @click.prevent="deleteTempIcon"
                                :aria-label="$t('label.remove_icon')"
                            >
                                <LucideX />
                            </button>
                            <OtpDisplay
                                ref="OtpDisplayForQuickForm"
                                :accountParams="form.data()"
                                :preferences="user.preferences"
                                :twofaccountService="twofaccountService"
                                :iconPathPrefix="$2fauth.config.subdirectory"
                                :can_autoCloseTimeout="false"
                                @increment-hotp="incrementHotp"
                                @please-close-me="ShowTwofaccountInModal = false"
                                @please-update-activeGroup="saveActiveGroup"
                                @otp-copied-to-clipboard="notify.success({ text: t('notification.copied_to_clipboard') })"
                                @validation-error="mapDisplayerErrors"
                                @error="(error) => errorHandler.show(error)"
                            />
                        </div>
                        <div v-if="form.errors.any()" role="alert" class="md-callout md-callout-error mt-6 text-left">
                            <ul>
                                <template v-for="(field, index) in form.errors.errors" :key="index">
                                    <li v-for="(error, index) in field" :key="index">{{ error }}</li>
                                </template>
                            </ul>
                        </div>
                        <div class="mt-8 flex flex-col items-stretch gap-2">
                            <VueButton nativeType="submit" :isLoading="form.isBusy" size="lg" :isFullWidth="true">{{ $t('label.save') }}</VueButton>
                            <NavigationButton action="cancel" :isText="true" :isRounded="false" :useLinkTag="false" @canceled="cancelCreation" />
                        </div>
                    </form>
                </section>
            </div>
            <!-- Full form -->
            <FormWrapper v-if="showAdvancedForm" :title="isEditMode ? 'heading.edit_account' : 'heading.new_account'">
                <form @submit.prevent="handleSubmit" @keydown="form.onKeydown($event)" class="flex flex-col gap-4 pb-6">
                    <!-- qcode fileupload -->
                    <div v-if="!isEditMode">
                        <label
                            role="button"
                            tabindex="0"
                            class="md-btn md-btn-tonal"
                            :title="$t('tooltip.use_qrcode')"
                            ref="qrcodeInputLabel"
                            @keyup.enter="qrcodeInputLabel.click()"
                        >
                            <input inert tabindex="-1" class="file-input sr-only" type="file" accept="image/*" v-on:change="uploadQrcode" ref="qrcodeInput">
                            <LucideQrCode />
                            {{ $t('label.prefill_using_qrcode') }}
                        </label>
                        <FormFieldError v-if="qrcodeForm.errors.hasAny('qrcode')" :error="qrcodeForm.errors.get('qrcode')" :field="'qrcode'" />
                    </div>

                    <!-- identity -->
                    <section class="md-card sm:p-8">
                        <!-- service -->
                        <FormField v-model="form.service" fieldName="service" :errorMessage="form.errors.get('email')" :isDisabled="form.otp_type === 'steamtotp'" label="field.service" :placeholder="$t('field.service.placeholder')" autofocus />
                        <!-- account -->
                        <FormField v-model="form.account" fieldName="account" :errorMessage="form.errors.get('account')" label="field.account" :placeholder="$t('field.account.placeholder')" />
                        <!-- icon source: logo library -->
                        <div v-if="user.preferences.iconSource == 'logolib'" class="md-field">
                            <label for="icon-collection" class="md-label">{{ $t('field.icon') }}</label>
                            <div class="flex flex-wrap gap-3">
                                <div class="relative min-w-44 flex-1 sm:flex-none">
                                    <select id="icon-collection" class="md-select" :disabled="!form.service" name="icon-collection" v-model="iconCollection">
                                        <option v-for="collection in iconCollections" :key="collection.text" :value="collection.value">
                                            {{ collection.text }}
                                        </option>
                                    </select>
                                    <LucideChevronDown class="pointer-events-none absolute right-4 top-1/2 -translate-y-1/2 text-md-on-surface-variant" />
                                </div>
                                <div v-if="iconCollectionVariants[iconCollection]" class="relative min-w-44 flex-1 sm:flex-none">
                                    <select class="md-select" :disabled="!form.service" name="icon-collection-variant" v-model="iconCollectionVariant" :aria-label="$t('field.icon')">
                                        <option v-for="variant in iconCollectionVariants[iconCollection]" :key="variant.value" :value="variant.value">
                                            {{ $t(variant.text) }}
                                        </option>
                                    </select>
                                    <LucideChevronDown class="pointer-events-none absolute right-4 top-1/2 -translate-y-1/2 text-md-on-surface-variant" />
                                </div>
                            </div>
                        </div>
                        <!-- icon source: icon pack -->
                        <FormSelect v-else-if="user.preferences.iconSource == 'iconpack'" v-model="iconPack" :options="iconPacks" fieldName="iconPack" :isDisabled="!form.service" label="field.icon">
                            <button class="md-icon-btn" @click="refreshIconPackList" type="button" :title="$t('tooltip.refresh_icon_pack_list')" :aria-label="$t('tooltip.refresh_icon_pack_list')">
                                <LucideRefreshCw :class="{ 'animate-spin-md': isLoading }"/>
                            </button>
                        </FormSelect>
                        <!-- icon field buttons -->
                        <div class="flex flex-wrap items-center gap-3">
                            <!-- try my luck button -->
                            <VueButton @click="fetchLogo" color="tonal" nativeType="button" :is-loading="fetchingLogo" :disabled="!form.service || (user.preferences.iconSource == 'iconpack' && !hasSomeIconPack)" aria-describedby="lgdTryMyLuck">
                                <LucideWandSparkles v-if="!fetchingLogo" />
                                <span>{{ $t('label.i_m_lucky') }}</span>
                            </VueButton>
                            <!-- upload icon button -->
                            <label
                                for="filUploadIcon"
                                role="button"
                                tabindex="0"
                                class="md-btn md-btn-outlined"
                                ref="iconInputLabel"
                                @keyup.enter="iconInputLabel.click()"
                                :title="$t('label.choose_image')"
                            >
                                <input id="filUploadIcon" tabindex="-1" class="file-input sr-only" type="file" accept="image/*" v-on:change="uploadIcon" ref="iconInput">
                                <LucideImageUp />
                                <span class="max-sm:sr-only">{{ $t('label.choose_image') }}</span>
                            </label>
                            <span v-if="tempIcon" class="inline-flex items-center gap-1 rounded-full bg-md-surface-container-highest py-1 pl-1.5 pr-1">
                                <img class="icon-preview size-8 rounded-xs object-contain" :src="$2fauth.config.subdirectory + '/storage/icons/' + tempIcon" :alt="$t('alttext.icon_to_illustrate_the_account')">
                                <button type="button" class="clear-selection md-icon-btn md-icon-btn-sm" @click.prevent="deleteTempIcon" :aria-label="$t('label.remove_icon')">
                                    <LucideX />
                                </button>
                            </span>
                        </div>
                        <FormFieldError v-if="iconForm.errors.hasAny('icon')" :error="iconForm.errors.get('icon')" :field="'icon'" />
                        <p id="lgdTryMyLuck" v-if="user.preferences.getOfficialIcons" class="md-help px-1">{{ $t('message.i_m_lucky_legend') }}</p>
                        <!-- group -->
                        <div v-if="groups.length > 0" class="mt-6">
                            <FormSelect v-model="form.group_id" :options="groups" fieldName="group_id" label="field.group" help="field.group.help" />
                        </div>
                    </section>

                    <!-- otp -->
                    <section class="md-card sm:p-8">
                        <!-- otp type -->
                        <FormToggle v-model="form.otp_type" :isDisabled="isEditMode" :choices="otp_types" fieldName="otp_type" :errorMessage="form.errors.get('otp_type')" label="field.otp_type" help="field.otp_type.help" />
                        <!-- secret -->
                        <FormProtectedField v-if="form.otp_type != ''" :enableProtection="isEditMode" v-model.trimAll="form.secret" fieldName="secret" :errorMessage="form.errors.get('secret')" label="field.secret" help="field.secret.help" />
                    </section>

                    <!-- Options -->
                    <section v-if="form.otp_type != '' && form.otp_type !== 'steamtotp'" class="md-card sm:p-8">
                        <h2 class="md-section-title">{{ $t('heading.options') }}</h2>
                        <p class="mb-6 mt-1 text-label font-normal text-md-on-surface-variant">
                            {{ $t('field.options.help') }}
                        </p>
                        <!-- digits -->
                        <FormToggle v-model="form.digits" :choices="digitsChoices" fieldName="digits" :errorMessage="form.errors.get('digits')" label="field.digits" help="field.digits.help" />
                        <!-- algorithm -->
                        <FormToggle v-model="form.algorithm" :choices="algorithms" fieldName="algorithm" :errorMessage="form.errors.get('algorithm')" label="field.algorithm" help="field.algorithm.help" />
                        <!-- TOTP period -->
                        <FormField v-if="form.otp_type === 'totp'" pattern="[0-9]{1,4}" class="max-w-48" v-model="form.period" fieldName="period" :errorMessage="form.errors.get('period')" label="field.period" help="field.period.help" :placeholder="$t('field.period.placeholder')" />
                        <!-- HOTP counter -->
                        <FormProtectedField v-if="form.otp_type === 'hotp'" pattern="[0-9]{1,4}" :enableProtection="isEditMode" :isExpanded="false" v-model="form.counter" fieldName="counter" :errorMessage="form.errors.get('counter')" label="field.counter" :placeholder="$t('field.counter.placeholder')" :help="isEditMode ? 'field.counter.help_lock' : 'field.counter.help'" />
                    </section>
                </form>
                <!-- otp display modal (for previewing) -->
                <Modal v-model:is-active="ShowTwofaccountInModal">
                    <OtpDisplay
                        ref="OtpDisplayForAdvancedForm"
                        :accountParams="form.data()"
                        :preferences="user.preferences"
                        :twofaccountService="twofaccountService"
                        :iconPathPrefix="$2fauth.config.subdirectory"
                        :can_autoCloseTimeout="false"
                        @increment-hotp="incrementHotp"
                        @please-close-me="ShowTwofaccountInModal = false"
                        @otp-copied-to-clipboard="notify.success({ text: t('notification.copied_to_clipboard') })"
                        @validation-error="mapDisplayerErrors"
                        @error="(error) => errorHandler.show(error)"
                    />
                </Modal>
            </FormWrapper>
            <!-- alternatives -->
            <Modal v-model:is-active="showAlternatives">
                <QrContentDisplay :qrContent="uri" />
            </Modal>
        </template>
        <template #footer>
            <VueFooter>
                <template #default>
                    <VueButton nativeType="submit" @click="handleSubmit" :id="isEditMode ? 'btnUpdate' : 'btnCreate'" :isLoading="form.isBusy" size="lg">
                        {{ isEditMode ? $t('label.save') : $t('label.create') }}
                    </VueButton>
                    <button v-if="form.otp_type && form.secret" id="btnPreview" type="button" class="md-btn md-btn-tonal md-btn-lg" @click="previewOTP">
                        <LucidePlay />
                        {{ $t('label.test') }}
                    </button>
                    <NavigationButton action="cancel" :isText="true" :useLinkTag="false" @canceled="cancelCreation" />
                </template>
            </VueFooter>
        </template>
    </StackLayout>
    <Spinner v-if="showSpinner" :type="'fullscreen'" :isVisible="true" message="message.parsing_data" />
</template>
