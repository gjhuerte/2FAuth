<script setup>
    import systemService from '@/services/systemService'
    import { useAppSettingsStore } from '@/stores/appSettings'
    import { LucideCheck, LucideX } from '@lucide/vue'

    const appSettings = useAppSettingsStore()
    const isScanning = ref(false)
    const isUpToDate = ref()

    async function getLatestRelease() {
        isScanning.value = true;
        isUpToDate.value = undefined

        await systemService.getLastRelease({returnError: true})
        .then(response => {
            appSettings.latestRelease = response.data.newRelease
            isUpToDate.value = response.data.newRelease === null ? null : response.data.newRelease === false
        })
        .catch(() => {
            isUpToDate.value = null
        })

        isScanning.value = false;
    }

</script>

<template>
    <div class="flex flex-wrap items-center gap-4">
        <VueButton nativeType="button" color="tonal" size="sm" :isLoading="isScanning" @click="getLatestRelease">{{ $t('label.check_now') }}</VueButton>
        <div class="text-label font-normal text-md-on-surface-variant">
            <span v-if="appSettings.latestRelease" class="md-badge md-badge-warning h-auto py-1">
                <span class="release-flag size-2 rounded-full bg-md-warning"></span>{{ $t('message.x_is_available', { version: appSettings.latestRelease }) }}
                <a class="underline" href="https://github.com/Bubka/2FAuth/releases" target="_blank" rel="noopener">{{ $t('link.view_on_github') }}</a>
            </span>
            <span v-if="isUpToDate" class="inline-flex items-center gap-1.5">
                <LucideCheck class="text-md-success" />{{ $t('message.you_are_up_to_date') }}
            </span>
            <span v-else-if="isUpToDate === null" class="inline-flex items-center gap-1.5">
                <LucideX class="text-md-error" />{{ $t('error.check_failed_try_later') }}
            </span>
        </div>
    </div>
</template>
