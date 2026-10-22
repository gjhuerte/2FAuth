<script setup>
    import tabs from './tabs'
    import systemService from '@/services/systemService'
    import { useAppSettingsUpdater } from '@/composables/appSettingsUpdater'
    import { useAppSettingsStore } from '@/stores/appSettings'
    import { useNotify, TabBar } from '@2fauth/ui'
    import { useErrorHandler } from '@2fauth/stores'
    import { useUserStore } from '@/stores/user'
    import VersionChecker from '@/components/VersionChecker.vue'
    import CopyButton from '@/components/CopyButton.vue'
    import { useI18n } from 'vue-i18n'
    import { LucideExternalLink, LucideSend } from '@lucide/vue'
    import { useSettingsBreakpoints } from '@/composables/breakpoints'

    const errorHandler = useErrorHandler()
    const { t } = useI18n()
    const $2fauth = inject('2fauth')
    const user = useUserStore()
    const notify = useNotify()
    const appSettings = useAppSettingsStore()
    const returnTo = useStorage($2fauth.prefix + 'returnTo', 'accounts')
    const { isLaptop } = useSettingsBreakpoints()

    const infos = ref()
    const listInfos = ref(null)
    const isSendingTestEmail = ref(false)
    const testEmailError = ref(null)
    const isClearingCache = ref(false)
    const healthEndPoint = $2fauth.config.subdirectory + '/up'
    const healthEndPointFullPath = location.hostname + $2fauth.config.subdirectory + '/up'
    
    const generalRef = useTemplateRef('heading-general')
    const sharingRef = useTemplateRef('heading-sharing')
    const storageRef = useTemplateRef('heading-storage')
    const securityRef = useTemplateRef('heading-security')
    const environmentRef = useTemplateRef('heading-environment')

    const scrollTo = (elRef) => {
        if (!elRef) return

        elRef.scrollIntoView({ behavior: 'smooth' })
    }

    /**
     * Sends a test email
     */
    function sendTestEmail() {
        isSendingTestEmail.value = true
        testEmailError.value = null

        systemService.sendTestEmail({returnError: true}).then(response => {
            notify.success({ text: t('notification.test_email_sent') })
        })
        .catch(error => {
            if (error.response.status === 424) {
                testEmailError.value = error.response.data.details
            }
            else  {
                errorHandler.show(error)
            }
        })
        .finally(() => {
            isSendingTestEmail.value = false;
        })
    }

    /**
     * clears app cache
     */
    function clearCache() {
        isClearingCache.value = true;

        systemService.clearCache().then(response => {
            notify.success({ text: t('notification.cache_cleared') })
        })
        .finally(() => {
            isClearingCache.value = false;
        })
    }

    /**
     * Saves a setting
     */
    async function saveSetting(setting, value) {
        const { error } = await useAppSettingsUpdater(setting, value)

        if (error == null) {
            notify.success({ text: t('notification.setting_saved') })
        }
    }


    onBeforeRouteLeave((to) => {
        if (! to.name.startsWith('admin.')) {
            notify.clear()
        }
    })

    onMounted(async () => {
        await appSettings.fetch()

        systemService.getSystemInfos({returnError: true}).then(response => {
            infos.value = response.data.common
        })
        .catch(() => {
            infos.value = null
        })
    })

</script>

