<script setup>
    import CopyButton from '@/components/CopyButton.vue'
    import AccessLogViewer from '@/components/AccessLogViewer.vue'
    import userService from '@/services/userService'
    import { useNotify } from '@2fauth/ui'
    import { useUserStore } from '@/stores/user'
    import { useBusStore } from '@/stores/bus'
    import { useI18n } from 'vue-i18n'
    import { useErrorHandler } from '@2fauth/stores'
    import { LucideLink, LucideTrash2, LucideTriangleAlert } from '@lucide/vue'
    import { useSettingsBreakpoints } from '@/composables/breakpoints'

    const errorHandler = useErrorHandler()
    const { t } = useI18n()
    const notify = useNotify()
    const router = useRouter()
    const user = useUserStore()
    const bus = useBusStore()
    const $2fauth = inject('2fauth')
    const { isLaptop } = useSettingsBreakpoints()

    const isFetching = ref(false)
    const managedUser = ref(null)
    const listUserPreferences = ref(null)
    const showFullLogLink = ref(false)

    const props = defineProps({
        userId: [Number, String]
    })

    onMounted(async () => {
        await getUser()
    })

    /**
     * Gets the user from backend
     */
    async function getUser() {
        isFetching.value = true

        userService.getById(props.userId, {returnError: true})
        .then(response => {
            managedUser.value = response.data
            bus.username = managedUser.value.info.name
        })
        .catch(error => {
            errorHandler.show(error)
        })
        .finally(() => {
            isFetching.value = false
        })
    }

    /**
     * Resends a pwd reset email to the user
     */
    async function resendPasswordEmail() {
        if (! confirmForYourself()) {
            return false
        }
        
        if (confirm(t('confirmation.purge_password_reset_request')) === true) {
            await userService.resendPasswordEmail(managedUser.value.info.id)
            managedUser.value.password_reset = null
        }
    }

    /**
     * Resets the user password
     */
    async function resetPassword() {
        if (! confirmForYourself()) {
            return false
        }

        if (confirm(t('confirmation.request_password_reset')) === true) {
            userService.resetPassword(managedUser.value.info.id, { returnError: true })
            .then(response => {
                managedUser.value = response.data
                notify.success({ text: t('notification.password_successfully_reset') })
            })
            .catch(error => {
                if(error.response.status === 400) {
                    notify.alert({ text: error.response.data.reason })
                }
                else {
                    errorHandler.show(error)
                }
            })
        }
    }

    /**
     * Set admin role
     * 
     * @param {string} preference 
     * @param {boolean} isAdmin 
     */
    function saveAdminRole(isAdmin) {
        if (! confirm(t('confirmation.change_admin_role'))) {
            nextTick().then(() => {
                    managedUser.value.info.is_admin = ! isAdmin
                })
            return
        }

        if(isAdmin === false && managedUser.value.info.id === user.id) {
            if (! confirm(t('confirmation.demote_own_account'))) {
                nextTick().then(() => {
                    managedUser.value.info.is_admin = true
                })
                return
            }
        }

        userService.promote(managedUser.value.info.id, { 'is_admin': isAdmin }, { returnError: true }).then(response => {
            managedUser.value.info.is_admin = response.data.info.is_admin
            notify.success({ text: t('notification.user_role_updated') })
        })
        .catch(error => {
            if( error.response.status === 403 ) {
                notify.alert({ text: error.response.data.message })
                managedUser.value.info.is_admin = true
            }
            else {
                errorHandler.show(error)
            }
        })
    }

    /**
     * submit user account deletion
     */
    function deleteUser() {
        if (! confirmForYourself()) {
            return false
        }

        if(confirm(t('confirmation.delete_user'))) {
            userService.delete(managedUser.value.info.id, { returnError: true }).then(response => {
                notify.success({ text: t('notification.user_account_successfully_deleted') })
                router.push({ name: 'admin.users' });
            })
            .catch(error => {
                if( error.response.status === 403 ) {
                    notify.alert({ text: error.response.data.message })
                }
                else {
                    errorHandler.show(error)
                }
            })
        }
    }

    /**
     * submit user account deletion
     */
    function revokePATs() {
        if (! confirmForYourself()) {
            return false
        }

        userService.revokePATs(managedUser.value.info.id).then(response => {
            managedUser.value.valid_personal_access_tokens = 0
            notify.success({ text: t('notification.pats_succesfully_revoked') })
        })
    }

    /**
     * submit user account deletion
     */
    function revokeWebauthnCredentials() {
        if (! confirmForYourself()) {
            return false
        }

        userService.revokeWebauthnCredentials(managedUser.value.info.id).then(response => {
            managedUser.value.valid_personal_access_tokens = 0
            notify.success({ text: t('notification.security_devices_succesfully_revoked') })
        })
    }

    /**
     * Confirmation for modification on own account
     */
    function confirmForYourself() {
        if(managedUser.value.info.id === user.id) {
            if (! confirm(t('confirmation.edit_own_account'))) {
                return false
            }
        }
        return true
    }

    const userRef = useTemplateRef('heading-user')
    const accessRef = useTemplateRef('heading-access')
    const lastAccessesRef = useTemplateRef('heading-lastAccesses')
    const preferencesRef = useTemplateRef('heading-preferences')
    const dangerZoneRef = useTemplateRef('heading-dangerZone')

    const scrollTo = (elRef) => {
        if (!elRef) return

        elRef.scrollIntoView({ behavior: 'smooth' })
    }
    
