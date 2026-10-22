<script setup>
    import twofaccountService from '@/services/twofaccountService'
    import shareService from '@/services/shareService'
    import TwofaccountMedia from '@/components/TwofaccountMedia.vue'
    import { useBusStore } from '@/stores/bus'
    import { asArray } from '@/composables/helpers'
    import { useFocus, onKeyStroke } from '@vueuse/core'
    import { LucideInfo, LucideLoaderCircle, LucideSearch, LucideUserCheck, LucideUserPlus, LucideX } from '@lucide/vue'
    import { useTwofaccounts } from '@/stores/twofaccounts'

    const $2fauth = inject('2fauth')
    const router = useRouter()
    const route = useRoute()
    const bus = useBusStore()
    const twofaccounts = useTwofaccounts()
    const returnTo = useStorage($2fauth.prefix + 'returnTo', 'accountSharing')

    const props = defineProps({
        twofaccountId: [Number, String]
    })

    onKeyStroke('Escape', (e) => {
        e.preventDefault()
        clearSearch()
    })

    const findUserForShareField = useTemplateRef('findUserForShare')
    const { focused: findUserForShareFocus } = useFocus(findUserForShareField)

    const twofaccount = ref(twofaccounts.items.find(account => account.id == props.twofaccountId))
    const isFetching = ref(false)
    const isSearching = ref(false)
    const isSending = ref(false)
    const searchQuery = ref('')
    const candidates = ref(null)
    const recipients = ref([])
    
    const returnToObject = computed(() => {
        if (returnTo.value == 'accountSharing') {
            return { name: 'accountSharing', params: { twofaccountId: route.params.twofaccountId }}
        }
        else {
            return { name: returnTo.value }
        }
    })

    const showCandidates = computed(() => {
        return candidates.value?.length > 0
    })

    const hasRecipients = computed(() => {
        return recipients.value.length > 0
    })

    let timeout = null
    let recipientsSearchAbortController = null

    onMounted(() => {
        isFetching.value = true

        twofaccountService.get(props.twofaccountId).then(response => {
            twofaccount.value = response.data
        })
        .finally(() => {
            isFetching.value = false
        })
    })

    onBeforeMount(() => {
    })

    onBeforeUnmount(() => {
        clearSearch()
    })

    watch(searchQuery, (newValue) => {
        if (timeout) clearTimeout(timeout);

        if (newValue.length == 0) {
            clearCandidates()
        }
        else {
            timeout = setTimeout(() => {
                if (newValue.length > 1) {
                    searchRecipient(newValue)
                }
            }, 300)
        }
    })

    /**
     * Get list of recipients matching keyword
     */
    function searchRecipient(keyword) {
        recipientsSearchAbortController?.abort()
        recipientsSearchAbortController = new AbortController()

        const currentSearchAbortController = recipientsSearchAbortController
        const searchLoadingTimeout = setTimeout(() => {
            if (currentSearchAbortController === recipientsSearchAbortController) {
                isSearching.value = true
            }
        }, 250)

        shareService.getRecipients(props.twofaccountId, keyword, {
            signal: recipientsSearchAbortController.signal,
        }).then(response => {
            candidates.value = asArray(response.data)
        })
        .finally(() => {
            clearTimeout(searchLoadingTimeout)
            if (currentSearchAbortController === recipientsSearchAbortController) {
                isSearching.value = false
            }
        })
    }

    /**
     * Add a candidate to the recipients list & Clear search
     */
    function addToRecipients(candidate) {
        if (!recipients.value.some((recipient) => recipient.id == candidate.id)) {
            recipients.value.push(candidate)
        }
        clearCandidates()
        searchQuery.value = ''
        findUserForShareFocus.value = true
    }

    /**
     * Clear candidates list
     */
    function clearCandidates() {
        candidates.value = null
    }

    /**
     * Clear recipients list
     */
    function clearRecipients() {
        recipients.value = []
    }

    /**
     * Remove a recipient from the list
     */
    function removeRecipient(recipient) {
        for (var i=0 ; i < recipients.value.length ; i++) {
            if ( recipients.value[i].id === recipient.id ) {
                recipients.value.splice(i,1);
                return
            }
        }
    }

    /**
     * Clear search
     */
    function clearSearch() {
        recipientsSearchAbortController?.abort()
        recipientsSearchAbortController = null

        searchQuery.value = ''
        clearCandidates()
        isSearching.value = false
    }

    /**
     * Wrapper to call the appropriate function at form submit
     */
    function handleSubmit() {
        isSending.value = true

        if (recipients.value.length > 0) {
            shareService.shareWithUsers(props.twofaccountId, recipients.value.map(r => r.id)).then(response => {
                router.push({ name: 'accountSharing', params: { twofaccountId: props.twofaccountId }})
            })
            .finally(() => {
                isSending.value = false
            })
        }
    }

