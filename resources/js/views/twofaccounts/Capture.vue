<script setup>
    import Form from '@/components/formElements/Form'
    import QrContentDisplay from '@/components/QrContentDisplay.vue'
    import { useBusStore } from '@/stores/bus'
    import { useNotify } from '@2fauth/ui'
    import { QrcodeStream } from 'vue-qrcode-reader'
    import { useI18n } from 'vue-i18n'
    import { useErrorHandler } from '@2fauth/stores'
    import { LucideChevronDown, LucideLock, LucideRefreshCw, LucideVideoOff, LucideStar, LucideCamera } from '@lucide/vue'

    const errorHandler = useErrorHandler()
    const { t } = useI18n()
    const router = useRouter()
    const bus = useBusStore()
    const notify = useNotify()

    const cameraIsOn = ref(false)
    const selectedCamera = ref(null)
    const cameras = ref([])
    const errorPhrase = ref('')
    const form = reactive(new Form({
        qrcode: null,
        uri: '',
    }))
    const showQrContent = ref(false)

    onMounted(async () => {
        if (!navigator.mediaDevices?.enumerateDevices) {
            errorPhrase.value  = 'secured_context_required'
        } else {
            await navigator.mediaDevices.enumerateDevices().then((devices) => {
                cameras.value = devices.filter(({ kind }) => kind === 'videoinput')

                if (cameras.value.length > 0) {
                    selectedCamera.value = cameras.value[0]
                }
                else errorPhrase.value  = 'no_cam_on_device'
            })
            .catch((err) => {
                onError(err)
            })
        }
    })

    const onError = error => {
        if (error.name === 'NotAllowedError') {
            errorPhrase.value = 'need_grant_permission'
        } else if (error.name === 'NotFoundError') {
            errorPhrase.value = 'no_cam_on_device'
        } else if (error.name === 'NotSupportedError' || error.name === 'InsecureContextError') {
            errorPhrase.value  = 'secured_context_required'
        } else if (error.name === 'NotReadableError') {
            errorPhrase.value = 'not_readable'
        } else if (error.name === 'OverconstrainedError') {
            errorPhrase.value = 'camera_not_suitable'
        } else if (error.name === 'StreamApiNotSupportedError') {
            errorPhrase.value = 'stream_api_not_supported'
        } else {
            errorHandler.show(error)
        }
    }

    /**
     * Pushes a decoded URI to the Create or Import form
     * 
     * The basicQRcodeReader option is Off, so qrcode decoding has already be done by vue-qrcode-reader, whether
     * from livescan or file input.
     * We simply check the uri validity to prevent useless push to the form, but the form will check uri validity too.
     */
    const onDetect = async (detectedCodes) => {
        const [ firstCode ] = detectedCodes
        form.uri = firstCode.rawValue

        if (! form.uri) {
            notify.warn({ text: t('error.qrcode_cannot_be_read') })
        }
        else if (form.uri.slice(0, 33).toLowerCase() == "otpauth-migration://offline?data=") {
            bus.migrationUri = form.uri
            router.push({ name: 'importAccounts' })
        }
        else if (form.uri.slice(0, 15).toLowerCase() !== "otpauth://totp/" && form.uri.slice(0, 15).toLowerCase() !== "otpauth://hotp/") {
            showQrContent.value = true
            notify.warn({ text: t('error.no_valid_otp') })
        }
        else {
            bus.decodedUri = form.uri
            router.push({ name: 'createAccount' })
        }
    }

    /**
     * Triggered when camera goes On
     */
    function cameraOn(event) {
        cameraIsOn.value = true
    }

    /**
     * Triggered when camera goes Off
     */
    function cameraOff(event) {
        cameraIsOn.value = false
    }

    /**
     * Exits the stream view
     */
    function exitStream() {
        // this.camera = 'off'
        router.go(-1)
    }

    /**
     * Paints the red outline during scan
     */
    const paintOutline = (detectedCodes, ctx) => {
        for (const detectedCode of detectedCodes) {
            const [firstPoint, ...otherPoints] = detectedCode.cornerPoints

            ctx.strokeStyle = '#d0bcff'
            ctx.lineWidth = 4

            ctx.beginPath()
            ctx.moveTo(firstPoint.x, firstPoint.y)
            for (const { x, y } of otherPoints) {
            ctx.lineTo(x, y)
            }
            ctx.lineTo(firstPoint.x, firstPoint.y)
            ctx.closePath()
            ctx.stroke()
        }
    }

    function reloadLocation() {
        location.reload()
    }
</script>

