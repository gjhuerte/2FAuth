<script setup>
    const { copy } = useClipboard({ legacy: true })
    import { useNotify } from '@2fauth/ui'
    import { LucideCopy, LucideExternalLink, LucideQrCode } from '@lucide/vue'
    import { useI18n } from 'vue-i18n'

    const { t } = useI18n()
    const notify = useNotify()

    const props = defineProps({
        qrContent: String,
    })

    /**
     * Checks if a string is an url
     * 
     * @param {string} str 
     */
    function isUrl(str) {
        var strRegex = /^(?:http(s)?:\/\/)?[\w.-]+(?:\.[\w\.-]+)+[\w\-\._~:/?#[\]@!\$&'\(\)\*\+,;=.]+$/
        var re = new RegExp(strRegex)

        return re.test(str)
    }

    /**
     * Opens an uri in a new browser window
     * 
     * @param {string} uri 
     */
    function openInBrowser(uri) {
        const a = document.createElement('a')
        a.setAttribute('href', uri)
        a.dispatchEvent(new MouseEvent("click", { 'view': window, 'bubbles': true, 'cancelable': true }))
    }

    /**
     * Copies to clipboard and notify
     * 
     * @param {*} data 
     */
    function copyToClipboard(data) {
        copy(data)
        notify.success({ text: t('notification.copied_to_clipboard') })
    }
</script>

<template>
    <div class="flex flex-col items-center gap-5 text-center">
        <span class="too-bad inline-flex size-16 items-center justify-center rounded-lg bg-md-error-container text-md-on-error-container" aria-hidden="true">
            <LucideQrCode class="size-8!" />
        </span>
        <p class="text-body text-md-on-surface">
            {{ $t('error.data_of_qrcode_is_not_valid_URI') }}
        </p>
        <p
            class="light-or-darker w-full break-all rounded-md bg-md-surface-container-highest px-4 py-3 font-mono text-label text-md-on-surface-variant"
            
        >{{ qrContent ? qrContent : '[' + $t('message.nothing') + ']' }}</p>
        <div class="flex flex-wrap justify-center gap-3">
            <!-- Copy to clipboard -->
            <button v-if="qrContent" type="button" class="md-btn md-btn-tonal" @click.stop="copyToClipboard(qrContent)">
                <LucideCopy />
                {{ $t('label.copy_to_clipboard') }}
            </button>
            <!-- Open in browser -->
            <button v-if="isUrl(qrContent)" type="button" class="md-btn md-btn-outlined" @click="openInBrowser(qrContent)">
                {{ $t('label.open_in_browser') }}
                <LucideExternalLink />
            </button>
        </div>
    </div>
</template>
