<script setup>
    import Form from '@/components/formElements/Form'
    import SsoConnectLink from '@/components/SsoConnectLink.vue'
    import AuthCard from '@/components/AuthCard.vue'
    import { LucideFingerprint, LucideFlaskConical, LucideSparkles, LucideTriangleAlert } from '@lucide/vue'
    import { useUserStore } from '@/stores/user'
    import { useNotify } from '@2fauth/ui'
    import { useAppSettingsStore } from '@/stores/appSettings'
    import { webauthnService } from '@/services/webauthn/webauthnService'
    import { useI18n } from 'vue-i18n'
    import { useErrorHandler } from '@2fauth/stores'

    const errorHandler = useErrorHandler()
    const { t } = useI18n()
    const $2fauth = inject('2fauth')
    const router = useRouter()
    const user = useUserStore()
    const notify = useNotify()
    const appSettings = useAppSettingsStore()
    const form = reactive(new Form({
        email: '',
        password: ''
    }))
    const isBusy = ref(false)
    const activeLoginForm = useStorage($2fauth.prefix + 'activeLoginForm', null)

    onMounted(() => {
        if (appSettings.enableSso == true && appSettings.useSsoOnly == true) {
            activeLoginForm.value = 'sso'
        }
        else if (activeLoginForm.value == null || activeLoginForm.value == 'sso') {
            activeLoginForm.value = 'legacy'
        }
    })


    /**
     * Toggle the form between legacy and webauthn method
     */
    function switchToForm(formName) {
        form.clear()
        activeLoginForm.value = formName
    }

    /**
     * Sign in using the login/password form
     */
    function LegacysignIn(e) {
        notify.clear()

        form.post('/user/login', {returnError: true}).then(async (response) => {
            await user.loginAs({
                id: response.data.id,
                name: response.data.name,
                email: response.data.email,
                oauth_provider: response.data.oauth_provider,
                authenticated_by_proxy: false,
                preferences: response.data.preferences,
                isAdmin: response.data.is_admin,
            })

            for (const [key, value] of Object.entries(response?.data?.appSettings || {})) {
                appSettings[key] = value
            }

            router.push({ name: 'accounts' })
        })
        .catch(error => {
            if( error.response?.status === 401 ) {
                notify.alert({text: t('notification.authentication_failed'), duration: 10000 })
            }
            else if( error.response?.status !== 422 ) {
                errorHandler.show(error)
            }
        })
    }

    /**
     * Sign in using webauthn
     */
    function webauthnLogin() {
        notify.clear()
        form.clear()
        isBusy.value = true

        webauthnService.authenticate(form.email).then(async (response) => {
            await user.loginAs({
                id: response.data.id,
                name: response.data.name,
                email: response.data.email,
                oauth_provider: response.data.oauth_provider,
                authenticated_by_proxy: false,
                preferences: response.data.preferences,
                isAdmin: response.data.is_admin,
            })

            for (const [key, value] of Object.entries(response?.data?.appSettings || {})) {
                appSettings[key] = value
            }

            router.push({ name: 'accounts' })
        })
        .catch(error => {
            if ('webauthn' in error) {
                if (error.name == 'is-warning') {
                    notify.warn({ text: t(error.message) })
                }
                else notify.alert({ text: t(error.message) })
            }
            else if( error.response.status === 401 ) {
                notify.alert({text: t('notification.authentication_failed'), duration: 10000 })
            }
            else if( error.response.status == 422 ) {
                form.errors.set(form.extractErrors(error.response))
            }
            else {
                errorHandler.show(error)
            }
        })
        .finally(() => {
            isBusy.value = false
        })
    }

</script>

