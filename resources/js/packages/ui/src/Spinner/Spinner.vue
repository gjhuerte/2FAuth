<script setup>

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
            <div class="flex flex-col items-center gap-5 rounded-[32px] bg-md-surface-container px-10 py-8 animate-enter">
                <span id="icnSpinnerFull" class="md-loader-contained size-16">
                    <span class="md-loader size-10"></span>
                </span>
                <span class="text-label text-md-on-surface-variant">{{ $t(message) }}</span>
            </div>
        </div>
        <span v-else-if="type == 'raw'" class="md-loader" :style="{ width: rawSize + 'px', height: rawSize + 'px' }" role="status"></span>
        <div v-else-if="type == 'list-loading'" class="mt-16 flex justify-center" role="status">
            <span id="icnSpinner" class="md-loader-contained size-14">
                <span class="md-loader size-9"></span>
            </span>
        </div>
    </div>
</template>
