<script setup>

    const props = defineProps({
        twofaccount: {
            type: Object,
            required: true
        }
    })

    const $2fauth = inject('2fauth')

</script>

<template>
    <div class="md-card mb-6 flex items-center gap-4 p-4">
        <img v-if="twofaccount.icon" role="presentation" class="md-account-icon size-12 -rotate-6" :class="'md-tone-' + ((twofaccount.id ?? 0) % 5)" :src="$2fauth.config.subdirectory + '/storage/icons/' + twofaccount.icon" alt="">
        <img v-else-if="twofaccount.icon == null" role="presentation" class="md-account-icon size-12 p-2.5" :src="$2fauth.config.subdirectory + '/storage/noicon.svg'" alt="">
        <div class="min-w-0">
            <p class="truncate font-display text-title text-md-on-surface">
                {{ twofaccount.service }}
            </p>
            <p class="truncate text-label font-normal text-md-on-surface-variant">{{ twofaccount.account }}</p>
        </div>
    </div>
</template>
