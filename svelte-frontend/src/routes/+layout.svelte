<script>
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { browser } from '$app/environment';
	
	import Header from '$lib/components/Header.svelte';
	import Sidebar from '$lib/components/Sidebar.svelte';
	import NotificationToast from '$lib/components/NotificationToast.svelte';
	import { notificationStore } from '$lib/stores/simulations.js';
	import { connectionStore } from '$lib/stores/simulations.js';
	
	// Reactive state
	$: isDashboard = $page.url.pathname.startsWith('/dashboard');
	$: isFullscreen = $page.url.pathname === '/grid' || $page.url.pathname.startsWith('/grid/');
	
	// Initialize connection monitoring
	onMount(() => {
		if (browser) {
			// Monitor WebSocket connection
			const ws = new WebSocket(`${import.meta.env.VITE_WS_URL || 'ws://localhost:8080'}/ws`);
			
			ws.onopen = () => {
				connectionStore.setConnected(true);
				notificationStore.add({
					type: 'success',
					message: 'Connected to VoltEdge simulation engine',
					duration: 3000
				});
			};
			
			ws.onclose = () => {
				connectionStore.setConnected(false);
				notificationStore.add({
					type: 'error',
					message: 'Disconnected from simulation engine',
					duration: 5000
				});
			};
			
			ws.onerror = () => {
				connectionStore.setConnected(false);
				notificationStore.add({
					type: 'error',
					message: 'Connection error - check simulation engine',
					duration: 5000
				});
			};
			
			return () => {
				ws.close();
			};
		}
	});
</script>

<svelte:head>
	<title>VoltEdge - Energy Grid Simulator</title>
</svelte:head>

<div class="min-h-full bg-gray-50">
	{#if isFullscreen}
		<!-- Fullscreen grid view -->
		<main class="h-screen">
			<slot />
		</main>
	{:else}
		<!-- Standard layout with header and sidebar -->
		<div class="flex h-screen">
			<!-- Sidebar -->
			<Sidebar />
			
			<!-- Main content area -->
			<div class="flex-1 flex flex-col overflow-hidden">
				<!-- Header -->
				<Header />
				
				<!-- Page content -->
				<main class="flex-1 overflow-x-hidden overflow-y-auto bg-gray-50">
					<div class="container mx-auto px-6 py-8">
						<slot />
					</div>
				</main>
			</div>
		</div>
	{/if}
	
	<!-- Global notification toasts -->
	<NotificationToast />
</div>

<style>
	/* Global styles */
	:global(body) {
		@apply text-gray-900;
	}
	
	/* Custom scrollbar */
	:global(::-webkit-scrollbar) {
		@apply w-2;
	}
	
	:global(::-webkit-scrollbar-track) {
		@apply bg-gray-100;
	}
	
	:global(::-webkit-scrollbar-thumb) {
		@apply bg-gray-300 rounded-full;
	}
	
	:global(::-webkit-scrollbar-thumb:hover) {
		@apply bg-gray-400;
	}
	
	/* Focus styles */
	:global(*:focus) {
		@apply outline-none ring-2 ring-primary-500 ring-offset-2;
	}
	
	/* Animation utilities */
	.fade-in {
		animation: fadeIn 0.3s ease-in-out;
	}
	
	.slide-in {
		animation: slideIn 0.3s ease-out;
	}
	
	@keyframes fadeIn {
		from {
			opacity: 0;
		}
		to {
			opacity: 1;
		}
	}
	
	@keyframes slideIn {
		from {
			transform: translateY(-10px);
			opacity: 0;
		}
		to {
			transform: translateY(0);
			opacity: 1;
		}
	}
</style>
