<script setup>
    import tabs from './tabs'
    import userService from '@/services/userService'
    import { webauthnService } from '@/services/webauthn/webauthnService'
    import { useAppSettingsStore } from '@/stores/appSettings'
    import { useUserStore } from '@/stores/user'
    import { useNotify, TabBar } from '@2fauth/ui'
    import { useI18n } from 'vue-i18n'
    import { useErrorHandler } from '@2fauth/stores'
    import { LucideCirclePlus, LucideFingerprint, LucideInfo, LucideTriangleAlert } from '@lucide/vue'

    const errorHandler = useErrorHandler()
    const { t } = useI18n()
    const $2fauth = inject('2fauth')
    const user = useUserStore()
    const appSettings = useAppSettingsStore()
    const notify = useNotify()
    const router = useRouter()
    const returnTo = useStorage($2fauth.prefix + 'returnTo', 'accounts')
    const activeLoginForm = useStorage($2fauth.prefix + 'activeLoginForm', 'legacy')

    const credentials = ref([])
    const isFetching = ref(false)

    const isDisabled = computed(() => {
        return (appSettings.enableSso && appSettings.useSsoOnly) || user.authenticated_by_proxy
    })
    
    onMounted(() => {
        fetchCredentials()
    })

    watch(() => user.preferences.useWebauthnOnly, () => {
        userService.updatePreference('useWebauthnOnly', user.preferences.useWebauthnOnly).then(response => {
            notify.success({ text: t('notification.setting_saved') })
        })
    })

    /**
     * Register a new security device
     */
    function register() {
        if (isDisabled.value == true) {
            notify.warn({text: t('error.unsupported_with_reverseproxy') })
            return false
        }

        webauthnService.register().then((response) => {
            router.push({ name: 'settings.webauthn.editCredential', params: { credentialId: JSON.parse(response.config.data).id } })
        })
        .catch(error => {
            if ('webauthn' in error) {
                if (error.name == 'is-warning') {
                    notify.warn({ text: t(error.message) })
                }
                else notify.alert({ text: t(error.message) })
            }
            else if( error.response?.status === 422 ) {
                notify.alert({ text: error.response.data.message })
            }
            else {
                errorHandler.show(error)
            }
        })
    }

    /**
     * revoke a credential
     */
    function revokeCredential(credentialId) {
        if(confirm(t('confirmation.revoke_device'))) {
            userService.revokeWebauthnDevice(credentialId).then(response => {
                // Remove the revoked credential from the collection
                credentials.value = credentials.value.filter(a => a.id !== credentialId)

                // Then we disable the useWebauthnOnly preference which is relevant
                // only when at least one device is registered
                if (credentials.value.length == 0) {
                    user.preferences.useWebauthnOnly = false
                }

                notify.success({ text: t('notification.device_revoked') })
            });
        }
    }

    /**
     * Always display a printable name
     */
    function displayName(credential) {
        return credential.alias ? credential.alias : t('label.my_device') + ' (#' + credential.id.substring(0, 10) + ')'
    }

    /**
     * Get all credentials from backend
     */
    function fetchCredentials() {
        isFetching.value = true

        userService.getWebauthnDevices({returnError: true})
        .then(response => {
            credentials.value = response.data
        })
        .catch(error => {
            if( error.response.status === 403 ) {
                // The backend returns a 403 response if the user is authenticated by a reverse proxy
                // or if SSO only is enabled.
                // The form is already disabled (see isDisabled) so we do nothing more here
            }
            else {
                errorHandler.show(error)
            }
        })
        .finally(() => {
            isFetching.value = false
        })
    }

    /**
     * Updates the active login form on local storage
     */
    async function setActiveLoginForm() {
        activeLoginForm.value = 'webauthn'
    }

    onBeforeRouteLeave((to) => {
        if (! to.name.startsWith('settings.')) {
            notify.clear()
        }
    })
</script>

