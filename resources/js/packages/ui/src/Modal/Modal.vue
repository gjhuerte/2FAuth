<script setup>
    import { NavigationButton } from '@2fauth/formcontrols'
    import { useNotify } from '../Notify'
    import { VueFooterContent } from '../VueFooterContent'

    const isActive = defineModel('isActive')
    const showFooterMenu = defineModel('showFooterMenu')
    const props = defineProps({
        modelValue: Boolean,
        isFullHeight:  {
            type: Boolean,
            default: false
        }
    })

    function closeModal(event) {
        useNotify().clear()
        isActive.value = false
    }
</script>

<template>
    <Transition name="md-sheet">
        <div
            v-show="isActive"
            class="modal modal-otp fixed inset-0 z-[2000] flex flex-col"
            :class="{ 'is-active': isActive }"
            role="dialog"
            aria-modal="true"
            @keyup.esc="closeModal"
        >
            <div class="modal-background absolute inset-0 bg-md-surface" @click.stop="closeModal"></div>
            <div class="pointer-events-none relative flex flex-1 flex-col overflow-y-auto px-4 pt-[max(1rem,env(safe-area-inset-top))]">
                <section class="modal-slot pointer-events-auto relative m-auto w-full max-w-md overflow-hidden rounded-[32px] bg-md-surface-container px-6 py-10 text-center sm:rounded-[48px] sm:px-10">
                    <div class="relative">
                        <slot name="default" />
                    </div>
                </section>
            </div>
            <div @click="showFooterMenu = false" v-if="showFooterMenu == true" class="footer-overlay fixed inset-0"></div>
            <footer class="main relative pb-[max(1.25rem,env(safe-area-inset-bottom))] pt-3">
                <VueFooterContent v-model:show-menu="showFooterMenu">
                    <template #default>
                        <NavigationButton action="close" :useLinkTag="false" @closed="closeModal" />
                    </template>
                    <template #submenu>
                        <slot name="footer-submenu" />
                    </template>
                    <template #subpart>
                        <slot name="footer-subpart">
                            <router-link v-if="$route.name != 'accounts'" id="lnkBackToHome" :to="{ name: 'accounts' }" class="md-muted-link">{{ $t('link.back_to_home') }}</router-link>
                            <span v-else>&nbsp;</span>
                        </slot>
                    </template>
                </VueFooterContent>
            </footer>
        </div>
    </Transition>
</template>
