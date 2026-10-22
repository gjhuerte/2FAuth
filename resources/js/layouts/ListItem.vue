<script setup>

</script>

<template>
    <div class="md-list-item">
        <div class="min-w-0 flex-1">
            <slot name="item"></slot>
            <slot name="legend"></slot>
        </div>
        <div class="flex shrink-0 items-center gap-1.5">
            <slot name="buttons"></slot>
        </div>
    </div>
</template>
