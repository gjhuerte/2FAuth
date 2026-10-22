<script setup>
    import AuthCard from '@/components/AuthCard.vue'
    import Form from '@/components/formElements/Form'
    import { useUserStore } from '@/stores/user'
    import { useAppSettingsStore } from '@/stores/appSettings'
    import { webauthnService } from '@/services/webauthn/webauthnService'
    import { useNotify } from '@2fauth/ui'
    import { useI18n } from 'vue-i18n'
    import { useErrorHandler } from '@2fauth/stores'
    import { LucideCheck, LucideFingerprint } from '@lucide/vue'

    const errorHandler = useErrorHandler()
    const { t } = useI18n()
    const user = useUserStore()
    const notify = useNotify()
    const router = useRouter()
    const showWebauthnRegistration = ref(false)
    const appSettings = useAppSettingsStore()
    const deviceId = ref(null)
    
    const registerForm = reactive(new Form({
        name : '',
        email : '',
        password : '',
        password_confirmation : '',
    }))

    const renameDeviceForm = reactive(new Form({
        name : ''
    }))

    /**
     * Register a new user
     */
    async function register(e) {
        registerForm.password_confirmation = registerForm.password

        registerForm.post('/user').then(response => {
            user.$patch({
                id: response.data.id,
                name: response.data.name,
                email: response.data.email,
                preferences: response.data.preferences,
                isAdmin: response.data.is_admin ?? false,
            })
            user.applyTheme()

            for (const [key, value] of Object.entries(response?.data?.appSettings || {})) {
                appSettings[key] = value
            }

            showWebauthnRegistration.value = true
        })
    }    

    /**
     * Register a new security device
     */
    function registerWebauthnDevice() {
        webauthnService.register().then((response) => {
            const publicKeyCredential = JSON.parse(response.config.data)

            deviceId.value = publicKeyCredential.id
        })
        .catch(error => {
            if( error.response.status === 422 ) {
                notify.alert({ text: error.response.data.message })
            }
            else {
                errorHandler.show(error)
            }
        })
    }

    /**
     * Rename the registered device
     */
    function RenameDevice(e) {
        renameDeviceForm.patch('/webauthn/credentials/' + deviceId.value + '/name')
        .then(() => {
            notify.success({ text: t('notification.device_successfully_registered') })
            router.push({ name: 'accounts' })
        })
    }

    onBeforeRouteLeave(() => {
        notify.clear()
    })
</script>

<template>
    <StackLayout>
        <template #content>
            <!-- webauthn registration -->
            <AuthCard v-if="showWebauthnRegistration" title="heading.authentication" punchline="message.enhance_security_using_webauthn">
                <p class="mb-6 text-body leading-relaxed text-md-on-surface-variant">
                    {{ $t('message.webauthn_uses_trusted_devices') }}
                </p>
                <div v-if="deviceId">
                    <p id="lblDeviceRegistrationSuccess" class="md-callout md-callout-success mb-6">
                        <LucideCheck />
                        {{ $t('notification.device_successfully_registered') }}
                    </p>
                    <form @submit.prevent="RenameDevice" @keydown="renameDeviceForm.onKeydown($event)">
                        <FormField v-model="renameDeviceForm.name" fieldName="name" :errorMessage="renameDeviceForm.errors.get('name')" inputType="text" placeholder="iPhone 12, TouchID, Yubikey 5C" label="field.name_this_device" />
                        <FormButtons :isBusy="renameDeviceForm.isBusy" :isDisabled="renameDeviceForm.isDisabled" submitLabel="label.continue" :isFullWidth="true" />
                    </form>
                </div>
                <div v-else class="flex flex-col gap-3">
                    <!-- register button -->
                    <button type="button" id="btnRegisterNewDevice" @click="registerWebauthnDevice()" class="md-btn md-btn-filled md-btn-lg w-full">
                        <LucideFingerprint />
                        {{ $t('label.register_a_device') }}
                    </button>
                    <!-- dismiss button -->
                    <RouterLink id="btnMaybeLater" :to="{ name: 'accounts' }" class="md-btn md-btn-text md-btn-lg w-full">{{ $t('link.maybe_later') }}</RouterLink>
                </div>
            </AuthCard>
            <!-- User registration form -->
            <AuthCard v-else title="heading.register" punchline="message.you_need_an_account_to_go_further">
                <form @submit.prevent="register" @keydown="registerForm.onKeydown($event)">
                    <FormField v-model="registerForm.name" fieldName="name" :errorMessage="registerForm.errors.get('name')" inputType="text" label="field.name" autocomplete="username" :maxLength="255" autofocus />
                    <FormField v-model="registerForm.email" fieldName="email" :errorMessage="registerForm.errors.get('email')" inputType="email" label="field.email" autocomplete="email" :maxLength="255" />
                    <FormPasswordField v-model="registerForm.password" fieldName="password" :errorMessage="registerForm.errors.get('password')" :showRules="true" autocomplete="new-password" label="field.password" />
                    <FormButtons :isBusy="registerForm.isBusy" :isDisabled="registerForm.isDisabled" submitLabel="label.register" submitId="btnRegister" :isFullWidth="true" />
                </form>
                <template #links>
                    <p>{{ $t('message.already_register') }} <RouterLink id="lnkSignIn" :to="{ name: 'login' }" class="md-link">{{ $t('link.sign_in') }}</RouterLink></p>
                </template>
            </AuthCard>
        </template>
        <template #footer>
            <VueFooter />
        </template>
    </StackLayout>
</template>
