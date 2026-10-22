<script setup>
    import { LucideLoaderCircle } from '@lucide/vue';

    const props = defineProps({
        isVisible: Boolean,
        type: {
            type: String,
            default: 'raw',
            required: true,
            validator(value, props) {
                return ['raw', 'list-loading', 'fullscreen', 'fullscreen-overlay'].includes(value)
            }
        },
        message: {
            type: String,
            default: '[[awaiting_message]]'
        },
        rawSize: {
            type: Number,
            default: 24
        },
    })
</script>

<template>
    <div v-if="isVisible" class="contents">
        <div
            v-if="type == 'fullscreen' || type == 'fullscreen-overlay'"
            class="fixed inset-x-0 z-[100000] flex items-center justify-center"
            :class="type == 'fullscreen' ? 'inset-y-0 bg-md-surface' : 'top-1/4 h-1/2'"
            role="status"
        >
            <div class="flex flex-col items-center gap-5 rounded-xl bg-md-surface-container px-10 py-8 shadow-lg animate-enter">
                <span id="icnSpinnerFull" class="relative inline-flex size-16 items-center justify-center">
                    <span class="absolute inset-0 rounded-full bg-md-primary/20 blur-xl" aria-hidden="true"></span>
                    <LucideLoaderCircle class="relative size-12! animate-spin-md text-md-primary" />
                </span>
                <span class="text-label text-md-on-surface-variant">{{ $t(message) }}</span>
            </div>
        </div>
        <LucideLoaderCircle v-else-if="type == 'raw'" class="inline-block animate-spin-md text-md-primary" :size="rawSize" :style="{ width: rawSize + 'px', height: rawSize + 'px' }" />
        <div v-else-if="type == 'list-loading'" class="mt-16 flex justify-center" role="status">
            <span id="icnSpinner" class="inline-flex size-12 items-center justify-center rounded-full bg-md-surface-container shadow-sm">
                <LucideLoaderCircle class="size-6! animate-spin-md text-md-primary" />
            </span>
        </div>
    </div>
</template>
