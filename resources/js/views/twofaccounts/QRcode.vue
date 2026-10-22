<script setup>
    import twofaccountService from '@/services/twofaccountService'

    const router = useRouter()
    const route = useRoute()
    const qrcode = ref()

    onBeforeMount(() => {
        getQRcode()
    })

    /**
     * Get a QR code image resource from backend
     */
    async function getQRcode () {
        const { data } = await twofaccountService.getQrcode(route.params.twofaccountId)
        qrcode.value = data.qrcode
    }
</script>

<template>
    <div class="modal modal-otp is-active fixed inset-0 z-[2000] flex flex-col" role="dialog" aria-modal="true">
        <div class="modal-background absolute inset-0 bg-md-surface"></div>
        <section class="modal-slot relative flex flex-1 items-center justify-center overflow-y-auto px-4 pt-[max(1rem,env(safe-area-inset-top))]">
            <div class="relative rounded-2xl bg-md-surface-container p-6 shadow-xl animate-enter sm:p-8">
                <div class="relative flex min-h-64 min-w-64 items-center justify-center overflow-hidden rounded-lg bg-white p-4 inset-shadow-sm">
                    <img v-if="qrcode" :src="qrcode" class="qrcode w-full max-w-80 max-h-[50vh] object-contain" :alt="$t('alttext.image_of_qrcode_to_scan')">
                    <Spinner :isVisible="!qrcode" :type="'raw'" :rawSize="32" />
                </div>
            </div>
        </section>
        <VueFooter>
            <template #default>
                <NavigationButton action="close" @closed="router.push({ name: 'accounts' })" :current-page-title="$t('title.showQRcode')" />
            </template>
            <template #subpart>
                <!-- we add a subpart to hide the default slot value -->
                <router-link v-if="$route.name != 'accounts'" id="lnkBackToHome" :to="{ name: 'accounts' }" class="md-muted-link">{{ $t('link.back_to_home') }}</router-link>
                <span v-else>&nbsp;</span>
            </template>
        </VueFooter>
    </div>
</template>
