<script setup>
    import tabs from './tabs'
    import Form from '@/components/formElements/Form'
    import userService from '@/services/userService'
    import { useAppSettingsStore } from '@/stores/appSettings'
    import { useNotify, TabBar } from '@2fauth/ui'
    import { useUserStore } from '@/stores/user'
    import { useI18n } from 'vue-i18n'
    import { useErrorHandler } from '@2fauth/stores'
    import { LucideCirclePlus, LucideCheck, LucideCopy, LucideInfo, LucideKeyRound, LucideTriangleAlert } from '@lucide/vue'

    const errorHandler = useErrorHandler()
    const { t } = useI18n()
    const appSettings = useAppSettingsStore()
    const $2fauth = inject('2fauth')
    const notify = useNotify()
    const user = useUserStore()
    const returnTo = useStorage($2fauth.prefix + 'returnTo', 'accounts')
    const { copy } = useClipboard({ legacy: true })

    const tokens = ref([])
    const isFetching = ref(false)
    const createPATModalIsVisible = ref(false)
    const visibleToken = ref(null)
    const visibleTokenId = ref(null)

    const isDisabled = computed(() => {
        return (appSettings.enableSso && appSettings.useSsoOnly && ! appSettings.allowPatWhileSsoOnly) || user.authenticated_by_proxy
    })

    onMounted(() => {
        fetchTokens()
    })

    const form = reactive(new Form({
        name : '',
    }))

    /**
     * Get all groups from backend
     */
    function fetchTokens() {
        isFetching.value = true

        userService.getPersonalAccessTokens({returnError: true})
        .then(response => {
            tokens.value = []
            response.data.forEach((data) => {
                if (data.id === visibleTokenId.value) {
                    data.value = visibleToken.value
                    tokens.value.unshift(data)
                }
                else {
                    tokens.value.push(data)
                }
            })
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
            visibleTokenId.value = null
            visibleToken.value = null
        })
    }


    /**
     * Open the PAT creation view
     */
    function showPATcreationForm() {
        clearTokenValues()

        if (isDisabled.value) {
            notify.warn({ text: t('error.unsupported_with_reverseproxy') })
        }
        else createPATModalIsVisible.value = true
    }
    
    /**
     * Generate a fresh token
     */
    function generatePAToken() {
        form.post('/oauth/personal-access-tokens')
        .then(response => {
            visibleToken.value = response.data.accessToken
            visibleTokenId.value = response.data.accessTokenId
            fetchTokens()
            createPATModalIsVisible.value = false
            form.reset()
        })
    }

    /**
     * revoke a token (after confirmation)
     */
    function revokeToken(tokenId) {
        if(confirm(t('confirmation.revoke_token'))) {
            userService.deletePersonalAccessToken(tokenId)
            .then(response => {
                // Remove the revoked token from the collection
                tokens.value = tokens.value.filter(a => a.id !== tokenId)
                notify.success({ text: t('notification.token_revoked') })
            })
        }
    }

    /**
     * Removes visible tokens data
     */
    function clearTokenValues() {
        tokens.value.forEach(token => {
            token.value = null
        })
        visibleToken.value = null
    }

    /**
     * Copies data to clipboard and notifies on success
     */
    function copyToClipboard(data) {
        copy(data)
        notify.success({ text: t('notification.copied_to_clipboard') })
    }

    /**
     * Closes & resets the PAT creation form 
     */
    function cancelPATcreation() {
        createPATModalIsVisible.value = false
        form.reset()
    }

    /**
     * Tells the nb of days until the provided date
     */
    function daysToExpiration(dateString) {
        const date = new Date(dateString)
        const now = Date.now()
        const deltaMs = date.getTime() - now

        return Math.ceil(deltaMs / (1000 * 60 * 60 * 24))
    }

    onBeforeRouteLeave((to) => {
        if (! to.name.startsWith('settings.')) {
            notify.clear()
        }
    })

</script>

