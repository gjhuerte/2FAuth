<script setup>
    import { useNotify } from '@2fauth/ui'
    import { LucideCopy } from '@lucide/vue'
    import { useI18n } from 'vue-i18n'
    const { t } = useI18n()

    const notify = useNotify()
    const { copy } = useClipboard({ legacy: true })

    const props = defineProps({
        token: String,
    })

    function copyToClipboard() {
        copy(props.token)
        notify.success({ text: t('notification.copied_to_clipboard') })
    }
</script>

<template>
    <button type="button" :aria-label="$t('label.copy_to_clipboard')" :title="$t('tooltip.copy_to_clipboard')" class="md-icon-btn md-icon-btn-sm float-right" @click.stop="copyToClipboard()">
        <LucideCopy />
    </button>
</template>
