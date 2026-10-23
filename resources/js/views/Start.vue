<script setup>
    import { LucideCamera, LucideClipboardPaste, LucideFileInput, LucideImageUp, LucideKeyboard, LucideLoaderCircle, LucideScanQrCode } from '@lucide/vue'
    import Form from '@/components/formElements/Form'
    import { useUserStore } from '@/stores/user'
    import { useBusStore } from '@/stores/bus'
    import { useNotify } from '@2fauth/ui'
    import { useTwofaccounts } from '@/stores/twofaccounts'
    import { useI18n } from 'vue-i18n'

    const { t } = useI18n()
    const router = useRouter()
    const user = useUserStore()
    const bus = useBusStore()
    const notify = useNotify()
    const twofaccounts = useTwofaccounts()

    const qrcodeInput = ref(null)
    const qrcodeInputLabel = ref(null)
    const form = reactive(new Form({
        qrcode: null,
        inputFormat: 'fileUpload',
    }))
    const isPasting = ref(false)
    const isUploading = ref(false)


    /**
     * Upload the submitted QR code file to the backend for decoding, then route the user
     * to the Create or Import form with decoded URI to prefill the form
     *
     * @param {File | undefined} file
     */
    function submitQrCode(file) {
        form.clear()
        form.qrcode = file ?? qrcodeInput.value.files[0]

        form.upload('/api/v1/qrcode/decode', { returnError: true }).then(response => {
            if (response.data.data.slice(0, 33).toLowerCase() === "otpauth-migration://offline?data=") {
                bus.migrationUri = response.data.data
                router.push({ name: 'importAccounts' })
            }
            else {
                bus.decodedUri = response.data.data
                router.push({ name: 'createAccount' })
            }
        })
        .catch(error => {
            if (error.response.status !== 422) {
                notify.alert({ text: error.response.data.message })
            }
        })
        .finally(() => {
            isPasting.value = false
            isUploading.value = false
        })
    }

    /**
     * Push user to the dedicated capture view for live scan
     */
    function capture() {
        router.push({ name: 'capture' });
    }

    /**
     * Checks if the pasted thig is an image, and if yes, submits it to {@link submitQrCode}
     * @param {ClipboardEvent} ev
     */
    function handlePaste(ev) {
        for (let i = 0; i < ev.clipboardData.files.length; i++) {
            const file = ev.clipboardData.files[i];
            if (file.type.indexOf('image/') !== 0) {
                // file is not an image
                break;
            }

            isPasting.value = true
            submitQrCode(file);
            return
        }

        notify.warn({ text: t('message.no_image_found_in_clipboard') })
    }

    /**
     * Triggers decoding of uploaded qr code
     */
    function handleUploadQR() {        
        isUploading.value = true
        submitQrCode()
    }

    onMounted(() => {
        if( user.preferences.useDirectCapture && user.preferences.defaultCaptureMode === 'upload' ) {
            qrcodeInputLabel.value.click()
        }
        console.log('mounting', handlePaste);
        document.addEventListener('paste', handlePaste);
    })

    onUnmounted(() => {
        document.removeEventListener('paste', handlePaste);
    });
</script>

