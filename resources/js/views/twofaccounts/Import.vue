<script setup>
    import Form from '@/components/formElements/Form'
    import twofaccountService from '@/services/twofaccountService'
    import { FormTextarea } from '@2fauth/formcontrols'
    import { useNotify, OtpDisplay } from '@2fauth/ui'
    import { useUserStore } from '@/stores/user'
    import { useBusStore } from '@/stores/bus'
    import { useTwofaccounts } from '@/stores/twofaccounts'
    import { useI18n } from 'vue-i18n'
    import { LucideCamera, LucideCheck, LucideCircleAlert, LucideCircleX, LucideDownload, LucideFileText, LucideQrCode, LucideTextCursorInput, LucideTriangleAlert, LucideUpload, LucideX } from '@lucide/vue'

    const { t } = useI18n()
    const $2fauth = inject('2fauth')
    const notify = useNotify()
    const user = useUserStore()
    const bus = useBusStore()
    const twofaccounts = useTwofaccounts()
    const otpDisplay = ref(null)
    const fileInput = ref(null)
    const qrcodeInput = ref(null)
    const directInput = ref(null)
    const directInputError = ref(null)
    const form = reactive(new Form({
        service: '',
        account: '',
        otp_type: '',
        icon: '',
        secret: '',
        algorithm: '',
        digits: null,
        counter: null,
        period: null,
    }))
    const fileForm = reactive(new Form({
        file: null,
        withSecret: true
    }))
    const qrcodeForm = reactive(new Form({
        qrcode: null,
        withSecret: true
    }))
    const showTwofaccountInModal = ref(false)
    const supportedSources = [
        {app: '2FAuth', format: 'JSON'},
        {app: 'Google Auth', format: t('label.qr_code')},
        {app: 'Aegis Auth', format: 'JSON'},
        {app: 'Aegis Auth', format: t('label.plain_text')},
        {app: '2FAS auth', format: 'JSON'},
    ]
    const exportedAccounts = ref([])
    const isFetching = ref(false)

    const importableCount = computed(() => {
        return exportedAccounts.value.filter(account => account.imported == -1 && account.id > -2).length
    })

    const duplicateCount = computed(() => {
        return exportedAccounts.value.filter(account => account.id === -1 && account.imported === -1).length
    })

    const importedCount = computed(() => {
        return exportedAccounts.value.filter(account => account.imported === 1).length
    })

    watch(showTwofaccountInModal, (val) => {
        if (val == false) {
            otpDisplay.value?.clearOTP()
        }
    })

    onMounted(() => {
        // A migration URI has been provided by the Start view using the bus store
        // We extract the accounts from the URI and list them in the view
        if( bus.migrationUri ) {
            migrate(bus.migrationUri)
            bus.migrationUri = null
        }
    })

    /**
     * Posts the migration payload
     */
    async function migrate(payload, form = null) {
        isFetching.value = true

        await twofaccountService.migrate(payload, { returnError: true }).then(response => {
            response.data.forEach((data) => {
                data.imported = -1;
                exportedAccounts.value.push(data)
            })
            notifyValidAccountFound()
            directInput.value = directInputError.value = null
        })
        .catch(error => {
            notify.alert({ text: t(error.response.data.message) })

            if(form != null && error.response.status === 422) {
                form.clear()
                form.errors.set(form.extractErrors(error.response))
            }
        })
        .finally(() => {
            isFetching.value = false
        })
    }

    /**
     * Removes all duplicates from the accounts list
     */
    function discardDuplicates() {
        if(confirm(t('confirmation.discard_duplicates'))) {
            notify.clear()
            otpDisplay.value?.clearOTP()
            exportedAccounts.value = exportedAccounts.value.filter(account => account.id !== -1)
        }
    }

    /**
     * Clears the accounts list
     */
    function discardAccounts() {
        if(confirm(t('confirmation.discard_all'))) {
            notify.clear()
            otpDisplay.value?.clearOTP()
            exportedAccounts.value = []
        }
    }

    /**
     * Removes one duplicate from the accounts list
     */
    function discardAccount(accountIndex) {
        if(confirm(t('confirmation.discard'))) {
            exportedAccounts.value.splice(accountIndex, 1)
        }
    }

    /**
     * Batch stores valid accounts, even duplicates
     */
    async function createAccounts() {
        for (let index = 0; index < exportedAccounts.value.length; index++) {
            if (exportedAccounts.value[index].imported == -1) {
                await createAccount(index)
            }
        }
        twofaccounts.sortDefault()
    }

    /**
     * Stores the provided account
     */
    async function createAccount(accountIndex) {
        form.fill(exportedAccounts.value[accountIndex])

        await form.post('/api/v1/twofaccounts', {returnError: true})
        .then(response => {
            exportedAccounts.value[accountIndex].imported = 1
            exportedAccounts.value[accountIndex].id = response.data.id
            delete response.data.secret
            twofaccounts.items.push(response.data)
        })
        .catch(error => {
            exportedAccounts.value[accountIndex].imported = 0
            exportedAccounts.value[accountIndex].id = 0
            exportedAccounts.value[accountIndex].errors = form.errors.flatten()
        })
    }

    /**
     * Generates a fresh OTP password and displays it
     */
    function previewAccount(accountIndex) {
        form.fill(exportedAccounts.value[accountIndex])
        showTwofaccountInModal.value = true

        nextTick().then(() => {
            otpDisplay.value.show()
        })
    }

    /**
     * Uploads the submitted file to the backend for parsing
     */
    function submitFile() {
        fileForm.clear()
        isFetching.value = true
        fileForm.file = fileInput.value.files[0]

        fileForm.upload('/api/v1/twofaccounts/migration', { returnError: true }).then(response => {
            response.data.forEach((data) => {
                data.imported = -1;
                exportedAccounts.value.push(data)
            })
            notifyValidAccountFound()
        })
        .catch(error => {
            if (error.response.status === 422) {
                if (error.response.data.errors?.file == undefined) {
                    notify.alert({ text: t('error.invalid_2fa_data') })
                }
            }
            else notify.alert({ text: error.response.data.message})
        })
        .finally(() => {
            isFetching.value = false
        })
        
    }

    /**
     * Uploads the submitted QR code file to the backend for decoding
     */
    function submitQrCode() {
        qrcodeForm.clear()
        isFetching.value = true
        qrcodeForm.qrcode = qrcodeInput.value.files[0]

        qrcodeForm.upload('/api/v1/qrcode/decode', { returnError: true }).then(response => {
            migrate(response.data.data, qrcodeForm)
        })
        .catch(error => {
            if( error.response.status === 422 ) {
                if (error.response.data.errors?.qrcode == undefined) {
                    notify.alert({ text: t('error.invalid_2fa_data') })
                }
            }
            else notify.alert({ text: error.response.data.message})
        })
        .finally(() => {
            isFetching.value = false
        })
    }

    /**
     * Notifies that valid account(s) have been found for import
     */
    function notifyValidAccountFound() {
        notify.success({ text: t('notification.x_valid_accounts_found', { count: importableCount.value }) })
    }

    /**
     * Submits the directInput form to the backend
     */
    function submitDirectInput() {
        directInputError.value = null
        
        if (! directInput.value) {
            directInputError.value = t('validation.required', { attribute: 'Direct input' })
        }
        else migrate(directInput.value)
    }