<template>
    <StackLayout v-if="createPATModalIsVisible">
        <template #content>
            <FormWrapper title="heading.new_token">
                <form @submit.prevent="generatePAToken" @keydown="form.onKeydown($event)" class="md-card sm:p-8">
                    <FormField v-model="form.name" fieldName="name" :errorMessage="form.errors.get('name')" inputType="text" label="field.name" autofocus />
                    <div class="mt-8 flex flex-wrap items-center gap-3">
                        <VueButton nativeType="submit" :id="'btnGenerateToken'" :isLoading="form.isBusy" size="lg">
                            {{ $t('label.generate') }}
                        </VueButton>
                        <VueButton @click="cancelPATcreation" nativeType="button" id="btnCancel" color="text" size="lg">
                            {{ $t('label.cancel') }}
                        </VueButton>
                    </div>
                </form>
            </FormWrapper>
        </template>
    </StackLayout>
    <StackLayout v-else>
        <template #header>
            <TabBar :tabs="tabs" :active-tab="'settings.oauth.tokens'" @tab-selected="(to) => router.push({ name: to })" />
        </template>
        <template #content>
            <FormWrapper>
                <p v-if="isDisabled && user.oauth_provider" class="md-callout md-callout-warning mb-6">
                    <LucideTriangleAlert />
                    <span>{{ $t('message.sso_only_x_settings_are_disabled', { auth_method: 'OAuth' }) }}</span>
                </p>
                <p v-if="isDisabled && user.authenticated_by_proxy" class="md-callout md-callout-warning mb-6">
                    <LucideTriangleAlert />
                    <span>{{ $t('message.auth_handled_by_proxy') + ' ' + $t('message.manage_auth_at_proxy_level') }}</span>
                </p>
                <div class="flex flex-wrap items-end justify-between gap-4">
                    <div>
                        <h1 class="md-page-title">{{ $t('heading.personal_access_tokens') }}</h1>
                        <p class="mt-2 max-w-prose text-body text-md-on-surface-variant">
                            {{ $t('message.token_legend')}}
                        </p>
                    </div>
                    <button type="button" class="md-btn md-btn-tonal" @click="showPATcreationForm">
                        <LucideCirclePlus /> {{ $t('link.generate_new_token')}}
                    </button>
                </div>
                <div v-if="tokens.length > 0" class="mt-8 pb-8">
                    <ul class="flex flex-col gap-2">
                        <li v-for="token in tokens" :key="token.id" class="group-item md-card px-5 py-4" :class="{ 'ring-1 ring-md-success': token.value }">
                            <div class="flex flex-wrap items-center gap-3">
                                <span class="inline-flex size-10 shrink-0 items-center justify-center rounded-md" :class="token.value ? 'bg-md-success-container text-md-on-success-container' : 'bg-md-secondary-container text-md-on-secondary-container'">
                                    <LucideCheck v-if="token.value" />
                                    <LucideKeyRound v-else />
                                </span>
                                <div class="min-w-0 flex-1">
                                    <p class="truncate text-title text-md-on-surface">{{ token.name }}</p>
                                    <!-- expiration warning -->
                                    <p v-if="daysToExpiration(token.expires_at) < 0" class="text-label text-md-error">
                                        {{ $t('message.expired_since_x', { expired_at : new Date(token.expires_at).toLocaleDateString() }) }}
                                    </p>
                                    <p v-else class="text-label" :class="daysToExpiration(token.expires_at) <= 7 ? 'text-md-warning' : 'font-normal text-md-on-surface-variant'">
                                        {{ $t('message.expire_in_x_day', { days_to_expiration : daysToExpiration(token.expires_at) }) }}
                                    </p>
                                </div>
                                <!-- revoke link -->
                                <div class="flex shrink-0 items-center gap-1">
                                    <button type="button" v-if="token.value" class="md-btn md-btn-filled md-btn-xs" @click.stop="copyToClipboard(token.value)">
                                        <LucideCopy />
                                        {{ $t('label.copy') }}
                                    </button>
                                    <button type="button" class="md-btn md-btn-danger-text md-btn-xs" @click="revokeToken(token.id)" :title="$t('tooltip.revoke')">
                                        {{ $t('label.revoke') }}
                                    </button>
                                </div>
                            </div>
                            <template v-if="token.value">
                                <!-- warning msg -->
                                <p class="mt-4 text-label font-normal text-md-on-surface-variant">
                                    {{ $t('message.make_sure_copy_token') }}
                                </p>
                                <!-- token value -->
                                <p class="pat mt-2 break-all rounded-md bg-md-surface-container-highest px-4 py-3 font-mono text-label-sm text-md-on-surface">
                                    {{ token.value }}
                                </p>
                            </template>
                        </li>
                    </ul>
                    <p class="mt-4 flex items-center justify-end gap-1.5 text-label-sm text-md-on-surface-variant">
                        <LucideInfo class="size-4!" />
                        {{ $t('message.revoking_a_token_is_permanent')}}
                    </p>
                </div>
                <Spinner :isVisible="isFetching && tokens.length === 0" type="list-loading" />
            </FormWrapper>
        </template>
        <template #footer>
            <VueFooter>
                <template #default>
                    <NavigationButton action="close" @closed="router.push({ name: returnTo })" :current-page-title="$t('title.settings.oauth.tokens')" />
                </template>
            </VueFooter>
        </template>
    </StackLayout>
</template>
