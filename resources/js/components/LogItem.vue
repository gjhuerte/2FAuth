<script setup>
    import {
        LucideSmartphone,
        LucideMonitor,
        LucideTablet,
        LucideCheck,
        LucideX
    } from '@lucide/vue'

    const $2fauth = inject('2fauth')

    const props = defineProps({
        log: {
            type: Object,
            required: true
        },
        logType: {
            type: String,
            required: true,
            validator(value, props) {
                return ['auth', 'otp'].includes(value)
            }
        }
    })

    const isSuccessfulLogin = (log) => {
        return log.login_successful && log.login_at
    }

    const isSuccessfulLogout = (log) => {
        return !log.login_at && log.logout_at
    }

    const isFailedEntry = (log) => {
        return !log.login_successful && !log.logout_at
    }
</script>

<template>
    <div class="md-list-item items-start text-label font-normal leading-relaxed text-md-on-surface-variant">
        <template v-if="props.logType == 'auth'">
            <div class="relative mt-0.5 inline-flex size-11 shrink-0 items-center justify-center rounded-full bg-md-surface-container-highest text-md-on-surface-variant">
                <LucideSmartphone v-if="log.device=='phone'" />
                <LucideTablet v-else-if="log.device=='tablet'" />
                <LucideMonitor v-else />
                <span
                    class="absolute -bottom-0.5 -right-0.5 inline-flex size-5 items-center justify-center rounded-full ring-2 ring-md-surface-container"
                    :class="isFailedEntry(log) ? 'bg-md-error text-md-on-error' : 'bg-md-success text-md-on-success'"
                >
                    <LucideX v-if="isFailedEntry(log)" stroke-width="3" class="size-3!" />
                    <LucideCheck v-else stroke-width="3" class="size-3!" />
                </span>
            </div>
            <div class="min-w-0 flex-1">
                <p class="text-body text-md-on-surface-variant">
                    <i18n-t v-if="isFailedEntry(log)" keypath="message.failed_login_on" tag="span">
                        <template v-slot:login_at>
                            <span class="font-medium text-md-on-surface">{{ log.login_at }}</span>
                        </template>
                    </i18n-t>
                    <i18n-t v-else-if="isSuccessfulLogout(log)" keypath="message.successful_logout_on" tag="span">
                        <template v-slot:logout_at>
                            <span class="font-medium text-md-on-surface">{{ log.logout_at }}</span>
                        </template>
                    </i18n-t>
                    <i18n-t v-else-if="$2fauth.config.proxyAuth" keypath="message.viewed_on" tag="span">
                        <template v-slot:login_at>
                            <span class="font-medium text-md-on-surface">{{ log.login_at }}</span>
                        </template>
                    </i18n-t>
                    <i18n-t v-else keypath="message.successful_login_on" tag="span">
                        <template v-slot:login_at>
                            <span class="font-medium text-md-on-surface">{{ log.login_at }}</span>
                        </template>
                    </i18n-t>
                </p>
                <p class="mt-1 flex flex-wrap gap-x-3 gap-y-0.5">
                    <span>{{ $t('label.IP') }}: <span class="font-medium text-md-on-surface">{{ log.ip_address }}</span></span>
                    <span>{{ $t('label.browser') }}: <span class="font-medium text-md-on-surface">{{ log.browser }}</span></span>
                    <span>{{ $t('label.operating_system_short') }}: <span class="font-medium text-md-on-surface">{{ log.platform }}</span></span>
                </p>
            </div>
        </template>
        <div v-else-if="props.logType == 'otp'" class="flex w-full items-start gap-4">
            <span class="mt-0.5 inline-flex h-7 shrink-0 items-center rounded-full bg-md-secondary-container px-2.5 font-mono text-label-sm font-medium text-md-on-secondary-container">{{ log.otp_type.toUpperCase() }}</span>
            <div class="min-w-0 flex-1">
                <i18n-t keypath="message.otp_generated_by_on" tag="p" class="text-body">
                    <template v-slot:otp>
                        <span class="font-medium text-md-on-surface">{{ log.otp_type.toUpperCase() }}</span>
                    </template>
                    <template v-slot:requester>
                        <span class="font-medium text-md-on-surface">{{ log.requester_name }} ({{ log.requester_email }})</span>
                    </template>
                    <template v-slot:generated_at>
                        <span class="font-medium text-md-on-surface">{{ new Date(log.generated_at).toLocaleString() }}</span>
                    </template>
                </i18n-t>
                <p class="mt-1 flex flex-wrap gap-x-3">
                    <span>{{ $t('label.IP') }}: <span class="font-medium text-md-on-surface">{{ log.ip_address }}</span></span>
                    <span v-if="log.otp_type == 'hotp'">{{ $t('label.counter') }}: <span class="font-medium text-md-on-surface">{{ log.counter }}</span></span>
                </p>
            </div>
        </div>
    </div>
</template>
