<script setup>
    import { LucideFileQuestion, LucideTriangleAlert } from '@lucide/vue'
    import { useErrorHandler } from '@2fauth/stores'

    const errorHandler = useErrorHandler()
    const router = useRouter()
    const route = useRoute()

    const showModal = ref(true)
    const showDebug = computed(() => process.env.NODE_ENV === 'development')

    watch(showModal, (val) => {
        if (val == false) {
            exit()
        }
    })

    onMounted(() => {
        if (route.query.err) {
            errorHandler.message = 'error.' + route.query.err
        }
    })

    /**
     * Exits the error view
     */
    function exit() {
        window.history.length > 1 && route.name !== '404' && route.name !== 'notFound' && !route.query.err
            ? router.go(-1)
            : router.push({ name: 'accounts' })
    }

</script>

<template>
    <Modal v-model:is-active="showModal">
        <div class="error-message flex flex-col items-center gap-3" v-if="$route.name == '404' || $route.name == 'notFound'">
            <span class="error-404 mb-3 inline-flex size-20 items-center justify-center rounded-xl bg-md-secondary-container text-md-on-secondary-container" aria-hidden="true">
                <LucideFileQuestion class="size-10!" :stroke-width="1.5" />
            </span>
            <p class="text-title-lg text-md-on-surface">404</p>
            <p class="text-body text-md-on-surface-variant">{{ $t('error.resource_not_found') }}</p>
        </div>
        <div v-else class="error-message flex flex-col items-center gap-2">
            <span class="error-generic mb-4 inline-flex size-20 items-center justify-center rounded-xl bg-md-error-container text-md-on-error-container" aria-hidden="true">
                <LucideTriangleAlert class="size-10!" :stroke-width="1.5" />
            </span>
            <p class="text-title text-md-on-surface">{{ $t('message.error_occured') }}</p>
            <p v-if="errorHandler.message" class="text-body text-md-on-surface-variant">{{ $t(errorHandler.message) }}</p>
            <template v-if="errorHandler.reasons">
                <p v-for="reason in errorHandler.reasons" :key="reason" class="text-label font-normal text-md-on-surface-variant">
                    {{ reason }}
                </p>
            </template>
            <p v-if="errorHandler.originalMessage" class="text-label font-normal text-md-on-surface-variant">{{ $t(errorHandler.originalMessage) }}</p>
            <pre v-if="showDebug && errorHandler.debug" class="mt-4 max-h-64 w-full overflow-auto rounded-md bg-md-surface-container-highest p-4 text-left font-mono text-label-sm text-md-on-surface-variant">{{ errorHandler.debug }}</pre>
        </div>
    </Modal>
</template>
