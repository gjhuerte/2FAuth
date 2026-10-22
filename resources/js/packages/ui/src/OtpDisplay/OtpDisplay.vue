<script setup>
    // Peer dependencies
    import { ref, watch, nextTick, computed, useTemplateRef } from 'vue'
    import { useClipboard } from '@vueuse/core'
    import { LucideEye, LucideEyeOff, LucideStar } from '@lucide/vue'

    // Internal package dependencies
    import i18n from '../i18n'
    import { useVisiblePassword } from '../useVisiblePassword'
    import Spinner from '../Spinner/Spinner.vue'
    import Dots from '../Dots/Dots.vue'
    import DotsController from '../DotsController/DotsController.vue'

    const { t } = i18n.global
    const { copy, copied } = useClipboard({ legacy: true })
    
    const emit = defineEmits([
        'please-close-me',
        'please-clear-search',
        'please-update-active-group',
        'please-toggle-favorite',
        'kickme',
        'increment-hotp',
        'error',
        'validation-error',
        'otp-copied-to-clipboard'
    ])

    const props = defineProps({
        twofaccountService: {
            required: true,
        },
        preferences: {
            type: Object,
            required: true,
        },
        can_showNextOtp: {
            type: Boolean,
            default: true,
        },
        can_showFavorite: {
            type: Boolean,
            default: true,
        },
        can_autoCloseTimeout: {
            type: Boolean,
            default: true,
        },
        iconPathPrefix: String,
        accountParams: {
            type: Object,
            default(rawProps) {
                return {
                    otp_type : '',
                    account : '',
                    service : '',
                    icon : '',
                    secret : '',
                    digits : null,
                    algorithm : '',
                    period : null,
                    counter : null,
                    image : '',
                    is_favorite: null
                }
            }
        },
        uri : String
    })

    const twofaccountService = props.twofaccountService
    const id = ref(null)
    // eslint-disable-next-line vue/no-dupe-keys
    const uri = ref(null)
    const otpauthParams = ref({
        otp_type : '',
        account : '',
        service : '',
        icon : '',
        secret : '',
        digits : null,
        algorithm : '',
        period : null,
        counter : null,
        image : '',
        is_favorite: null
    })
    const discloseDottedPwd = ref(false)
    const password = ref('')
    const visiblePassword = computed(() => {
        return useVisiblePassword(
            password,
            props.preferences.formatPassword,
            props.preferences.formatPasswordBy,
            props.preferences.showOtpAsDot,
            discloseDottedPwd
        )
    })
    const next_password = ref('')
    const visible_next_password = computed(() => {
        return useVisiblePassword(
            next_password,
            props.preferences.formatPassword,
            props.preferences.formatPasswordBy,
            props.preferences.showOtpAsDot,
            discloseDottedPwd
        )
    })
    const generated_at = ref(null)
    const hasTOTP = ref(false)
    const showMainSpinner = ref(false)
    const opacity = ref('0')
    const autoCloseTimeout = ref(null)

    const dotsControllerRef = useTemplateRef('dotsController')
    const dotsRef = useTemplateRef('dots')
    const otpSpanTagRef = useTemplateRef('otpSpanTag')

    watch(
        () => props.accountParams.icon,
        (val) => {
            if (val != undefined) {
                otpauthParams.value.icon = val
            }
        }
    )

    /***
     * 
     */
    const show = async (accountId) => {
        discloseDottedPwd.value = false      

        // 3 possible cases :
        //
        //   Case 1 : When user asks for an otp of an existing account: the ID is provided so we fetch the account data
        //     from db but without the uri. This prevent the uri (a sensitive data) to transit via http request unnecessarily.
        //     In this case this.otp_type is sent by the backend.
        //
        //   # NO LONGER USED : The uri should be parsed and its values passed via the otpauthParams prop.
        //   # Case 2 : When user uses the Quick Uploader and preview the account: No ID but we have an URI.
        //
        //   Case 3 : When user uses the Advanced form and preview the account: We should have all OTP parameters
        //     (in props.accountParams) to obtain an otp, including Secret and otp_type which are required

        otpauthParams.value.otp_type = props.accountParams.otp_type
        otpauthParams.value.account = props.accountParams.account
        otpauthParams.value.service = props.accountParams.service
        otpauthParams.value.icon = props.accountParams.icon
        otpauthParams.value.secret = props.accountParams.secret
        otpauthParams.value.digits = props.accountParams.digits
        otpauthParams.value.algorithm = props.accountParams.algorithm
        otpauthParams.value.period = props.accountParams.period
        otpauthParams.value.counter = props.accountParams.counter
        otpauthParams.value.is_favorite = props.accountParams.is_favorite
        setLoadingState()

        // Case 1
        if (accountId) {
            id.value = accountId
            const { data } = await twofaccountService.get(id.value)

            otpauthParams.value.service = data.service
            otpauthParams.value.account = data.account
            otpauthParams.value.icon = data.icon
            otpauthParams.value.otp_type = data.otp_type

            if( isHMacBased(data.otp_type) && data.counter ) {
                otpauthParams.value.counter = data.counter
            }
        }
        // Case 2
        else if(props.uri) {
            uri.value = props.uri
            otpauthParams.value.otp_type = props.uri.slice(0, 15 ).toLowerCase() === "otpauth://totp/" ? 'totp' : 'hotp'
        }
        // Case 3
        else {
            if (! props.accountParams.secret) {
                emit('error', new Error(t('error.cannot_create_otp_without_secret')))
            }
            else if (! isTimeBased(otpauthParams.value.otp_type) && ! isHMacBased(otpauthParams.value.otp_type)) {
                emit('error', new Error(t('error.not_a_supported_otp_type')))
            }

            if (isTimeBased(otpauthParams.value.otp_type)) {
                hasTOTP.value = true
            }
        }

        try {
            await getOtp()
            focusOnOTP()

            if (props.preferences.getOtpOnRequest && props.can_autoCloseTimeout && parseInt(props.preferences.autoCloseTimeout) > 0) {
                startAutoCloseTimer()
            }
        }
        catch(error) {
            clearOTP()
        }
    }

    /**
     * Requests and handles a fresh OTP
     */
    async function getOtp() {
        // We replace the current on screen password with the next_password to avoid having a loader.
        // The next_password will be confirmed with a new request to be synced with the backend no matter what.
        if (props.can_showNextOtp && next_password.value) {
            password.value = next_password.value
            next_password.value = ''
            dotsRef.value.turnOff()
            turnDotOn(0)
        }
        else {
            setLoadingState()
        }

        await getOtpPromise().then(response => {
            let otp = response.data
            password.value = otp.password
            next_password.value = props.can_showNextOtp && Object.prototype.hasOwnProperty.call(otp, 'next_password') ? otp.next_password : ''

            if(props.preferences.copyOtpOnDisplay) {
                copyOTP(otp.password)
            }

            if (isTimeBased(otp.otp_type)) {
                generated_at.value = otp.generated_at
                otpauthParams.value.period = otp.period
                hasTOTP.value = true

                nextTick().then(() => {
                    dotsControllerRef.value.startStepping()
                })
            }
            else if (isHMacBased(otp.otp_type)) {
                otpauthParams.value.counter = otp.counter

                // returned counter & uri are incremented
                emit('increment-hotp', { nextHotpCounter: otp.counter, nextUri: otp.uri })
            }
        })
        .catch(error => {
            if (error.response.status === 422) {
                emit('validation-error', error.response)
            }
            //throw error
        })
        .finally(() => {
            showMainSpinner.value = false
        })
    }

    /**
     * Shows blacked dots and a loading spinner
     */
    function setLoadingState() {
        showMainSpinner.value = true
        dotsRef.value.turnOff()
    }

    /**
     * Returns the appropriate promise to get a fresh OTP from backend
     */
    function getOtpPromise() {
        if(id.value) {
            return twofaccountService.getOtpById(id.value)
        }
        else if(uri.value) {
            return twofaccountService.getOtpByUri(uri.value)
        }
        else {
            return twofaccountService.getOtpByParams(otpauthParams.value)
        }
    }

    /**
     * Triggers the component closing
     */
    function closeMe() {
        emit("please-close-me");
        discloseDottedPwd.value = false
        clearOTP()
    }

    /**
     * Reset component's refs
     */
    function clearOTP() {
        id.value = otpauthParams.value.counter = generated_at.value = null
        otpauthParams.value.service = otpauthParams.value.account = otpauthParams.value.icon = otpauthParams.value.otp_type = otpauthParams.value.secret = ''
        password.value = '... ...'
        next_password.value = ''
        hasTOTP.value = false
        clearTimeout(autoCloseTimeout.value)

        dotsControllerRef.value?.reset();
    }

    /**
     * Put focus on the OTP html tag
     */
    function focusOnOTP() {
        nextTick().then(() => {
            otpSpanTagRef.value?.focus()
        })
    }

    /**
     * Copies to clipboard
     * 
     * @param {string} otp The password to copy
     * @param {*} permit_closing Toggle moddle closing On-Off
     */
    function copyOTP(otp, permit_closing) {
        copy(otp.replace(/ /g, ''))

        if (copied) {
            if (props.preferences.kickUserAfter == -1 && (permit_closing || false) === true) {
                emit('kickme')
            } else if(props.preferences.closeOtpOnCopy && (permit_closing || false) === true) {
                closeMe()
            }

            if(props.preferences.clearSearchOnCopy) {
                emit('please-clear-search')
            }
            if (props.preferences.viewDefaultGroupOnCopy) {
                const newActiveGroup = props.preferences.defaultGroup == -1 ?
                    props.preferences.activeGroup
                    : props.preferences.defaultGroup

                emit('please-update-active-group', newActiveGroup);
            }

            emit('otp-copied-to-clipboard')
        }
    }

    /**
     * Checks OTP type is Time based (TOTP)
     * 
     * @param {string} otp_type 
     */
    function isTimeBased(otp_type) {
        return (otp_type === 'totp' || otp_type === 'steamtotp')
    }

    /**
     * Checks OTP type is HMAC based (HOTP)
     * 
     * @param {string} otp_type 
     */
    function isHMacBased(otp_type) {
        return otp_type === 'hotp'
    }
    
    /**
     * Turns dots On from the first one to the provided one
     */
    function turnDotOn(dotIndex) {
        dotsRef.value.turnOn(dotIndex)
        opacity.value = 'opacity-step-' + dotIndex
    }

    defineExpose({
        show,
        clearOTP,
        setFavorite
    })

    /**
     * Force the favorite status
     */
    function setFavorite(is_favorite)
    {
        otpauthParams.value.is_favorite = is_favorite
    }
    
    /**
     * Starts an auto close timer
     */
    function startAutoCloseTimer() {
        let duration = parseInt(props.preferences.autoCloseTimeout) // in minutes
        
        autoCloseTimeout.value = setTimeout(function() {
            closeMe()
        }, duration * 60 * 1000);
    }