</script>


<template>
    <StackLayout>
        <template #content>
            <ResponsiveWidthWrapper>
                <h1 ref="heading-user" class="md-page-title mb-6 scroll-mt-6">
                    {{ $t('heading.user_management') }}
                </h1>
                <div v-if="isLaptop && user.preferences.showQuickNavMenus" class="settings-menu fixed top-32 -ml-60 w-52">
                    <aside class="menu">
                        <ul class="menu-list flex flex-col gap-0.5">
                            <li><button type="button" class="md-menu-item h-10 rounded-full" @click="scrollTo(userRef)">{{ $t('heading.user') }}</button></li>
                            <li v-if="!$2fauth.config.proxyAuth">
                                <button type="button" class="md-menu-item h-10 truncate rounded-full" @click="scrollTo(accessRef)">{{ $t('heading.access') }}</button>
                                <ul class="ml-4 flex flex-col gap-0.5 border-l border-md-outline-variant pl-2">
                                    <li><button type="button" class="md-menu-item h-9 rounded-full text-md-on-surface-variant" @click="scrollTo(lastAccessesRef)">{{ $t('heading.last_accesses') }}</button></li>
                                </ul>
                            </li>
                            <li><button type="button" class="md-menu-item h-10 rounded-full" @click="scrollTo(preferencesRef)">{{ $t('heading.preferences') }}</button></li>
                            <li><button type="button" class="md-menu-item h-10 rounded-full md-menu-item-danger" @click="scrollTo(dangerZoneRef)">{{ $t('heading.danger_zone') }}</button></li>
                        </ul>
                    </aside>
                </div>
                <!-- user info -->
                <div v-if="! isFetching && managedUser" class="animate-enter pb-8">
                    <section class="relative mb-4 overflow-hidden rounded-xl bg-md-surface-container p-6 shadow-md sm:p-8">
                        <div class="relative flex items-center gap-4">
                            <span class="md-shape-burst inline-flex size-16 shrink-0 items-center justify-center font-display text-title-lg font-semibold" :class="'md-tone-' + (managedUser.info.id % 5)">
                                {{ managedUser.info.name.charAt(0).toUpperCase() }}
                            </span>
                            <div class="min-w-0 flex-1">
                                <p class="flex items-center gap-2 font-display text-title-lg font-semibold text-md-on-surface">
                                    <span class="truncate">{{ managedUser.info.name }}</span>
                                    <span class="md-badge md-badge-outline shrink-0 font-mono">#{{ managedUser.info.id }}</span>
                                </p>
                                <p class="truncate text-body text-md-on-surface-variant">{{ managedUser.info.email }}</p>
                            </div>
                        </div>
                        <p class="relative mt-4 text-label font-normal text-md-on-surface-variant">
                            {{ $t('message.registered_on_date', { date: managedUser.info.created_at }) }} · {{ $t('message.last_seen_on_date', { date: managedUser.info.last_seen_at }) }}
                        </p>
                        <!-- oauth banner -->
                        <p v-if="managedUser.info.oauth_provider" class="md-callout md-callout-info relative mt-4">
                            <LucideLink />
                            {{ $t('message.account_bound_to_x_via_oauth', { provider: managedUser.info.oauth_provider }) }}
                        </p>
                        <!-- isAdmin option -->
                        <div class="relative mt-6">
                            <FormCheckbox v-model="managedUser.info.is_admin" @update:model-value="val => saveAdminRole(val === true)" :isDanger="true" fieldName="is_admin" label="field.is_admin" help="field.is_admin.help" />
                        </div>
                    </section>
                    <!-- access -->
                    <section v-if="!$2fauth.config.proxyAuth" class="md-card mb-4 sm:p-8">
                        <h2 ref="heading-access" class="md-section-title mb-6 scroll-mt-6">{{ $t('heading.access') }}</h2>
                        <div class="md-list">
                            <!-- reset password -->
                            <div class="md-list-item flex-wrap items-start bg-md-surface-container-high">
                                <div class="min-w-0 flex-1">
                                    <p class="text-body font-medium text-md-on-surface">{{ $t('heading.password') }}</p>
                                    <div class="mt-1 flex flex-col gap-1 text-label font-normal text-md-on-surface-variant">
                                        <span v-if="managedUser.password_reset === 0">{{ $t('message.password_request_expired') }}</span>
                                        <span v-else-if="managedUser.password_reset">{{ $t('message.password_requested_on_t', { datetime: managedUser.password_reset }) }}</span>
                                        <span v-if="managedUser.password_reset">{{ $t('message.resend_email_help') }}</span>
                                        <span>{{ $t('message.reset_password_help') }}</span>
                                    </div>
                                </div>
                                <div class="flex flex-wrap gap-1.5">
                                    <!-- resend email button -->
                                    <button type="button" v-if="managedUser.password_reset" class="md-btn md-btn-tonal md-btn-xs" @click="resendPasswordEmail" :title="$t('tooltip.resend_email_title')">
                                        {{ $t('label.resend_email') }}
                                    </button>
                                    <!-- reset password button -->
                                    <button type="button" class="md-btn md-btn-tonal md-btn-xs" @click="resetPassword" :title="$t('tooltip.reset_password_title')">
                                        {{ $t('label.reset_password') }}
                                    </button>
                                </div>
                            </div>
                            <!-- personal access tokens -->
                            <div class="md-list-item bg-md-surface-container-high">
                                <div class="min-w-0 flex-1">
                                    <p class="text-body font-medium text-md-on-surface">{{ $t('heading.personal_access_tokens') }}</p>
                                    <p class="text-label font-normal text-md-on-surface-variant">
                                        {{ $t('message.user_has_x_active_pat', { count: managedUser.valid_personal_access_tokens }) }}
                                    </p>
                                </div>
                                <button v-if="managedUser.valid_personal_access_tokens > 0" type="button" class="md-btn md-btn-danger-text md-btn-xs" @click="revokePATs" :title="$t('tooltip.revoke_all_pat_for_user')">
                                    {{ $t('label.revoke') }}
                                </button>
                            </div>
                            <!-- webauthn devices -->
                            <div class="md-list-item bg-md-surface-container-high">
                                <div class="min-w-0 flex-1">
                                    <p class="text-body font-medium text-md-on-surface">{{ $t('heading.security_devices') }}</p>
                                    <p class="text-label font-normal text-md-on-surface-variant">
                                        {{ $t('message.user_has_x_security_devices', { count: managedUser.webauthn_credentials }) }}
                                    </p>
                                </div>
                                <button v-if="managedUser.webauthn_credentials > 0" type="button" class="md-btn md-btn-danger-text md-btn-xs" :title="$t('tooltip.revoke_all_devices_for_user')">
                                    {{ $t('label.revoke') }}
                                </button>
                            </div>
                        </div>
                        <!-- last access -->
                        <h3 ref="heading-lastAccesses" class="mb-4 mt-8 scroll-mt-6 text-title text-md-primary">{{ $t('heading.last_accesses') }}</h3>
                        <AccessLogViewer v-if="managedUser" :userId="props.userId" :lastOnly="true" @has-more-entries="showFullLogLink = true"/>
                        <p v-if="showFullLogLink" class="mt-4 text-label font-normal text-md-on-surface-variant">
                            {{ $t('message.log_has_more_entries') }} <router-link id="lnkFullLogs" class="md-link" :to="{ name: 'admin.logs.access', params: { userId: props.userId }}" >
                                {{ $t('link.see_full_log') }}.
                            </router-link>
                        </p>
                    </section>
                    <!-- preferences -->
                    <section class="md-card mb-4 sm:p-8">
                        <h2 ref="heading-preferences" class="md-section-title mb-6 scroll-mt-6">{{ $t('heading.preferences') }}</h2>
                        <div class="about-debug relative rounded-md bg-md-surface-container-highest p-5 font-mono text-label-sm inset-shadow-sm">
                            <CopyButton id="btnCopyEnvVars" :token="listUserPreferences?.innerText" />
                            <ul ref="listUserPreferences" id="listUserPreferences" class="flex flex-col gap-1">
                                <li v-for="(value, preference) in managedUser.info.preferences" :value="value" :key="preference" class="break-all">
                                    <b class="font-medium text-md-on-surface">{{preference}}</b>: <span class="text-md-on-surface-variant">{{value}}</span>
                                </li>
                            </ul>
                        </div>
                    </section>
                    <!-- danger zone -->
                    <section class="md-card mb-4 sm:p-8 bg-md-error-soft ring-1 ring-md-error-container">
                        <h2 ref="heading-dangerZone" class="md-section-title mb-4 flex scroll-mt-6 items-center gap-2 text-md-error!">
                            <LucideTriangleAlert class="size-6!" />
                            {{ $t('heading.danger_zone') }}
                        </h2>
                        <p class="text-body leading-relaxed text-md-on-surface-variant">
                            {{  $t('message.delete_this_user_legend') }}
                        </p>
                        <p class="mt-2 text-body font-medium text-md-on-surface">
                            {{  $t('message.this_is_not_soft_delete') }}
                        </p>
                        <button type="button" class="md-btn md-btn-danger mt-6" @click="deleteUser" title="delete">
                            <LucideTrash2 />
                            {{  $t('label.delete_this_user') }}
                        </button>
                    </section>
                </div>
            </ResponsiveWidthWrapper>
            <!-- loader -->
            <Spinner v-if="isFetching || ! managedUser" :isVisible="true" type="fullscreen-overlay" message="message.fetching_data" />
        </template>
        <template #footer>
            <VueFooter>
                <template #default>
                    <NavigationButton action="back" @goback="router.push({ name: 'admin.users' })" :previous-page-title="$t('title.admin.users')" />
                    <NavigationButton action="close" :isText="true" @closed="router.push({ name: 'accounts' })" :current-page-title="$t('title.admin.manageUser')" />
                </template>
            </VueFooter>
        </template>
    </StackLayout>
</template>
