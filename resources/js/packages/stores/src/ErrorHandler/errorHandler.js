import { ref } from 'vue'
import { defineStore } from 'pinia'

export const useErrorHandler = defineStore('errorHandler', () => {

    // STATE

    const lastError = ref(null)
    const message = ref(null)
    const reasons = ref(null)
    const originalMessage = ref(null)
    const debug = ref(null)

    // ACTIONS

    function $reset() {
        lastError.value = null
        message.value = null
        reasons.value = null
        originalMessage.value = null
        debug.value = null
    }

    /**
     * 
     */
    function parse(error) {
        $reset
        lastError.value = error

        // Handle axios response error
        if (error.response) {
            if (error.response.data) {
                message.value = error.response.data.message ?? null,
                originalMessage.value = error.response.data.originalMessage ?? null
                reasons.value = error.response.data.reason ?? null
                debug.value = error.response.data.debug ?? null
            }

            if (error.response.status === 407) {
                message.value = 'error.auth_proxy_failed',
                originalMessage.value = 'error.auth_proxy_failed.legend'
            }
            else if (error.response.status === 403) {
                message.value = 'error.unauthorized',
                originalMessage.value = 'error.unauthorized.legend'
            }
        } else {
            message.value = error.message
            debug.value = error.stack ?? null
        }

        if (reasons.value && ! Array.isArray(reasons.value)) {
            reasons.value = new Array(reasons.value)
        }
    }
    
    /**
     * 
     */
    function show(error) {
        parse(error)
        this.$router.push({ name: 'genericError' })
    }

    /**
     * Push the user to the notFound error page
     */
    function notFound() {
        this.$router.push({ name: '404' })
    }

    return {
        // STATE
        lastError,
        message,
        reasons,
        originalMessage,
        debug,

        // ACTIONS
        parse,
        show,
        notFound,
    }
})