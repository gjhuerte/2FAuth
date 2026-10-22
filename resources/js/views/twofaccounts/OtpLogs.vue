<script setup>
    import LogViewer from '@/components/LogViewer.vue'
    import TwofaccountMedia from '@/components/TwofaccountMedia.vue'
    import { useTwofaccounts } from '@/stores/twofaccounts'

    const router = useRouter()

    const props = defineProps({
        twofaccountId: [Number, String]
    })

    const twofaccounts = useTwofaccounts()
    const twofaccount = twofaccounts.getById(props.twofaccountId)

</script>

<template>
    <StackLayout>
        <template #content>
            <ResponsiveWidthWrapper>
                <h1 class="md-page-title">
                    {{ $t('heading.otp_generation_log') }}
                </h1>
                <div class="mt-6 animate-enter pb-8">
                    <TwofaccountMedia :twofaccount="twofaccount" />
                    <LogViewer :twofaccountId="props.twofaccountId" :logType="'otp'" :sortingKey="'generated_at'" :lastOnly="false" :showSearch="true" :period="1" />
                </div>
            </ResponsiveWidthWrapper>
        </template>
        <template #footer>
            <VueFooter>
                <template #default>
                    <NavigationButton action="close" @closed="router.push({ name: 'accounts' })" :current-page-title="$t('title.otpLogs')" />
                </template>
            </VueFooter>
        </template>
    </StackLayout>
</template>
