<script setup>
    /**
     * Hero container shared by every sign-in / sign-up / recovery screen.
     */
    const $2fauth = inject('2fauth')

    const props = defineProps({
        title: {
            type: String,
            default: ''
        },
        punchline: {
            type: String,
            default: ''
        },
    })
</script>

<template>
    <div class="mx-auto w-full max-w-md px-0 pb-6 pt-6 sm:max-w-lg sm:pt-14">
        <section class="relative overflow-hidden rounded-xl rounded-tr-md bg-md-surface-container px-6 py-8 shadow-lg animate-enter sm:rounded-3xl sm:rounded-tr-lg sm:px-10 sm:py-12">
            <div class="relative">
                <div class="mb-6 flex items-center gap-3">
                    <span class="inline-flex size-12 -rotate-6 items-center justify-center rounded-md bg-md-primary shadow-[0_3px_0_0_var(--md-primary-press)] transition-transform duration-300 ease-spring hover:rotate-6 hover:scale-110 dark:bg-md-primary-container dark:shadow-[0_3px_0_0_var(--md-shadow)]">
                        <img :src="$2fauth.config.subdirectory + '/logo.svg'" alt="" class="h-7 w-auto" />
                    </span>
                    <span class="md-overline">2FAuth</span>
                </div>
                <h1 v-if="title" class="md-page-title">{{ $t(title) }}</h1>
                <p v-if="punchline" id="punchline" class="mt-2 text-body leading-relaxed text-md-on-surface-variant">{{ $t(punchline) }}</p>
                <div class="mt-8">
                    <slot />
                </div>
            </div>
        </section>
        <div v-if="$slots.links" class="nav-links mt-6 flex flex-col items-center gap-2 px-4 text-center text-label font-normal text-md-on-surface-variant">
            <slot name="links" />
        </div>
    </div>
</template>
