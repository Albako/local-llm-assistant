<script lang="ts">
	import { onMount } from 'svelte';
	import { isNativeMobile, checkNetworkStatus, listenToNetworkChanges } from '$lib/mobile';

	let isMobile = false;
	let isOnline = navigator.onLine;
	let unsubscribe: (() => void) | null = null;

	onMount(() => {
		isMobile = isNativeMobile();

		// Check initial network status
		checkNetworkStatus().then((status) => {
			isOnline = status.connected;
		});

		// Listen for network changes
		unsubscribe = listenToNetworkChanges((connected) => {
			isOnline = connected;
		});

		return () => {
			unsubscribe?.();
		};
	});
</script>

<!-- 
	Mobile-aware layout wrapper
	This component handles:
	- Safe areas for notched devices (status bar, notch, etc.)
	- Mobile-specific styling
	- Network status indicator
-->

<div class="mobile-container" class:native-mobile={isMobile}>
	<!-- Status indicator for network -->
	{#if !isOnline}
		<div class="offline-banner">
			<p>⚠️ You are offline. Some features may not work correctly.</p>
		</div>
	{/if}

	<!-- Main content with safe area padding -->
	<div class="safe-area-wrapper">
		<slot />
	</div>
</div>

<style>
	:global(body.native-mobile) {
		padding-top: max(12px, env(safe-area-inset-top));
		padding-bottom: max(12px, env(safe-area-inset-bottom));
		padding-left: max(12px, env(safe-area-inset-left));
		padding-right: max(12px, env(safe-area-inset-right));
	}

	.mobile-container {
		display: flex;
		flex-direction: column;
		min-height: 100vh;
		width: 100%;
	}

	.mobile-container.native-mobile {
		/* Adjust for native status bar and notch */
		padding-top: max(12px, env(safe-area-inset-top));
		padding-bottom: max(12px, env(safe-area-inset-bottom));
	}

	.offline-banner {
		background-color: #dc2626;
		color: white;
		padding: 12px 16px;
		text-align: center;
		font-weight: 500;
		box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
	}

	.offline-banner p {
		margin: 0;
		font-size: 14px;
	}

	.safe-area-wrapper {
		flex: 1;
		display: flex;
		flex-direction: column;
		width: 100%;
	}
</style>