<template>
    <StackLayout>
        <template #header>
            <TabBar :tabs="tabs" :active-tab="'admin.appSetup'" @tab-selected="(to) => router.push({ name: to })" />
        </template>
        <template #content>
            <ResponsiveWidthWrapper>
                <div v-if="isLaptop && user.preferences.showQuickNavMenus" class="settings-menu fixed top-32 -ml-60 w-52">
                    <aside class="menu">
                        <ul class="menu-list flex flex-col gap-0.5">
                            <li><button type="button" class="md-menu-item h-10 rounded-full" @click="scrollTo(generalRef)">{{ $t('heading.general') }}</button></li>
                            <li><button type="button" class="md-menu-item h-10 rounded-full" @click="scrollTo(sharingRef)">{{ $t('heading.sharing') }}</button></li>
                            <li><button type="button" class="md-menu-item h-10 rounded-full" @click="scrollTo(storageRef)">{{ $t('heading.storage') }}</button></li>
                            <li><button type="button" class="md-menu-item h-10 rounded-full" @click="scrollTo(securityRef)">{{ $t('heading.security') }}</button></li>
                            <li><button type="button" class="md-menu-item h-10 rounded-full" @click="scrollTo(environmentRef)">{{ $t('heading.environment') }}</button></li>
                        </ul>
                    </aside>
                </div>
                <div class="animate-enter pb-8">
                <form>
                    <section class="md-card mb-4 sm:p-8">
                    <h2 ref="heading-general" class="md-section-title mb-6 scroll-mt-6">{{ $t('heading.general') }}</h2>
                    <!-- Check for update -->
                    <FormCheckbox v-model="appSettings.checkForUpdate" @update:model-value="val => saveSetting('checkForUpdate', val)" fieldName="checkForUpdate" label="field.check_for_update" help="field.check_for_update.help" />
                    <div class="mb-6 ml-11">
                        <VersionChecker />
                    </div>
                    <!-- email config test -->
                    <div class="mb-6 rounded-md bg-md-surface-container-high p-5">
                        <label class="block text-body font-medium text-md-on-surface" for="btnTestEmail">{{ $t('field.test_email') }}</label>
                        <p class="mt-1 text-label font-normal leading-relaxed text-md-on-surface-variant">{{ $t('field.test_email.help') }}</p>
                        <p class="mt-1 text-label font-normal text-md-on-surface-variant">
                            <i18n-t keypath="message.email_will_be_send_to_x" tag="span">
                                <template v-slot:email>
                                    <span class="font-mono text-md-primary">{{ user.email }}</span>
                                </template>
                            </i18n-t>
                        </p>
                        <VueButton id="btnTestEmail" nativeType="button" color="tonal" size="sm" class="mt-4" :isLoading="isSendingTestEmail" @click="sendTestEmail">
                            <LucideSend v-if="!isSendingTestEmail" />
                            {{ $t('label.send') }}
                        </VueButton>
                        <div v-if="testEmailError" class="about-debug mt-4 rounded-sm bg-md-error-container/50 p-4 font-mono text-label-sm text-md-on-error-container">
                            <FormFieldError v-if="testEmailError" :error="$t('error.email_sending_failed')" :field="'testEmail'" />
                            {{ testEmailError }}
                        </div>
                    </div>
                    <!-- healthcheck -->
                    <div class="mb-6 rounded-md bg-md-surface-container-high p-5">
                        <label class="block text-body font-medium text-md-on-surface" for="lnkHealthCheck">{{ $t('field.health_endpoint') }}</label>
                        <p class="mt-1 text-label font-normal leading-relaxed text-md-on-surface-variant">{{ $t('field.health_endpoint.help') }}</p>
                        <a id="lnkHealthCheck" class="md-link mt-3 inline-flex items-center gap-1.5 break-all font-mono text-label" target="_blank" rel="noopener" :href="healthEndPoint">
                            {{ healthEndPointFullPath }}
                            <LucideExternalLink class="size-4! shrink-0" />
                        </a>
                    </div>
                    </section>
                    <section class="md-card mb-4 sm:p-8">
                    <h2 ref="heading-sharing" class="md-section-title mb-6 scroll-mt-6">{{ $t('heading.sharing') }}</h2>
                    <!-- sharing -->
                    <FormCheckbox v-model="appSettings.enableSharing" @update:model-value="val => saveSetting('enableSharing', val)" fieldName="enableSharing" label="field.enable_sharing" help="field.enable_sharing.help" />
                    <FormCheckbox v-model="appSettings.enableAllUsersSharingScope" @update:model-value="val => saveSetting('enableAllUsersSharingScope', val)" fieldName="enableAllUsersSharingScope"  :isDisabled="!appSettings.enableSharing" :isIndented="true" label="field.enable_all_users_sharing_scope" help="field.enable_all_users_sharing_scope.help" />
                    <p class="-mt-2 mb-4 ml-[4.25rem] text-label font-normal text-md-on-surface-variant">{{ $t('field.enable_all_users_sharing_scope.help_bis') }}</p>
                    <a id="lnkSharingDoc" class="md-link mt-2 inline-flex items-center gap-1.5" target="_blank" rel="noopener" href="https://docs.2fauth.app/usage/2fa-sharing/">
                        {{ $t('link.sharing_doc') }}
                        <LucideExternalLink class="size-4!" />
                    </a>
                    </section>
                    <section class="md-card mb-4 sm:p-8">
                    <h2 ref="heading-storage" class="md-section-title mb-6 scroll-mt-6">{{ $t('heading.storage') }}</h2>
                    <!-- store icons in database -->
                    <FormCheckbox v-model="appSettings.storeIconsInDatabase" @update:model-value="val => saveSetting('storeIconsInDatabase', val)" fieldName="storeIconsInDatabase" label="field.store_icon_to_database" help="field.store_icon_to_database.help" />
                    <p class="-mt-2 mb-4 ml-11 text-label font-normal text-md-on-surface-variant">{{ $t('field.store_icon_to_database.help_bis') }}</p>
                    <a id="lnkIconsDoc" class="md-link mt-2 inline-flex items-center gap-1.5" target="_blank" rel="noopener" href="https://docs.2fauth.app/usage/icons/">
                        {{ $t('link.icons_doc') }}
                        <LucideExternalLink class="size-4!" />
                    </a>
                    </section>
                    <section class="md-card mb-4 sm:p-8">
                    <h2 ref="heading-security" class="md-section-title mb-6 scroll-mt-6">{{ $t('heading.security') }}</h2>
                    <!-- protect db -->
                    <FormCheckbox v-model="appSettings.useEncryption" @update:model-value="val => saveSetting('useEncryption', val)" fieldName="useEncryption" label="field.use_encryption" help="field.use_encryption.help" />
                    </section>
                </form>

                <section class="md-card mb-4 sm:p-8">
                <h2 ref="heading-environment" class="md-section-title mb-6 scroll-mt-6">{{ $t('heading.environment') }}</h2>
                <!-- cache management -->
                    <div class="mb-6 rounded-md bg-md-surface-container-high p-5">
                        <label class="block text-body font-medium text-md-on-surface" for="btnClearCache">{{ $t('field.cache_management') }}</label>
                        <p class="mt-1 text-label font-normal leading-relaxed text-md-on-surface-variant">{{ $t('field.cache_management.help') }}</p>
                        <VueButton id="btnClearCache" nativeType="button" color="tonal" size="sm" class="mt-4" :isLoading="isClearingCache" @click="clearCache">
                            {{ $t('label.clear') }}
                        </VueButton>
                    </div>
                <!-- env vars -->
                <label for="btnCopyEnvVars" class="mb-2 block px-1 text-label text-md-on-surface-variant">{{ $t('label.variables') }}</label>
                <div v-if="infos" class="about-debug relative rounded-md bg-md-surface-container-highest p-5 font-mono text-label-sm shadow-inner">
                    <CopyButton id="btnCopyEnvVars" :token="listInfos?.innerText" />
                    <ul ref="listInfos" id="listInfos" class="flex flex-col gap-1">
                        <li v-for="(value, preference) in infos" :value="value" :key="preference" class="break-all">
                            <b class="font-medium text-md-on-surface">{{ preference }}</b>: <span class="text-md-on-surface-variant">{{ value }}</span>
                        </li>
                    </ul>
                </div>
                <div v-else-if="infos === null" class="about-debug md-callout md-callout-warning">
                    {{ $t('error.error_during_data_fetching') }}
                </div>
                </section>
                </div>
            </ResponsiveWidthWrapper>
        </template>
        <template #footer>
            <VueFooter>
                <template #default>
                    <NavigationButton action="close" @closed="router.push({ name: returnTo })" :current-page-title="$t('title.admin.appSetup')" />
                </template>
            </VueFooter>
        </template>
    </StackLayout>
</template>
