<script setup>
    import { useUserStore } from '@/stores/user'
    import { LucideListChecks, LucideTrash2, LucideScanQrCode, LucideUserX, LucidePackage, FolderInput } from '@lucide/vue'

    const router = useRouter()
    const user = useUserStore()

    const props = defineProps({
        inManagementMode: {
            type: Boolean,
            default: false
        },
        canMove: {
            type: Boolean,
            default: true
        },
        showMove: {
            type: Boolean,
            default: true
        },
        canDelete: {
            type: Boolean,
            default: true
        },
        showDelete: {
            type: Boolean,
            default: true
        },
        canUnshare: {
            type: Boolean,
            default: true
        },
        showUnshare: {
            type: Boolean,
            default: false
        },
        canExport: {
            type: Boolean,
            default: true
        },
        showExport: {
            type: Boolean,
            default: true
        },
        areDisabled: {
            type: Boolean,
            default: false
        },
    }) 
    
    const emit = defineEmits(['update:inManagementMode', 'move-button-clicked', 'delete-button-clicked', 'export-button-clicked', 'unshare-button-clicked'])

    /**
     * Routes user to the appropriate submitting view
     */
    function goAddNewAccount() {
        if( user.preferences.useDirectCapture && user.preferences.defaultCaptureMode === 'advancedForm' ) {
            router.push({ name: 'createAccount' })
        }
        else if( user.preferences.useDirectCapture && user.preferences.defaultCaptureMode === 'livescan' ) {
            router.push({ name: 'capture' })
        }
        else {
            router.push({ name: 'start' })
        }
    }
</script>

<template>
    <template v-if="!inManagementMode">
        <!-- New item button -->
        <button type="button" class="md-btn md-btn-filled md-btn-lg" @click="goAddNewAccount">
            <LucideScanQrCode />
            <span>{{ $t('label.new') }}</span>
        </button>
        <!-- Manage button -->
        <button type="button" id="btnManage" class="md-btn md-btn-tonal md-btn-lg" @click="$emit('update:inManagementMode', true)">
            <LucideListChecks />
            <span>{{ $t('label.manage') }}</span>
        </button>
    </template>
    <template v-else>
        <!-- move button -->
        <button
            v-if="showMove"
            id="btnMove"
            type="button"
            :disabled="areDisabled || !canMove"
            class="md-btn md-btn-tonal max-lg:px-3"
            @click="$emit('move-button-clicked')"
            :title="$t('tooltip.move_selected_to_group')"
            :aria-label="$t('tooltip.move_selected_to_group')"
        >
            <FolderInput />
            <span class="max-lg:sr-only">{{ $t('label.move') }}</span>
        </button>
        <!-- unshare button -->
        <button
            v-if="showUnshare"
            id="btnShare"
            type="button"
            :disabled="areDisabled || !canUnshare"
            class="md-btn md-btn-tonal max-lg:px-3"
            @click="$emit('unshare-button-clicked')"
            :title="$t('tooltip.unshare_selected_accounts')"
            :aria-label="$t('tooltip.unshare_selected_accounts')"
        >
            <LucideUserX />
            <span class="max-lg:sr-only">{{ $t('label.unshare') }}</span>
        </button>
        <!-- export button -->
        <button
            v-if="showExport"
            id="btnExport"
            type="button"
            :disabled="areDisabled || !canExport"
            class="md-btn md-btn-tonal max-lg:px-3"
            @click="$emit('export-button-clicked')"
            :title="$t('tooltip.export_selected_accounts')"
            :aria-label="$t('tooltip.export_selected_accounts')"
        >
            <LucidePackage />
            <span class="max-lg:sr-only">{{ $t('label.export') }}</span>
        </button>
        <!-- delete button -->
        <button
            v-if="showDelete"
            id="btnDelete"
            type="button"
            :disabled="areDisabled || !canDelete"
            class="md-btn md-btn-danger-tonal max-lg:px-3"
            @click="$emit('delete-button-clicked')"
            :title="$t('tooltip.delete_selected_accounts')"
            :aria-label="$t('tooltip.delete_selected_accounts')"
        >
            <LucideTrash2 />
            <span class="max-lg:sr-only">{{ $t('label.delete') }}</span>
        </button>
    </template>
</template>