<template>
    <StackLayout>
        <template #content>
            <!-- webauthn authentication -->
            <AuthCard v-if="activeLoginForm == 'webauthn'" title="heading.webauthn_login" punchline="message.welcome_to_2fauth">
                <div v-if="appSettings.enableSso == true && appSettings.useSsoOnly == true" class="md-callout md-callout-warning mb-6">
                    <LucideTriangleAlert />
                    <p>{{ $t('message.sso_only_form_restricted_to_admin') }}</p>
                </div>
                <p class="mb-6 text-body text-md-on-surface-variant">
                    {{ $t('message.use_security_device_to_sign_in') }}
                </p>
                <form id="frmWebauthnLogin" @submit.prevent="webauthnLogin" @keydown="form.onKeydown($event)">
                    <FormField v-model="form.email" fieldName="email" :errorMessage="form.errors.get('email')" inputType="email" label="field.email" autofocus />
                    <FormButtons :isBusy="isBusy" submitLabel="label.continue" submitId="btnContinue" :isFullWidth="true" />
                </form>
                <div v-if="appSettings.enableSso == true && Object.values($2fauth.config.sso).includes(true)" class="mt-8">
                    <div class="mb-4 flex items-center gap-3 text-label-sm text-md-on-surface-variant">
                        <span class="h-px flex-1 bg-md-outline-variant"></span>
                        {{ $t('message.or_continue_with') }}
                        <span class="h-px flex-1 bg-md-outline-variant"></span>
                    </div>
                    <div class="flex flex-wrap justify-center gap-2">
                        <template v-for="(isEnabled, provider) in $2fauth.config.sso" :key="provider">
                            <SsoConnectLink v-if="isEnabled" :provider="provider" />
                        </template>
                    </div>
                </div>
                <template #links>
                    <p>
                        {{ $t('message.lost_your_device') }}
                        <RouterLink id="lnkRecoverAccount" :to="{ name: 'webauthn.lost' }" class="md-link">
                            {{ $t('link.recover_your_account') }}
                        </RouterLink>
                    </p>
                    <p>{{ $t('message.sign_in_using') }}
                        <a id="lnkSignWithLegacy" href="#" role="button" class="md-link" @click.prevent="switchToForm('legacy')">
                            {{ $t('link.login_and_password') }}
                        </a>
                    </p>
                <p v-if="appSettings.disableRegistration == false && appSettings.useSsoOnly == false">
                    {{ $t('message.dont_have_account_yet') }}
                    <RouterLink id="lnkRegister" :to="{ name: 'register' }" class="md-link">
                        {{ $t('link.register') }}
                    </RouterLink>
                </p>
                </template>
            </AuthCard>
            <!-- SSO only links -->
            <AuthCard v-else-if="activeLoginForm == 'sso'" title="heading.sso_login" punchline="message.welcome_to_2fauth">
                <div v-if="$2fauth.isDemoApp" class="md-callout md-callout-info mb-6">
                    <LucideSparkles />
                    <p>
                        {{ $t('message.welcome_to_demo_app') }}<br />
                        <i18n-t keypath="message.sign_in_using_email_password" tag="span">
                            <template v-slot:email>
                                <strong>demo@2fauth.app</strong>
                            </template>
                            <template v-slot:password>
                                <strong>demo</strong>
                            </template>
                        </i18n-t>
                    </p>
                </div>
                <div v-if="$2fauth.isTestingApp" class="md-callout md-callout-warning mb-6">
                    <LucideFlaskConical />
                    <p>
                        {{ $t('message.welcome_to_testing_app') }}
                        <i18n-t keypath="message.use_those_credentials" tag="span">
                            <template v-slot:email>
                                <strong>testing@2fauth.app</strong>
                            </template>
                            <template v-slot:password>
                                <strong>password</strong>
                            </template>
                        </i18n-t>
                    </p>
                </div>
                <p class="text-body text-md-on-surface">{{ $t('message.password_login_and_webauthn_are_disabled') }}</p>
                <p class="mt-1 text-body text-md-on-surface-variant">{{ $t('message.sign_in_using_sso') }}</p>
                <div v-if="Object.values($2fauth.config.sso).includes(true)" class="mt-6 flex flex-wrap gap-2">
                    <template v-for="(isEnabled, provider) in $2fauth.config.sso" :key="provider">
                        <SsoConnectLink v-if="isEnabled" :provider="provider" />
                    </template>
                </div>
                <p v-else class="mt-6 text-label italic text-md-on-surface-variant">{{ $t('message.no_provider') }}</p>
                <template #links>
                    <p>
                        {{ $t('message.no_sso_provider_or_provider_is_missing') }}
                        <a id="lnkSsoDocs" class="md-link" :href="$2fauth.urls.ssoDocUrl" target="_blank" rel="noopener">
                            {{ $t('link.see_how_to_enable_sso') }}
                        </a>
                    </p>
                    <p>{{ $t('message.if_administrator') }}
                        <a id="lnkSignWithLegacy" href="#" role="button" class="md-link" @click.prevent="switchToForm('legacy')">
                            {{ $t('link.sign_in_here') }}
                        </a>
                    </p>
                </template>
            </AuthCard>
            <!-- login/password legacy form -->
            <AuthCard v-else-if="activeLoginForm == 'legacy'" title="heading.login" punchline="message.welcome_to_2fauth">
                <div v-if="$2fauth.isDemoApp" class="md-callout md-callout-info mb-6">
                    <LucideSparkles />
                    <p>
                        {{ $t('message.welcome_to_demo_app') }}<br />
                        <i18n-t keypath="message.sign_in_using_email_password" tag="span">
                            <template v-slot:email>
                                <strong>demo@2fauth.app</strong>
                            </template>
                            <template v-slot:password>
                                <strong>demo</strong>
                            </template>
                        </i18n-t>
                    </p>
                </div>
                <div v-if="$2fauth.isTestingApp" class="md-callout md-callout-warning mb-6">
                    <LucideFlaskConical />
                    <p>
                        {{ $t('message.welcome_to_testing_app') }}
                        <i18n-t keypath="message.use_those_credentials" tag="span">
                            <template v-slot:email>
                                <strong>testing@2fauth.app</strong>
                            </template>
                            <template v-slot:password>
                                <strong>password</strong>
                            </template>
                        </i18n-t>
                    </p>
                </div>
                <div v-if="appSettings.enableSso == true && appSettings.useSsoOnly == true" class="md-callout md-callout-warning mb-6">
                    <LucideTriangleAlert />
                    <p>{{ $t('message.sso_only_form_restricted_to_admin') }}</p>
                </div>
                <form id="frmLegacyLogin" @submit.prevent="LegacysignIn" @keydown="form.onKeydown($event)">
                    <FormField v-model="form.email" fieldName="email" :errorMessage="form.errors.get('email')" inputType="email" label="field.email" autocomplete="username" autofocus />
                    <FormPasswordField v-model="form.password" fieldName="password" :errorMessage="form.errors.get('password')" label="field.password" autocomplete="current-password" />
                    <div class="-mt-2 flex justify-end">
                        <RouterLink id="lnkResetPwd" :to="{ name: 'password.request' }" class="md-link text-label" :aria-label="$t('label.reset_your_password')">
                            {{ $t('message.forgot_your_password') }}
                        </RouterLink>
                    </div>
                    <FormButtons :isBusy="form.isBusy" submitLabel="label.sign_in" submitId="btnSignIn" :isFullWidth="true" />
                </form>
                <button
                    id="lnkSignWithWebauthn"
                    type="button"
                    class="md-btn md-btn-outlined md-btn-lg mt-3 w-full"
                    @click="switchToForm('webauthn')"
                >
                    <LucideFingerprint />
                    {{ $t('tooltip.sign_in_using_security_device') }}
                </button>
                <div v-if="appSettings.enableSso == true && Object.values($2fauth.config.sso).includes(true)" class="mt-8">
                    <div class="mb-4 flex items-center gap-3 text-label-sm text-md-on-surface-variant">
                        <span class="h-px flex-1 bg-md-outline-variant"></span>
                        {{ $t('message.or_continue_with') }}
                        <span class="h-px flex-1 bg-md-outline-variant"></span>
                    </div>
                    <div class="flex flex-wrap justify-center gap-2">
                        <template v-for="(isEnabled, provider) in $2fauth.config.sso" :key="provider">
                            <SsoConnectLink v-if="isEnabled" :provider="provider" />
                        </template>
                    </div>
                </div>
                <template #links>
                <p v-if="appSettings.disableRegistration == false && appSettings.useSsoOnly == false">
                    {{ $t('message.dont_have_account_yet') }}
                    <RouterLink id="lnkRegister" :to="{ name: 'register' }" class="md-link">
                        {{ $t('link.register') }}
                    </RouterLink>
                </p>
                </template>
            </AuthCard>
        </template>
        <template #footer>
            <VueFooter />
        </template>
    </StackLayout>
</template>
