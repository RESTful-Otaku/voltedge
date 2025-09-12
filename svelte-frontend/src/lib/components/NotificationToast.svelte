<script>
	import { notificationStore, notifications } from '$lib/stores/simulations.js';
	
	// Auto-dismiss duration
	const AUTO_DISMISS_DURATION = 5000;
	
	// Handle notification click
	function handleClick(notification) {
		if (notification.onClick) {
			notification.onClick();
		}
		notifications.remove(notification.id);
	}
	
	// Handle close button click
	function handleClose(notification) {
		notifications.remove(notification.id);
	}
</script>

<!-- Notification Container -->
<div class="fixed top-4 right-4 z-50 space-y-2">
	{#each $notificationStore.notifications as notification (notification.id)}
		<div class="max-w-sm w-full bg-white shadow-lg rounded-lg pointer-events-auto ring-1 ring-black ring-opacity-5 overflow-hidden
			{notification.type === 'success' ? 'border-l-4 border-green-400' :
			 notification.type === 'error' ? 'border-l-4 border-red-400' :
			 notification.type === 'warning' ? 'border-l-4 border-yellow-400' :
			 'border-l-4 border-blue-400'}">
			
			<div class="p-4">
				<div class="flex items-start">
					<!-- Icon -->
					<div class="flex-shrink-0">
						{#if notification.type === 'success'}
							<svg class="h-6 w-6 text-green-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
							</svg>
						{:else if notification.type === 'error'}
							<svg class="h-6 w-6 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
							</svg>
						{:else if notification.type === 'warning'}
							<svg class="h-6 w-6 text-yellow-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
							</svg>
						{:else}
							<svg class="h-6 w-6 text-blue-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
							</svg>
						{/if}
					</div>
					
					<!-- Content -->
					<div class="ml-3 w-0 flex-1 pt-0.5">
						{#if notification.title}
							<p class="text-sm font-medium text-gray-900">{notification.title}</p>
						{/if}
						{#if notification.message}
							<p class="mt-1 text-sm text-gray-500">{notification.message}</p>
						{/if}
						
						<!-- Actions -->
						{#if notification.actions && notification.actions.length > 0}
							<div class="mt-3 flex space-x-2">
								{#each notification.actions as action}
									<button
										on:click={() => action.onClick && action.onClick()}
										class="text-sm font-medium text-blue-600 hover:text-blue-500 focus:outline-none focus:underline"
									>
										{action.label}
									</button>
								{/each}
							</div>
						{/if}
					</div>
					
					<!-- Close Button -->
					<div class="ml-4 flex-shrink-0 flex">
						<button
							on:click={() => handleClose(notification)}
							class="bg-white rounded-md inline-flex text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
						>
							<span class="sr-only">Close</span>
							<svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
								<path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
							</svg>
						</button>
					</div>
				</div>
			</div>
			
			<!-- Progress Bar (for auto-dismiss) -->
			{#if notification.duration && notification.duration > 0}
				<div class="h-1 bg-gray-200">
					<div class="h-1 bg-gray-400 animate-progress" style="animation-duration: {notification.duration}ms;"></div>
				</div>
			{/if}
		</div>
	{/each}
</div>

<style>
	@keyframes progress {
		from {
			width: 100%;
		}
		to {
			width: 0%;
		}
	}
	
	.animate-progress {
		animation: progress linear;
	}
</style>