<template>
    <div class="modal is-active fixed inset-0 z-[2000] flex flex-col bg-md-scrim text-white" role="dialog" aria-modal="true">
        <section class="modal-slot relative flex flex-1 flex-col items-center justify-center overflow-y-auto px-4 pt-[max(1rem,env(safe-area-inset-top))]">
            <!-- errors / loading -->
            <div v-if="errorPhrase" class="relative z-10 w-full max-w-md rounded-xl bg-md-surface-container p-8 text-center text-md-on-surface shadow-xl animate-enter">
                <span class="mx-auto mb-5 inline-flex size-16 items-center justify-center rounded-lg bg-md-error-container text-md-on-error-container" aria-hidden="true">
                    <LucideVideoOff class="size-8!" />
                </span>
                <p class="text-title text-md-on-surface">{{ $t('message.stream.live_scan_cant_start') }}</p>
                <p class="mt-2 text-body text-md-on-surface-variant">{{ $t('message.stream.' + errorPhrase + '.reason') }}</p>
                <div v-if="errorPhrase == 'need_grant_permission'" class="mt-5">
                    <p class="mb-2 text-label font-normal text-md-on-surface-variant">{{ $t('message.stream.need_grant_permission.solution') }}</p>
                    <p class="mb-4 text-label font-normal text-md-on-surface-variant">{{ $t('message.stream.need_grant_permission.click_camera_icon') }}</p>
                    <!-- mock address bar -->
                    <div class="addressbar flex items-center gap-3 rounded-full bg-md-surface-container-highest px-4 py-2.5 text-left font-mono text-label-sm text-md-on-surface-variant" aria-hidden="true">
                        <span class="relative flex items-center gap-2">
                            <LucideLock class="size-4!" />
                            <span class="relative inline-flex">
                                <span class="absolute -inset-1.5 rounded-full ring-2 ring-md-error"></span>
                                <LucideVideoOff class="size-4!" />
                            </span>
                        </span>
                        <span class="flex-1 truncate">http://my.2fauth.app/...</span>
                        <LucideStar class="size-4!" />
                    </div>
                    <button type="button" class="md-btn md-btn-tonal mt-5" @click.stop="reloadLocation">
                        <LucideRefreshCw />
                        {{ $t('label.refresh') }}
                    </button>
                </div>
                <p v-else class="mt-3 text-label font-normal text-md-on-surface-variant">{{ $t('message.stream.' + errorPhrase + '.solution') }}</p>
            </div>
            <span v-else-if="!cameraIsOn" class="relative z-10 inline-flex size-16 items-center justify-center rounded-full bg-white/10 backdrop-blur-sm">
                <Spinner :isVisible="true" :type="'raw'" :rawSize="32" />
            </span>
            <!-- stream -->
            <div v-show="!errorPhrase" class="fullscreen-streamer absolute inset-x-0 top-[6%] mx-auto flex h-[68%] max-w-3xl flex-col gap-3 px-4">
                <!-- device selector -->
                <div v-if="cameraIsOn && cameras.length > 1" class="relative z-10 mx-auto w-full max-w-xs">
                    <LucideCamera class="pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 text-white/80" />
                    <select v-model="selectedCamera" class="h-11 w-full cursor-pointer appearance-none rounded-full border border-white/20 bg-white/10 pl-12 pr-10 text-label text-white outline-none backdrop-blur-md focus-visible:ring-2 focus-visible:ring-white" :aria-label="$t('label.default')">
                        <option v-for="camera in cameras" :key="camera.label" :value="camera" class="text-black">
                            {{ camera.label ? camera.label : $t('label.default') }}
                        </option>
                    </select>
                    <LucideChevronDown class="pointer-events-none absolute right-4 top-1/2 -translate-y-1/2 text-white/80" />
                </div>
                <div class="relative flex-1 overflow-hidden rounded-2xl ring-1 ring-white/10">
                    <qrcode-stream
                        v-if="selectedCamera !== null"
                        :track="paintOutline"
                        @detect="onDetect"
                        @error="onError"
                        @camera-on="cameraOn"
                        @camera-off="cameraOff"
                    ></qrcode-stream>
                    <!-- viewfinder -->
                    <div v-if="cameraIsOn" aria-hidden="true" class="pointer-events-none absolute left-1/2 top-1/2 size-56 -translate-x-1/2 -translate-y-1/2 sm:size-64">
                        <span class="absolute left-0 top-0 size-10 rounded-tl-[28px] border-l-4 border-t-4 border-white/90"></span>
                        <span class="absolute right-0 top-0 size-10 rounded-tr-[28px] border-r-4 border-t-4 border-white/90"></span>
                        <span class="absolute bottom-0 left-0 size-10 rounded-bl-[28px] border-b-4 border-l-4 border-white/90"></span>
                        <span class="absolute bottom-0 right-0 size-10 rounded-br-[28px] border-b-4 border-r-4 border-white/90"></span>
                    </div>
                </div>
            </div>
            <Modal v-model:is-active="showQrContent">
                <QrContentDisplay :qrContent="form.uri" />
            </Modal>
        </section>
        <VueFooter>
            <template #default>
                <NavigationButton action="cancel" :isCapture="true" :useLinkTag="false" @canceled="exitStream()" />
            </template>
        </VueFooter>
    </div>
</template>
