<script setup>
    import { useUserStore } from '@/stores/user'
    import { LucideCodeXml, LucideFlaskConical, LucideFolderGit2, LucideGraduationCap } from '@lucide/vue'
    import { useI18n } from 'vue-i18n'

    const $2fauth = inject('2fauth')
    const { t } = useI18n()

    const resources = computed(() => [
        { href: 'https://github.com/Bubka/2FAuth', icon: LucideFolderGit2, label: 'Github' },
        { href: 'https://docs.2fauth.app/', icon: LucideGraduationCap, label: t('label.docs') },
        { href: 'https://demo.2fauth.app/', icon: LucideFlaskConical, label: t('label.demo') },
        { href: 'https://docs.2fauth.app/resources/rapidoc.html', icon: LucideCodeXml, label: t('label.api') },
    ])
    const user = useUserStore()
    const router = useRouter()
    
    const returnTo = router.options.routes.find((route) => route.path == router.options.history.state.back).name;

</script>

<template>
    <StackLayout>
        <template #content>
            <ResponsiveWidthWrapper>
                <div class="animate-enter pb-8">
                    <!-- hero -->
                    <section class="relative overflow-hidden rounded-2xl bg-md-surface-container p-8 shadow-lg sm:rounded-3xl sm:p-12">
                        <div aria-hidden="true" class="pointer-events-none absolute -right-20 -top-28 size-72 rounded-full bg-md-primary/25 blur-3xl"></div>
                        <div class="relative flex flex-col gap-6 sm:flex-row sm:items-center">
                            <span class="inline-flex size-20 shrink-0 items-center justify-center rounded-xl bg-md-primary shadow-md dark:bg-md-primary-container">
                                <img class="about-logo h-11 w-auto" :src="$2fauth.config.subdirectory + '/logo.svg'" alt="2FAuth logo" />
                            </span>
                            <div>
                                <p class="md-overline">{{ $t('heading.about') }}</p>
                                <h1 class="mt-1 text-headline text-md-on-surface">
                                    2FAuth
                                    <span v-if="user.isAuthenticated" class="md-badge ml-1 align-middle">v{{ $2fauth.version }}</span>
                                </h1>
                                <p class="mt-2 text-body leading-relaxed text-md-on-surface-variant">{{ $t('message.2fauth_teaser')}}</p>
                                <p class="mt-3 text-label font-normal text-md-on-surface-variant">
                                    ©Bubka · <a class="md-link" href="https://github.com/Bubka/2FAuth/blob/master/LICENSE" target="_blank" rel="noopener">AGPL-3.0 license</a>
                                </p>
                            </div>
                        </div>
                    </section>
                    <!-- resources -->
                    <h2 class="md-section-title mb-4 mt-10">{{ $t('heading.resources') }}</h2>
                    <div class="grid grid-cols-2 gap-3 sm:grid-cols-4">
                        <a v-for="res in resources" :key="res.href" :href="res.href" target="_blank" rel="noopener" class="md-card md-card-interactive group flex flex-col gap-3 p-5 no-underline hover:scale-[1.02]">
                            <span class="inline-flex size-11 items-center justify-center rounded-md bg-md-secondary-container text-md-on-secondary-container transition-transform duration-300 ease-md group-hover:scale-110">
                                <component :is="res.icon" />
                            </span>
                            <span class="text-title text-md-on-surface">{{ res.label }}</span>
                        </a>
                    </div>
                    <!-- credits -->
                    <h2 class="md-section-title mb-4 mt-10">{{ $t('heading.credits') }}</h2>
                    <ul class="md-list">
                        <li class="md-list-item text-body text-md-on-surface-variant">
                            <span>{{ $t('message.made_with') }} <a class="md-link" href="https://docs.2fauth.app/credits/" target="_blank" rel="noopener">Laravel, Tailwind CSS, Vue.js and more</a></span>
                        </li>
                        <li class="md-list-item text-body text-md-on-surface-variant">
                            <span>{{ $t('message.ui_icons_by') }} <a class="md-link" href="https://lucide.dev/" target="_blank" rel="noopener">Lucide</a> <a class="md-muted-link text-label-sm" href="https://lucide.dev/license" target="_blank" rel="noopener">(ISC License)</a></span>
                        </li>
                        <li class="md-list-item text-body text-md-on-surface-variant">
                            <span>{{ $t('message.logos_by') }} <a class="md-link" href="https://2fa.directory/" target="_blank" rel="noopener">2FA Directory</a> <a class="md-muted-link text-label-sm" href="https://github.com/2factorauth/twofactorauth/blob/master/LICENSE.md" target="_blank" rel="noopener">(MIT License)</a></span>
                        </li>
                    </ul>
                </div>
            </ResponsiveWidthWrapper>
        </template>
        <template #footer>
            <VueFooter>
                <template #default>
                    <NavigationButton action="back" @goback="router.push({ name: returnTo })" :previous-page-title="$t('title.' + returnTo)" />
                </template>
            </VueFooter>
        </template>
    </StackLayout>
</template>
