<script setup>
    import LogItem from '@/components/LogItem.vue'
    import userService from '@/services/userService'
    import { useErrorHandler } from '@2fauth/stores'
    import { SearchBox } from '@2fauth/ui'
    import {
        LucideCalendarArrowDown,
        LucideCalendarArrowUp,
    } from '@lucide/vue'

    const errorHandler = useErrorHandler()
    const $2fauth = inject('2fauth')

    const props = defineProps({
        userId: [Number, String],
        lastOnly: Boolean,
        showSearch: Boolean,
        period: {
            type: [Number, String],
            default: 12
        },
    })

    const periods = {
        aMonth: 1,
        threeMonths: 3,
        halfYear: 6,
        aYear: 12
    }

    const authentications = ref([])
    const isFetching = ref(false)
    const searched = ref('')
    const period = ref(props.period)
    const orderIsDesc = ref(true)

    const emit = defineEmits(['has-more-entries'])

    const visibleAuthentications = computed(() => {
        return authentications.value.filter(authentication => {
            return JSON.stringify(authentication)
            .toString()
            .toLowerCase()
            .includes(searched.value);
        })
    })

    onMounted(() => {
        getAuthentications()
    })

    /**
     * Sets the visible time span
     * 
     * @param {int} duration 
     */
    function setPeriod(duration) {
        period.value = duration
        getAuthentications()
    }

    /**
     * Set sort order to ASC
     */
    function setAsc() {
        orderIsDesc.value = false
        sortAsc()
    }
        
    /**
     * Sorts entries ascending
     */
    function sortAsc() {
        authentications.value.sort((a, b) => a.id > b.id ? 1 : -1)
    }

    /**
     * Set sort order to DESC
     */
    function setDesc() {
        orderIsDesc.value = true
        sortDesc()
    }

    /**
     * Sorts entries descending
    */
    function sortDesc() {
        authentications.value.sort((a, b) => a.id < b.id ? 1 : -1)
    }

    /**
     * Gets user authentication logs
     */
    function getAuthentications() {
        isFetching.value = true
        let limit = props.lastOnly ? 4 : false

        userService.getauthentications(props.userId, period.value, limit, {returnError: true})
        .then(response => {
            authentications.value = response.data

            if (authentications.value.length > 3 && props.lastOnly) {
                emit('has-more-entries')
                authentications.value.pop()
            }
            
            orderIsDesc.value == true ? sortDesc() : sortAsc()
        })
        .catch(error => {
            errorHandler.show(error)
        })
        .finally(() => {
            isFetching.value = false
        })
    }

    const deviceIcon = (device) => {
        switch (device) {
            case "phone":
                return 'mobile-screen'
            case "tablet":
                return 'tablet-screen-button'
            default:
                return 'display'
        }
    }
</script>

<template>
    <div v-if="props.showSearch" class="mb-4 flex flex-col gap-3">
        <SearchBox v-model:keyword="searched" :hasNoBackground="true" :isSmall="true" />
        <nav class="flex flex-wrap items-center justify-center gap-2">
            <div class="md-segmented h-9" role="group">
                <button id="btnShowOneMonth" :title="$t('tooltip.show_last_month_log')" v-on:click="setPeriod(periods.aMonth)" :aria-checked="period === periods.aMonth" role="radio" type="button" class="md-segment min-h-9 px-3 py-0 text-label-sm">
                    {{ $t('label.one_month') }}
                </button>
                <button id="btnShowThreeMonths" :title="$t('tooltip.show_three_months_log')" v-on:click="setPeriod(periods.threeMonths)" :aria-checked="period === periods.threeMonths" role="radio" type="button" class="md-segment min-h-9 px-3 py-0 text-label-sm">
                    {{ $t('label.x_month', { 'x' : '3' }) }}
                </button>
                <button id="btnShowSixMonths" :title="$t('tooltip.show_six_months_log')" v-on:click="setPeriod(periods.halfYear)" :aria-checked="period === periods.halfYear" role="radio" type="button" class="md-segment min-h-9 px-3 py-0 text-label-sm">
                    {{ $t('label.x_month', { 'x' : '6' }) }}
                </button>
                <button id="btnShowOneYear" :title="$t('tooltip.show_one_year_log')" v-on:click="setPeriod(periods.aYear)" :aria-checked="period === periods.aYear" role="radio" type="button" class="md-segment min-h-9 px-3 py-0 text-label-sm">
                    {{ $t('label.one_year') }}
                </button>
            </div>
            <div class="flex items-center gap-1">
                <button id="btnSortLogDesc" v-on:click="setDesc" :title="$t('tooltip.sort_by_date_desc')" :aria-label="$t('tooltip.sort_by_date_desc')" :aria-pressed="orderIsDesc" type="button" class="md-icon-btn md-icon-btn-sm aria-pressed:bg-md-secondary-container aria-pressed:text-md-on-secondary-container">
                    <LucideCalendarArrowDown />
                </button>
                <button id="btnSortLogAsc" v-on:click="setAsc" :title="$t('tooltip.sort_by_date_asc')" :aria-label="$t('tooltip.sort_by_date_asc')" :aria-pressed="!orderIsDesc" type="button" class="md-icon-btn md-icon-btn-sm aria-pressed:bg-md-secondary-container aria-pressed:text-md-on-secondary-container">
                    <LucideCalendarArrowUp />
                </button>
            </div>
        </nav>
    </div>
    <Spinner v-if="isFetching" :isVisible="true" :type="'list-loading'" />
    <p v-else-if="authentications.length == 0" class="md-card mt-4 text-center text-body text-md-on-surface-variant">
        {{ $t('message.no_entry_yet') }}
    </p>
    <div v-else-if="visibleAuthentications.length > 0" class="md-list">
        <LogItem v-for="authentication in visibleAuthentications" :key="authentication.id" :log="authentication" log-type="auth" />
    </div>
    <p v-else class="mt-5 px-3 text-body text-md-on-surface-variant">
        {{ $t('message.no_result') }}
    </p>
</template>
