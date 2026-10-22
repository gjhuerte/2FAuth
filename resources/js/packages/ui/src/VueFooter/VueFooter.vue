<script setup>

    import { ref, inject } from 'vue'

    import VueFooterContent from '../VueFooterContent/VueFooterContent.vue'

    const $2fauth = inject('2fauth', {
        context: 'webapp',
        version: 'x.y.z',
        config: {
            proxyAuth: false,
            proxyLogoutUrl: null,
        }
    })

    const showMenu = ref(false)
</script>

<template>
    <div @click="showMenu = false" v-if="showMenu == true" class="footer-overlay fixed inset-0 z-20"></div>
    <footer v-if="$2fauth.context == 'webext'" class="main relative z-30 px-4 pb-5 pt-3">
        <VueFooterContent>
            <template v-if="$slots.default" #default>
                <slot name="default" />
            </template>
            <template v-if="$slots.submenu" #submenu>
                <slot name="submenu" />
            </template>
            <template v-if="$slots.subpart" #subpart>
                <slot name="subpart" />
            </template>
        </VueFooterContent>
    </footer>
    <footer
        v-else-if="$2fauth.context == 'webapp'"
        class="main relative z-30 px-4 pb-[max(1rem,env(safe-area-inset-bottom))] pt-2"
        :class="{ 'menu' : showMenu }"
    >
        <VueFooterContent v-model:show-menu="showMenu">
            <template v-if="$slots.default" #default>
                <slot name="default" />
            </template>
            <template v-if="$slots.submenu" #submenu>
                <slot name="submenu" />
            </template>
            <template v-if="$slots.subpart" #subpart>
                <slot name="subpart" />
            </template>
        </VueFooterContent>
    </footer>
</template>
