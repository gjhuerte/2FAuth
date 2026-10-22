<script setup>
    import tabs from './tabs'
    import userService from '@/services/userService'
    import { useNotify, TabBar, SearchBox } from '@2fauth/ui'
    import { useErrorHandler } from '@2fauth/stores'
    import { LucideShieldUser, LucideUserPlus } from '@lucide/vue'

    const errorHandler = useErrorHandler()
    const $2fauth = inject('2fauth')
    const notify = useNotify()
    const returnTo = useStorage($2fauth.prefix + 'returnTo', 'accounts')

    const users = ref([])
    const searched = ref('')
    const isFetching = ref(false)

    const visibleUsers = computed(() => {
        return users.value.filter(
            user => {
                let ret = user.name.toLowerCase().includes(searchedObj.value.keywords)
                    || user.email.toLowerCase().includes(searchedObj.value.keywords)

                if (searchedObj.value.admin != undefined) {
                    ret = ret && user.is_admin == searchedObj.value.admin
                }
                if (searchedObj.value.oauth != undefined) {
                    ret = ret && user.oauth_provider == searchedObj.value.oauth
                }

                return ret
            }
        )
    })

    const searchedObj = computed(() => {
        const obj = {
            admin: undefined,
            oauth: undefined,
            keywords: searched.value.toLowerCase()
        }
        const searchedChunks = searched.value.toLowerCase().split(' ')
        const regexAdmin = /admin:([01])/
        const regexOAuth = /oauth:([a-zA-Z0-9])/

        searchedChunks.forEach(chunk => {
            if (chunk.match(regexAdmin)) {
                obj.admin = parseInt(chunk.replace(regexAdmin, '$1'))
                obj.keywords = obj.keywords.replace(chunk, '').trim()
            }
            if (chunk.match(regexOAuth)) {
                obj.oauth = chunk.replace(regexOAuth, '$1')
                obj.keywords = obj.keywords.replace(chunk, '').trim()
            }
        })

        return obj
    })

    onMounted(() => {
        fetchUsers()
    })

    /**
     * 
     * @param {*} filter 
     */
    function addFilter(filter) {
        const regexAdmin = /admin:([01])/
        const regexOAuth = /oauth:([a-zA-Z0-9]*)/

        if (searched.value.match(regexAdmin) && filter.match(regexAdmin)) {
            searched.value = searched.value.replace(regexAdmin, filter)
        }
        else if (searchedObj.value.oauth != undefined && filter.match(regexOAuth)) {
            searched.value = searched.value.replace(regexOAuth, filter)
        }
        else searched.value = searched.value ? searched.value + ' ' + filter : filter
    }

    /**
     * Gets all users from backend
     */
    function fetchUsers() {
        isFetching.value = true

        userService.getAll({returnError: true})
        .then(response => {
            users.value = response.data
        })
        .catch(error => {
            errorHandler.show(error)
        })
        .finally(() => {
            isFetching.value = false
        })
    }

    onBeforeRouteLeave((to) => {
        if (! to.name.startsWith('admin.')) {
            notify.clear()
        }
    })

</script>

<template>
    <StackLayout>
        <template #header>
            <TabBar :tabs="tabs" :active-tab="'admin.users'" @tab-selected="(to) => router.push({ name: to })" />
        </template>
        <template #content>
            <FormWrapper>
                <div class="flex flex-wrap items-end justify-between gap-4">
                    <div>
                        <h1 class="md-page-title">{{ $t('heading.users') }}</h1>
                        <p class="mt-2 max-w-prose text-body text-md-on-surface-variant">
                            {{ $t('message.admin_users_legend')}}
                        </p>
                    </div>
                    <RouterLink class="md-btn md-btn-tonal" :to="{ name: 'admin.createUser' }">
                        <LucideUserPlus /> {{ $t('link.create_new_user') }}
                    </RouterLink>
                </div>
                <!-- search -->
                <div class="mt-8">
                    <SearchBox v-model:keyword="searched" :hasNoBackground="true" :placeholder="$t('placeholder.search_user_placeholder')" />
                </div>
                <div id="groupChips" class="mb-4 mt-3 flex flex-wrap justify-center gap-2">
                    <button type="button" @click="addFilter('admin:1')" class="md-chip">
                        <LucideShieldUser />
                        admin
                    </button>
                    <button type="button" @click="addFilter('oauth:github')" class="md-chip">
                        github
                    </button>
                    <button type="button" @click="addFilter('oauth:openid')" class="md-chip">
                        openId
                    </button>
                </div>
                <ul v-if="visibleUsers.length > 0" class="flex flex-col gap-2 pb-8">
                    <li v-for="user in visibleUsers" :key="user.id" class="md-card flex items-center gap-4 px-4 py-3 sm:px-5">
                        <span class="inline-flex size-11 shrink-0 items-center justify-center rounded-full font-display text-title font-semibold" :class="'md-tone-' + (user.id % 5)" aria-hidden="true">
                            {{ user.name.charAt(0).toUpperCase() }}
                        </span>
                        <div class="min-w-0 flex-1">
                            <p class="truncate font-display text-title text-md-on-surface">{{ user.name }}</p>
                            <p class="truncate text-label font-normal text-md-on-surface-variant">{{ user.email }}</p>
                            <div v-if="user.is_admin || user.oauth_provider" class="mt-2 flex flex-wrap gap-1.5">
                                <span v-if="user.is_admin" class="md-badge md-badge-warning">admin</span>
                                <span v-if="user.oauth_provider" class="md-badge md-badge-outline">oauth: {{ user.oauth_provider }}</span>
                            </div>
                        </div>
                        <!-- manage link -->
                        <RouterLink :to="{ name: 'admin.manageUser', params: { userId: user.id }}" class="md-btn md-btn-tonal md-btn-sm shrink-0" :title="$t('tooltip.manage')">
                            {{ $t('link.manage') }}
                        </RouterLink>
                    </li>
                </ul>
                <Spinner v-else-if="isFetching" :isVisible="true" type="list-loading" />
                <p v-else class="mt-4 px-3 text-body text-md-on-surface-variant">
                    {{ $t('message.no_result') }}
                </p>
            </FormWrapper>
        </template>
        <template #footer>
            <VueFooter>
                <template #default>
                    <NavigationButton action="close" @closed="router.push({ name: returnTo })" :current-page-title="$t('title.admin.users')" />
                </template>
            </VueFooter>
        </template>
    </StackLayout>
</template>