<template>
    <StackLayout>
        <template #header>
            <TabBar :tabs="tabs" :active-tab="'settings.webauthn.devices'" @tab-selected="(to) => router.push({ name: to })" />
        </template>
        <template #content>
            <FormWrapper>
                <p v-if="isDisabled && user.oauth_provider" class="md-callout md-callout-warning mb-6">
                    <LucideTriangleAlert />
                    <span>{{ $t('message.sso_only_x_settings_are_disabled', { auth_method: 'WebAuthn' }) }}</span>
                </p>
                <p v-if="isDisabled && user.authenticated_by_proxy" class="md-callout md-callout-warning mb-6">
                    <LucideTriangleAlert />
                    <span>{{ $t('message.auth_handled_by_proxy') + ' ' + $t('message.manage_auth_at_proxy_level') }}</span>
                </p>
                <div class="flex flex-wrap items-end justify-between gap-4">
                    <div>
                        <h1 class="md-page-title">{{ $t('heading.security_devices') }}</h1>
                        <p class="mt-2 max-w-prose text-body text-md-on-surface-variant">
                            {{ $t('message.security_devices_legend')}}
                        </p>
                    </div>
                    <button type="button" class="md-btn md-btn-tonal" @click="register">
                        <LucideCirclePlus /> {{ $t('link.register_a_new_device')}}
                    </button>
                </div>
                <!-- credentials list -->
                <div v-if="credentials.length > 0" class="mt-8">
                    <ul class="flex flex-col gap-2">
                        <li v-for="credential in credentials" :key="credential.id" class="group-item md-card flex items-center gap-3 px-5 py-3">
                            <span class="inline-flex size-10 shrink-0 items-center justify-center rounded-md bg-md-secondary-container text-md-on-secondary-container">
                                <LucideFingerprint />
                            </span>
                            <span class="min-w-0 flex-1 truncate text-title text-md-on-surface">{{ displayName(credential) }}</span>
                            <!-- revoke link -->
                            <button type="button" class="md-btn md-btn-danger-text md-btn-xs" @click="revokeCredential(credential.id)" :title="$t('tooltip.revoke')">
                                {{ $t('label.revoke') }}
                            </button>
                        </li>
                    </ul>
                    <p class="mt-4 flex items-center justify-end gap-1.5 text-label-sm text-md-on-surface-variant">
                        <LucideInfo class="size-4!" />
                        {{ $t('message.revoking_a_device_is_permanent')}}
                    </p>
                </div>
                <Spinner :isVisible="isFetching && credentials.length === 0" type="list-loading" />
                <section class="md-card mb-8 mt-8 sm:p-8">
                    <h2 class="md-section-title">{{ $t('heading.options') }}</h2>
                    <p class="mb-6 mt-1 text-label font-normal text-md-on-surface-variant">
                        {{ $t('message.need_a_security_device_to_enable_options')}}
                    </p>
                    <form>
                        <!-- use webauthn only -->
                        <FormCheckbox
                            v-model="user.preferences.useWebauthnOnly"
                            @update:model-value="val => setActiveLoginForm()"
                            fieldName="useWebauthnOnly"
                            label="field.use_webauthn_only"
                            help="field.use_webauthn_only.help"
                            :isDisabled="isDisabled || credentials.length === 0"
                        />
                        <div class="ml-11 flex flex-col gap-2 text-label font-normal leading-relaxed text-md-on-surface-variant">
                            <p>{{ $t('field.use_webauthn_only.help_bis') }}</p>
                            <p>{{ $t('field.use_webauthn_only.help_ter') }}</p>
                        </div>
                    </form>
                </section>
            </FormWrapper>
        </template>
        <template #footer>
            <VueFooter>
                <template #default>
                    <NavigationButton action="close" @closed="router.push({ name: returnTo })" :current-page-title="$t('title.settings.webauthn.devices')" />
                </template>
            </VueFooter>
        </template>
    </StackLayout>
</template>