</script>

<template>
    <StackLayout>
        <template #content>
            <ResponsiveWidthWrapper>
                <h1 class="md-page-title">
                    {{ $t('heading.import') }}
                </h1>
                <div v-if="!isFetching && exportedAccounts.length === 0" class="animate-enter pb-8">
                    <div class="mt-3 text-body leading-relaxed text-md-on-surface-variant">
                        <p class="mb-2">{{ $t('message.import_legend') }}</p>
                        <p>{{ $t('message.import_legend_afterpart') }}</p>
                    </div>
                    <div class="mt-8 grid gap-4">
                        <!-- qr code -->
                        <section class="md-card flex flex-col gap-4 sm:flex-row sm:items-start">
                            <span class="inline-flex size-12 shrink-0 items-center justify-center rounded-md bg-md-primary-container text-md-on-primary-container">
                                <LucideQrCode />
                            </span>
                            <div class="min-w-0 flex-1">
                                <h2 class="text-title text-md-on-surface">{{ $t('heading.qr_code') }}</h2>
                                <p class="mt-1 text-label font-normal leading-relaxed text-md-on-surface-variant">{{ $t('message.supported_formats_for_qrcode_upload') }}</p>
                                <template v-if="qrcodeForm.errors.any()">
                                    <template v-for="(messages, error) in qrcodeForm.errors.all()" :key="error">
                                        <FormFieldError :error="qrcodeForm.errors.get(error)" :field="error" />
                                    </template>
                                </template>
                                <div class="mt-4 flex flex-wrap gap-2">
                                    <RouterLink id="btnCapture" :to="{ name: 'capture' }" class="md-btn md-btn-tonal">
                                        <LucideCamera />
                                        {{ $t('link.scan') }}
                                    </RouterLink>
                                    <button type="button" class="md-btn md-btn-outlined" @click="qrcodeInput.click()">
                                        <input inert tabindex="-1" class="file-input sr-only" type="file" accept="image/*" v-on:change="submitQrCode" ref="qrcodeInput">
                                        <LucideUpload />
                                        {{ $t('label.upload') }}
                                    </button>
                                </div>
                            </div>
                        </section>
                        <!-- text file -->
                        <section class="md-card flex flex-col gap-4 sm:flex-row sm:items-start">
                            <span class="inline-flex size-12 shrink-0 items-center justify-center rounded-md bg-md-secondary-container text-md-on-secondary-container">
                                <LucideFileText />
                            </span>
                            <div class="min-w-0 flex-1">
                                <h2 class="text-title text-md-on-surface">{{ $t('label.text_file') }}</h2>
                                <p class="mt-1 text-label font-normal leading-relaxed text-md-on-surface-variant">{{ $t('message.supported_formats_for_file_upload') }}</p>
                                <template v-if="fileForm.errors.any()">
                                    <template v-for="(messages, error) in fileForm.errors.all()" :key="error">
                                        <FormFieldError :error="fileForm.errors.get(error)" :field="error" />
                                    </template>
                                </template>
                                <div class="mt-4">
                                    <button type="button" class="md-btn md-btn-outlined" @click="fileInput.click()">
                                        <input inert tabindex="-1" class="file-input sr-only" type="file" accept="text/plain,application/json,text/csv,.2fas" v-on:change="submitFile" ref="fileInput">
                                        <LucideUpload />
                                        {{ $t('label.upload') }}
                                    </button>
                                </div>
                            </div>
                        </section>
                        <!-- direct input -->
                        <section class="md-card flex flex-col gap-4 sm:flex-row sm:items-start">
                            <span class="inline-flex size-12 shrink-0 items-center justify-center rounded-md bg-md-tertiary-container text-md-on-tertiary-container">
                                <LucideTextCursorInput />
                            </span>
                            <div class="min-w-0 flex-1">
                                <h2 class="text-title text-md-on-surface">{{ $t('message.direct_input') }}</h2>
                                <p class="mb-4 mt-1 text-label font-normal leading-relaxed text-md-on-surface-variant">{{ $t('message.expected_format_for_direct_input') }}</p>
                                <FormTextarea v-model="directInput" :errorMessage="directInputError" fieldName="payload" rows="5" :size="'is-small'" />
                                <button type="button" class="md-btn md-btn-filled -mt-1" @click.stop="submitDirectInput">
                                    {{ $t('label.submit') }}
                                </button>
                            </div>
                        </section>
                    </div>
                    <!-- Supported migration resources -->
                    <h2 class="md-section-title mb-3 mt-12">{{ $t('heading.supported_migration_formats') }}</h2>
                    <p class="md-callout md-callout-warning mb-4">
                        <LucideTriangleAlert />
                        {{ $t('message.do_not_set_password_or_encryption') }}
                    </p>
                    <div class="md-card overflow-x-auto p-2">
                        <table class="md-table">
                            <thead>
                                <tr>
                                    <th></th>
                                    <th class="text-center">Plain text</th>
                                    <th class="text-center">QR code</th>
                                    <th class="text-center">JSON</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <th scope="row" class="font-medium! normal-case! tracking-normal! text-md-on-surface!">Google Authenticator</th>
                                    <td></td>
                                    <td class="text-center"><LucideCheck stroke-width="3" class="inline size-4! text-md-primary" /></td>
                                    <td></td>
                                </tr>
                                <tr>
                                    <th scope="row" class="font-medium! normal-case! tracking-normal! text-md-on-surface!">Aegis Auth</th>
                                    <td class="text-center"><LucideCheck stroke-width="3" class="inline size-4! text-md-primary" /></td>
                                    <td></td>
                                    <td class="text-center"><LucideCheck stroke-width="3" class="inline size-4! text-md-primary" /></td>
                                </tr>
                                <tr>
                                    <th scope="row" class="font-medium! normal-case! tracking-normal! text-md-on-surface!">2FAS auth</th>
                                    <td></td>
                                    <td></td>
                                    <td class="text-center"><LucideCheck stroke-width="3" class="inline size-4! text-md-primary" /></td>
                                </tr>
                                <tr>
                                    <th scope="row" class="font-medium! normal-case! tracking-normal! text-md-on-surface!">FreeOTP+</th>
                                    <td class="text-center"><LucideCheck stroke-width="3" class="inline size-4! text-md-primary" /></td>
                                    <td></td>
                                    <td></td>
                                </tr>
                                <tr>
                                    <th scope="row" class="font-medium! normal-case! tracking-normal! text-md-on-surface!">2FAuth</th>
                                    <td></td>
                                    <td></td>
                                    <td class="text-center"><LucideCheck stroke-width="3" class="inline size-4! text-md-primary" /></td>
                                </tr>
                                <tr>
                                    <th scope="row" class="font-medium! normal-case! tracking-normal! text-md-on-surface!">Bitwarden</th>
                                    <td></td>
                                    <td></td>
                                    <td class="text-center"><LucideCheck stroke-width="3" class="inline size-4! text-md-primary" /></td>
                                </tr>
                                <tr>
                                    <th scope="row" class="font-medium! normal-case! tracking-normal! text-md-on-surface!">Bitwarden Authenticator</th>
                                    <td></td>
                                    <td></td>
                                    <td class="text-center"><LucideCheck stroke-width="3" class="inline size-4! text-md-primary" /></td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
                <div v-else-if="!isFetching" class="animate-enter pb-8">
                    <div class="mt-3 text-body leading-relaxed text-md-on-surface-variant">
                        <p class="mb-2">{{ $t('message.submitted_data_parsed_now_accounts_are_awaiting_import') }}</p>
                        <p>{{ $t('message.use_buttons_to_save_or_discard') }}</p>
                    </div>
                    <!-- discard links -->
                    <div class="mb-3 mt-6 flex flex-wrap justify-end gap-1">
                        <template v-if="importableCount > 0">
                            <button v-if="duplicateCount" @click="discardDuplicates()" type="button" class="md-btn md-btn-neutral md-btn-xs">{{ $t('label.discard_duplicates') }} ({{duplicateCount}})</button>
                            <button @click="discardAccounts()" type="button" class="md-btn md-btn-neutral md-btn-xs">{{ $t('label.discard_all') }}</button>
                        </template>
                        <button v-if="importedCount == exportedAccounts.length" @click="exportedAccounts = []" type="button" class="md-btn md-btn-neutral md-btn-xs">{{ $t('label.clear') }}</button>
                    </div>
                    <ul class="flex flex-col gap-2">
                        <li v-for="(account, index) in exportedAccounts" :key="account.name" class="group-item md-card flex items-center gap-4 px-4 py-3 sm:px-5">
                            <img role="presentation" v-if="account.icon && user.preferences.showAccountsIcons" class="import-icon md-account-icon size-10" :src="$2fauth.config.subdirectory + '/storage/icons/' + account.icon" alt="">
                            <div class="min-w-0 flex-1">
                                <!-- Account name -->
                                <button v-if="account.id > -2 && account.imported !== 0" type="button" class="block max-w-full truncate text-left text-title text-md-on-surface hover:text-md-primary" @click="previewAccount(index)" :title="$t('tooltip.generate_a_test_password')">
                                    {{ account.account }}
                                </button>
                                <p v-else class="truncate text-title text-md-on-surface">{{ account.account }}</p>
                                <!-- service name -->
                                <p class="truncate text-label font-normal text-md-on-surface-variant">{{ $t('label.issuer') }}: {{ account.service }}</p>
                                <!-- reasons to invalid G-Auth data -->
                                <p v-if="account.id === -2" class="mt-1 flex items-center gap-1 text-label text-md-error">
                                    <LucideCircleX class="size-4!" />{{ account.secret }}
                                </p>
                                <!-- possible duplicates -->
                                <p v-if="account.id === -1 && account.imported !== 1 && !account.errors" class="mt-1 flex items-center gap-1 text-label text-md-warning">
                                    <LucideCircleAlert class="size-4!" />{{ $t('message.possible_duplicate') }}
                                </p>
                                <!-- errors during account creation -->
                                <ul v-if="account.errors" class="mt-1">
                                    <li v-for="(error) in account.errors" :key="error" class="text-label text-md-error">{{ error }}</li>
                                </ul>
                            </div>
                            <!-- buttons -->
                            <div v-if="account.imported === -1" class="flex shrink-0 items-center gap-1">
                                <!-- import button -->
                                <button v-if="account.id > -2" type="button" class="md-btn md-btn-filled md-btn-xs" @click="createAccount(index)" :title="$t('tooltip.import_this_account')">
                                    {{ $t('label.to_import') }}
                                </button>
                                <!-- discard button -->
                                <button type="button" class="md-icon-btn md-icon-btn-sm" @click="discardAccount(index)" :title="$t('tooltip.discard_this_account')" :aria-label="$t('tooltip.discard_this_account')">
                                    <LucideX />
                                </button>
                            </div>
                            <!-- result label -->
                            <div v-else class="shrink-0">
                                <span v-if="account.imported === 1" class="md-badge md-badge-success">
                                    <LucideCheck />{{ $t('message.imported') }}
                                </span>
                                <span v-else class="md-badge md-badge-error">
                                    <LucideX />{{ $t('message.failure') }}
                                </span>
                            </div>
                        </li>
                    </ul>
                </div>
            </ResponsiveWidthWrapper>
            <Spinner v-if="isFetching && exportedAccounts.length === 0" :type="'fullscreen-overlay'" :isVisible="true" message="message.parsing_data" />
            <!-- modal -->
            <Modal v-model:is-active="showTwofaccountInModal">
                <OtpDisplay
                    ref="otpDisplay"
                    :accountParams="form.data()"
                    :preferences="user.preferences"
                    :twofaccountService="twofaccountService"
                    :iconPathPrefix="$2fauth.config.subdirectory"
                    @please-close-me="showTwofaccountInModal = false"
                    @otp-copied-to-clipboard="notify.success({ text: t('notification.copied_to_clipboard') })"
                    @error="(error) => errorHandler.show(error)"
                />
            </Modal>
        </template>
        <template #footer>
            <VueFooter>
                <template #default>
                    <!-- Import all button -->
                    <button v-if="importableCount > 0" type="button" class="md-btn md-btn-filled md-btn-lg" @click="createAccounts">
                        <LucideDownload />
                        {{ $t('label.import_all') }} ({{ importableCount }})
                    </button>
                    <NavigationButton v-if="importableCount > 0" action="cancel" :isText="true" @canceled="router.push({ name: 'accounts' })" />
                    <NavigationButton v-else action="close" @closed="router.push({ name: 'accounts' })" :current-page-title="$t('title.importAccounts')" />
                </template>
            </VueFooter>
        </template>
    </StackLayout>
</template>
