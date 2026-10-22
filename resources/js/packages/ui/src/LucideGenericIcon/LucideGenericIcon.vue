<script setup>
    import { computed } from 'vue';
    import { Sun, Moon, Grid3X3, List, MonitorCheck, Slash, SlidersHorizontal, CircleUser, KeySquare, ScanFace, Settings, UsersRound, ShieldUser, Info } from "@lucide/vue";

    const icons = { Sun, Moon, Grid3X3, List, MonitorCheck, Slash, SlidersHorizontal, CircleUser, KeySquare, ScanFace, Settings, UsersRound, ShieldUser, Info }

    const props = defineProps({
        name: {
            type: String,
            required: true
        },
        size: Number,
        color: String,
        strokeWidth: Number,
        defaultClass: String
    })

    const icon = computed(() => icons[props.name]);
</script>

<template>
    <component
        :is="icon"
        :size="size"
        :color="color"
        :stroke-width="strokeWidth"
        :default-class="defaultClass"
    />
</template>