<template>
    <StackLayout :is-vertical-centered="true">
        <template #content>
            <Spinner v-if="isPasting" :type="'fullscreen-overlay'" :isVisible="true" message="message.parsing_data" />
            <div v-else class="mx-auto w-full max-w-3xl py-6">
                <!-- hero -->
                <section class="relative overflow-hidden rounded-2xl rounded-tr-md bg-md-surface-container px-6 py-10 text-center shadow-lg animate-enter sm:rounded-3xl sm:rounded-tr-lg sm:px-12 sm:py-14">
                    <div class="relative">
                        <span class="mx-auto mb-6 inline-flex size-20 animate-float items-center justify-center rounded-xl bg-md-primary-container text-md-on-primary-container shadow-md">
                            <LucideScanQrCode class="size-10!" :stroke-width="1.5" />
                        </span>
                        <!-- trailer phrase that invite to add an account -->
                        <div v-if="twofaccounts.count === 0" class="mb-8">
                            <h1 class="md-page-title">{{ $t('message.no_account_here') }}</h1>
                            <p class="mt-2 text-body-lg text-md-on-surface-variant max-sm:text-body">{{ $t('message.add_first_account') }}</p>
                        </div>
                        <div class="quick-uploader-wrapper">
                            <!-- upload a qr code (with basic file field and backend decoding) -->
                            <label v-if="user.preferences.useBasicQrcodeReader" role="button" tabindex="0" class="md-btn md-btn-filled md-btn-lg h-14 px-10 text-body shadow-md" :aria-busy="isUploading" ref="qrcodeInputLabel" @keyup.enter="qrcodeInputLabel.click()">
                                <input aria-hidden="true" tabindex="-1" class="file-input sr-only" type="file" accept="image/*" v-on:change="submitQrCode" ref="qrcodeInput">
                                <LucideLoaderCircle v-if="isUploading" class="md-btn-spinner" />
                                <LucideImageUp v-else />
                                {{ $t('label.upload_qrcode') }}
                            </label>
                            <!-- scan button that launch camera stream -->
                            <button v-else type="button" class="md-btn md-btn-filled md-btn-lg h-14 px-10 text-body shadow-md" @click="capture()">
                                <LucideCamera />
                                {{ $t('label.scan_qrcode') }}
                            </button>
                            <FormFieldError v-if="form.errors.hasAny('qrcode')" :error="form.errors.get('qrcode')" :field="'qrcode'" />
                        </div>
                        <p class="mt-6 inline-flex items-center gap-2 rounded-full bg-md-surface-container-high px-4 py-2 text-label font-normal text-md-on-surface-variant">
                            <LucideClipboardPaste class="size-4!" />
                            {{ $t('message.you_can_also_paste') }}
                        </p>
                    </div>
                </section>
                <!-- alternative methods -->
                <p class="md-overline mb-4 mt-10 px-2 text-center">{{ $t('message.alternative_methods') }}</p>
                <div class="grid gap-3 sm:grid-cols-3">
                    <!-- upload a qr code -->
                    <label
                        v-if="!user.preferences.useBasicQrcodeReader"
                        role="button"
                        tabindex="0"
                        class="md-card md-card-interactive group flex items-center gap-4 p-5 text-left hover:scale-[1.02] sm:flex-col sm:items-start"
                        ref="qrcodeInputLabel"
                        @keyup.enter="qrcodeInputLabel.click()"
                    >
                        <input aria-hidden="true" tabindex="-1" class="file-input sr-only" type="file" accept="image/*" v-on:change="handleUploadQR" ref="qrcodeInput">
                        <span class="inline-flex size-14 shrink-0 items-center justify-center md-tone-0 md-shape-cookie transition-[rotate] duration-700 ease-spring group-hover:rotate-90">
                            <LucideLoaderCircle v-if="isUploading" class="animate-spin-md" />
                            <LucideImageUp v-else />
                        </span>
                        <span class="font-display text-title text-md-on-surface">{{ $t('label.upload_qrcode') }}</span>
                    </label>
                    <!-- link to advanced form -->
                    <RouterLink class="md-card md-card-interactive group flex items-center gap-4 p-5 text-left no-underline hover:scale-[1.02] sm:flex-col sm:items-start" :to="{ name: 'createAccount' }">
                        <span class="inline-flex size-14 shrink-0 items-center justify-center md-tone-4 md-shape-flower transition-[rotate] duration-700 ease-spring group-hover:rotate-90">
                            <LucideKeyboard />
                        </span>
                        <span class="font-display text-title text-md-on-surface">{{ $t('link.use_advanced_form') }}</span>
                    </RouterLink>
                    <!-- link to import view -->
                    <RouterLink id="btnImport" class="md-card md-card-interactive group flex items-center gap-4 p-5 text-left no-underline hover:scale-[1.02] sm:flex-col sm:items-start" :to="{ name: 'importAccounts' }">
                        <span class="inline-flex size-14 shrink-0 items-center justify-center md-tone-1 md-shape-clover transition-[rotate] duration-700 ease-spring group-hover:rotate-90">
                            <LucideFileInput />
                        </span>
                        <span class="font-display text-title text-md-on-surface">{{ $t('label.import') }}</span>
                    </RouterLink>
                </div>
            </div>
        </template>
        <template #footer>
            <VueFooter>
                <template v-if="!twofaccounts.isEmpty" #default>
                    <NavigationButton action="back" @goback="router.push({ name: 'accounts' })" :previous-page-title="$t('title.accounts')" />
                </template>
            </VueFooter>
        </template>
    </StackLayout>
</template>