</script>

<template>
    <div class="flex flex-col items-center">
        <figure
            class="mb-5 inline-flex size-20 rotate-[-4deg] items-center justify-center overflow-hidden rounded-lg shadow-md animate-pop"
            :class="otpauthParams.icon ? 'md-tone-' + ((otpauthParams.service || '').length % 5) : 'no-icon border border-dashed border-md-outline-variant bg-md-surface shadow-none'"
        >
            <img class="size-14 object-contain" :src="iconPathPrefix + '/storage/icons/' + otpauthParams.icon" v-if="otpauthParams.icon" :alt="$t('alttext.icon_to_illustrate_the_account')">
        </figure>
        <p class="flex max-w-full items-center justify-center gap-1 font-display text-title-lg font-semibold text-md-on-surface">
            <button
                v-if="id && props.can_showFavorite && props.preferences.enableFavorites && otpauthParams.is_favorite != null"
                type="button"
                class="favorite-icon md-icon-btn md-icon-btn-sm -ml-2"
                @click.stop="$emit('please-toggle-favorite', id)"
                :title="otpauthParams.is_favorite ? $t('tooltip.remove_from_favorites') : $t('tooltip.set_as_favorite')"
                :aria-label="otpauthParams.is_favorite ? $t('tooltip.remove_from_favorites') : $t('tooltip.set_as_favorite')"
                :aria-pressed="!!otpauthParams.is_favorite"
            >
                <LucideStar :class="otpauthParams.is_favorite ? 'fill-md-star text-md-star' : 'text-md-outline'" :strokeWidth="1.5" />
            </button>
            <span class="truncate">{{ otpauthParams.service }}</span>
        </p>
        <p class="mt-1 max-w-full truncate text-body text-md-on-surface-variant">{{ otpauthParams.account }}</p>
        <div class="mt-8 flex min-h-20 items-center justify-center">
            <span
                v-if="!showMainSpinner"
                :key="visiblePassword"
                id="otp"
                role="log"
                ref="otpSpanTag"
                tabindex="0"
                class="otp group relative animate-pop cursor-pointer rounded-lg px-5 py-2 font-mono text-[2.75rem] font-medium leading-none tracking-[0.06em] text-md-on-surface tabular-nums outline-none transition-[background-color,transform] duration-200 ease-md hover:bg-md-primary-soft active:scale-90 focus-visible:ring-2 focus-visible:ring-md-primary sm:text-display"
                @click="copyOTP(password, true)"
                @keyup.enter="copyOTP(password, true)"
                :title="$t('tooltip.copy_to_clipboard')"
            >
                {{ visiblePassword }}
            </span>
            <span v-else tabindex="0" class="otp inline-flex h-16 items-center">
                <Spinner :isVisible="showMainSpinner" :type="'raw'" :rawSize="36" />
            </span>
        </div>
        <div class="mt-3 flex h-3 items-center">
            <Dots ref="dots" v-show="isTimeBased(otpauthParams.otp_type)" />
        </div>
        <p v-show="isHMacBased(otpauthParams.otp_type)" class="md-badge mt-1">
            {{ $t('field.counter') }}: {{ otpauthParams.counter }}
        </p>
        <p v-if="props.can_showNextOtp && props.preferences.showNextOtp" class="mt-4 min-h-8 font-mono text-title tabular-nums text-md-on-surface-variant">
            <span
                v-if="next_password"
                class="cursor-pointer rounded-sm px-2 py-1 transition-[background-color,opacity] duration-300 ease-md hover:bg-md-primary-soft"
                :class="opacity"
                @click="copyOTP(next_password, true)"
                @keyup.enter="copyOTP(next_password, true)"
                :title="$t('tooltip.copy_next_password')"
            >
                {{ visible_next_password }}
            </span>
            <span v-else>&nbsp;</span>
        </p>
        <p v-if="props.preferences.showOtpAsDot && props.preferences.revealDottedOTP" class="mt-3">
            <button
                type="button"
                class="md-icon-btn"
                @click.stop="discloseDottedPwd = !discloseDottedPwd"
                :aria-label="discloseDottedPwd ? $t('tooltip.hide_password') : $t('tooltip.reveal_password')"
                :aria-pressed="discloseDottedPwd"
            >
                 <LucideEye v-if="discloseDottedPwd" />
                 <LucideEyeOff v-else />
            </button>
        </p>
        <DotsController
            v-if="hasTOTP"
            :period="otpauthParams.period"
            :generated_at="generated_at"
            :autostart="false"
            v-on:stepping-ended="getOtp()"
            v-on:stepping-started="turnDotOn($event)"
            v-on:stepped-up="turnDotOn($event)"
            ref="dotsController"
        ></DotsController>
    </div>
</template>
