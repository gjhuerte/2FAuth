<script setup>
    /**
     * Atmospheric Material You backdrop: layered, heavily blurred organic
     * shapes in the primary / tertiary / secondary tones, sitting behind
     * every screen. Purely decorative.
     */
</script>

<template>
    <div aria-hidden="true" class="pointer-events-none fixed inset-0 -z-10 overflow-hidden">
        <div class="absolute inset-0 bg-[radial-gradient(circle_at_top_right,var(--md-secondary-container)_0%,transparent_45%)] opacity-70 dark:opacity-25"></div>
        <div class="absolute -top-40 -left-32 size-[34rem] rounded-[100px] rounded-tr-[20px] bg-md-primary/25 blur-3xl mix-blend-multiply dark:bg-md-primary/15 dark:mix-blend-screen"></div>
        <div class="absolute top-1/3 -right-48 size-[30rem] rounded-full bg-md-tertiary/20 blur-3xl mix-blend-multiply dark:bg-md-tertiary/10 dark:mix-blend-screen"></div>
        <div class="absolute -bottom-56 left-1/4 h-[28rem] w-[40rem] rounded-[100px] rounded-bl-[24px] bg-md-secondary-container/70 blur-3xl mix-blend-multiply dark:bg-md-secondary-container/30 dark:mix-blend-screen"></div>
    </div>
</template>
