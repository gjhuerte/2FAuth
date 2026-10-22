<script setup>
    import { inject, computed } from 'vue'
    import { LucideChevronUp, LucideLogOut, LucideSettings, LucideShieldUser } from '@lucide/vue'

    const showMenu = defineModel('showMenu')
    showMenu.value = false

    // This is a lot of injects just for a footer
    // TODO : Try to reduce dependencies
    const appSettings = inject('appSettingsStore', {
        latestRelease: null,
        checkForUpdate: true,
    })
    const user = inject('userStore', {
        isAdmin: false,
        isAuthenticated: false,
        email: null,
        preferences: {
            showEmailInFooter: true,
        },
        logout: function () { }
    })
    const $2fauth = inject('2fauth', {
        context: 'webapp',
        version: 'x.y.z',
        config: {
            proxyAuth: false,
            proxyLogoutUrl: null,
        }
    })

    const showReleaseFlag = computed(() => appSettings.latestRelease && appSettings.checkForUpdate)
    const showLogout = computed(() => !$2fauth.config.proxyAuth || ($2fauth.config.proxyAuth && $2fauth.config.proxyLogoutUrl))

    /**
     *
     */
    function logout(message) {
        if(confirm(message)) {
            user.logout()
        }
    }
</script>

<template>
    <template v-if="$2fauth.context == 'webext'" >
        <!-- action buttons -->
        <div v-if="$slots.default" class="mb-3 flex flex-wrap items-center justify-center gap-3">
            <slot name="default" />
        </div>
        <!-- sub-links -->
        <div class="text-center text-label">
            <slot name="subpart" />
        </div>
    </template>
    <template v-else-if="$2fauth.context == 'webapp'">
        <div class="relative mx-auto flex w-full max-w-xl flex-col items-center gap-2">
            <!-- action buttons -->
            <div
                v-if="$slots.default"
                class="flex max-w-full flex-wrap items-center justify-center gap-2 rounded-xl border border-md-outline-variant bg-md-surface-container-high p-2 shadow-md"
                :inert="showMenu"
            >
                <slot name="default" />
            </div>
            <!-- sub menu -->
            <Transition name="md-sheet">
                <div
                    v-if="showMenu"
                    class="submenu md-menu absolute bottom-full mb-3"
                    role="menu"
                >
                    <slot name="submenu">
                        <ul class="flex flex-col">
                            <!-- settings link -->
                            <li role="none">
                                <router-link id="lnkSettings" :to="{ name: 'settings.options' }" class="md-menu-item" role="menuitem">
                                    <LucideSettings />
                                    {{ $t('link.settings') }}
                                </router-link>
                            </li>
                            <!-- admin link -->
                            <li v-if="user.isAdmin" role="none">
                                <router-link id="lnkAdmin" :to="{ name: 'admin.appSetup' }" class="md-menu-item" role="menuitem">
                                    <LucideShieldUser />
                                    {{ $t('link.admin_panel') }}
                                    <span v-if="showReleaseFlag" class="release-flag ml-auto size-2 rounded-full bg-md-tertiary"></span>
                                </router-link>
                            </li>
                            <!-- sign-out button -->
                            <li v-if="showLogout" role="none" class="mt-1 border-t border-md-outline-variant pt-1">
                                <button type="button" id="lnkSignOut" class="md-menu-item" role="menuitem" @click="logout($t('confirmation.logout'))">
                                    <LucideLogOut />
                                    {{ $t('label.sign_out') }}
                                </button>
                            </li>
                        </ul>
                    </slot>
                </div>
            </Transition>
            <!-- sub part -->
            <div class="flex min-h-9 w-full items-center justify-center text-center text-label">
                <slot name="subpart">
                    <div v-if="$route.meta.showAbout === true">
                        <!-- about link -->
                        <router-link v-if="$route.name != 'about'" id="lnkAbout" :to="{ name: 'about' }" class="md-muted-link">
                            <span v-if="user.isAuthenticated && $route.meta.watchedByKicker" class="font-medium">2FAuth · v{{ $2fauth.version }}</span>
                            <span v-else>{{ $t('link.about') }}</span>
                        </router-link>
                        <span v-else>&nbsp;</span>
                    </div>
                    <!-- legacy links -->
                    <div v-else-if="user.preferences.showEmailInFooter == false" class="flex flex-wrap items-center justify-center gap-1 text-md-on-surface-variant">
                        <router-link id="lnkSettings" :to="{ name: 'settings.options' }" class="md-btn md-btn-neutral md-btn-xs">
                            {{ $t('link.settings') }}
                        </router-link>
                        <router-link v-if="user.isAdmin" id="lnkAdmin" :to="{ name: 'admin.appSetup' }" class="md-btn md-btn-neutral md-btn-xs">
                            {{ $t('link.admin_panel') }}<span v-if="showReleaseFlag" class="release-flag size-2 rounded-full bg-md-tertiary"></span>
                        </router-link>
                        <button v-if="showLogout" type="button" id="lnkSignOut" class="md-btn md-btn-neutral md-btn-xs" @click="logout($t('confirmation.logout'))">
                            {{ $t('label.sign_out') }}
                        </button>
                    </div>
                    <!-- email + menu links -->
                    <button
                        v-else
                        type="button"
                        id="btnEmailMenu"
                        @click="showMenu = !showMenu"
                        class="md-btn md-btn-neutral md-btn-sm max-w-full"
                        :aria-expanded="showMenu"
                        aria-haspopup="menu"
                    >
                        <span v-if="showReleaseFlag" class="release-flag size-2 shrink-0 rounded-full bg-md-tertiary" aria-hidden="true"></span>
                        <span class="truncate">{{ user.email }}</span>
                        <LucideChevronUp class="transition-transform duration-300 ease-md" :class="{ 'rotate-180': !showMenu }" />
                    </button>
                </slot>
            </div>
        </div>
    </template>
</template>
