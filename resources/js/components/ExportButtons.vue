<script setup>
    import { LucideFileJson, LucideFileText } from '@lucide/vue'

    const router = useRouter()
    const emit = defineEmits(['export-twofauth-format', 'export-otpauth-format'])
    const $2fauth = inject('2fauth')

</script>

<template>
    <div class="flex flex-col gap-4 text-left">
        <section class="rounded-lg bg-md-surface-container-high p-5">
            <p class="text-title text-md-on-surface">
                {{ $t('message.twofauth_export_format_sub') }}
            </p>
            <p class="mt-2 text-label font-normal leading-relaxed text-md-on-surface-variant">
                {{ $t('message.twofauth_export_format_desc') }}
                {{ $t('message.twofauth_export_format_url') }}
                <a id="lnkExportSchemaUrl" class="md-link" :href="$2fauth.urls.exportSchemaUrl" target="_blank" rel="noopener">
                    {{ $t('link.twofauth_export_schema') }}
                </a>
            </p>
            <button type="button" id="btnExport2FAuth" class="md-btn md-btn-filled mt-4" @click="$emit('export-twofauth-format')" :title="$t('tooltip.twofauth_export_format_sub')">
                <LucideFileJson />
                {{ $t('label.twofauth_export_format') }}
            </button>
        </section>
        <section class="rounded-lg bg-md-surface-container-high p-5">
            <p class="text-title text-md-on-surface">
                {{ $t('message.otpauth_export_format_sub') }}
            </p>
            <p class="mt-2 text-label font-normal leading-relaxed text-md-on-surface-variant">
                {{ $t('message.otpauth_export_format_desc') }}
            </p>
            <button type="button" id="btnExportOtpauth" class="md-btn md-btn-tonal mt-4" @click="$emit('export-otpauth-format')" :title="$t('tooltip.otpauth_export_format_sub')">
                <LucideFileText />
                {{ $t('label.otpauth_export_format') }}
            </button>
        </section>
    </div>
</template>
