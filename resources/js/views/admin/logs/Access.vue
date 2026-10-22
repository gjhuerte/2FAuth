<script setup>
    import AccessLogViewer from '@/components/AccessLogViewer.vue'
    import userService from '@/services/userService'
    import { useNotify } from '@2fauth/ui'
    import { useBusStore } from '@/stores/bus'

    const bus = useBusStore()
    const router = useRouter()

    onMounted(async () => {
        getUser()
    })

    const props = defineProps({
        userId: [Number, String]
    })

    const username = ref(bus.username ?? '')

    /**
     * Gets the user from backend
     */
    function getUser() {
        userService.getById(props.userId, {returnError: true})
        .then(response => {
            username.value = response.data.info.name
        })
    }
    
</script>

<template>
    <StackLayout>
        <template #content>
            <ResponsiveWidthWrapper>
                <h1 class="md-page-title">
                    {{ $t('heading.access_log') }}
                </h1>
                <p class="mb-6 mt-2 text-body text-md-on-surface-variant">
                    {{ $t('message.access_log_legend_for_user', { username: username }) }} <span class="md-badge md-badge-outline font-mono">#{{ props.userId }}</span>
                </p>
                <div class="animate-enter pb-8">
                    <AccessLogViewer :userId="props.userId" :lastOnly="false" :showSearch="true" :period="1" />
                </div>
            </ResponsiveWidthWrapper>
        </template>
        <template #footer>
            <VueFooter>
                <template #default>
                    <NavigationButton action="back" @goback="router.push({ name: 'admin.manageUser', params: { userId: props.userId }})" :previous-page-title="$t('title.admin.manageUser')" />
                    <NavigationButton action="close" :isText="true" @closed="router.push({ name: 'accounts' })" :current-page-title="$t('title.admin.logs.access')" />
                </template>
            </VueFooter>
        </template>
    </StackLayout>
</template>