</script>

<template>
    <StackLayout>
        <template #content>
            <ResponsiveWidthWrapper>
                <h1 class="md-page-title">
                    {{ $t('heading.new_sharing') }}
                </h1>
                <div class="mb-6 mt-2 text-body leading-relaxed text-md-on-surface-variant">
                    <p>{{ $t('message.share_account_with_other_users')}}</p>
                    <p>{{ $t('message.this_form_does_not_affect_existing_sharing')}}</p>
                </div>
                <TwofaccountMedia :twofaccount="twofaccount" />
                <form @submit.prevent="handleSubmit" class="md-card animate-enter sm:p-8">
                    <div class="md-field">
                        <label for="findUserForShare" class="md-label">
                            {{ $t('field.findUserForShare') }}
                        </label>
                        <div class="relative">
                            <input ref="findUserForShare" id="findUserForShare" v-model="searchQuery" type="text" class="md-input pr-14" autocomplete="off" autofocus :aria-expanded="!!(candidates || isSearching)" aria-controls="dropdown-menu" />
                            <button type="button" v-if="searchQuery != ''" id="btnClearSearch" tabindex="1" :title="$t('tooltip.clear_search')" :aria-label="$t('tooltip.clear_search')" class="clear-selection md-icon-btn absolute right-2 top-2" @click="clearSearch">
                                <LucideX />
                            </button>
                            <LucideSearch v-else class="pointer-events-none absolute right-4 top-1/2 -translate-y-1/2 text-md-on-surface-variant" />
                            <!-- candidates -->
                            <div v-if="candidates || isSearching" class="dropdown-menu md-menu absolute inset-x-0 top-full mt-2 w-auto" id="dropdown-menu" role="menu">
                                <template v-if="showCandidates">
                                    <template v-for="candidate in candidates" :key="candidate.id" >
                                        <button v-if="!candidate.is_shared_with" type="button" role="menuitem" @click="addToRecipients(candidate)" class="dropdown-item md-menu-item">
                                            <LucideUserPlus />
                                            {{ candidate.name }}
                                        </button>
                                        <span v-else class="dropdown-item md-menu-item cursor-default text-md-on-surface-variant hover:bg-transparent">
                                            <LucideUserCheck />
                                            {{ candidate.name }} ({{ $t('message.already_shared') }})
                                        </span>
                                    </template>
                                </template>
                                <template v-else>
                                    <span v-if="isSearching" class="dropdown-item flex h-12 items-center justify-center">
                                        <LucideLoaderCircle class="animate-spin-md text-md-primary" />
                                    </span>
                                    <span v-else class="dropdown-item flex h-12 items-center px-4 text-label italic text-md-on-surface-variant">{{ $t('message.no_match') }}</span>
                                </template>
                            </div>
                        </div>
                        <p class="md-help">{{ $t('field.findUserForShare.help') }}</p>
                    </div>
                    <div v-if="recipients.length > 0" class="mb-6 flex flex-wrap gap-2">
                        <span v-for="recipient in recipients" :key="recipient.id" class="md-chip md-chip-selected cursor-default pr-1">
                            {{ recipient.name }}
                            <button type="button" @click="removeRecipient(recipient)" class="is-delete inline-flex size-6 items-center justify-center rounded-full hover:bg-md-secondary-container-hover" :aria-label="$t('tooltip.revoke')">
                                <LucideX class="size-3.5!" />
                            </button>
                        </span>
                    </div>
                    <p class="md-callout">
                        <LucideInfo />
                        {{ $t('message.keep_in_mind_share_principle') }}
                    </p>
                    <FormButtons
                        :isDisabled="!hasRecipients"
                        :isBusy="isSending"
                        :submitLabel="'label.share'"
                        :showCancelButton="true"
                        @cancel="router.push(returnToObject)" />
                </form>
            </ResponsiveWidthWrapper>
        </template>
    </StackLayout>
</template>
