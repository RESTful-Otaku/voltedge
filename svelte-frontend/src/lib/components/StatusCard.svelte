<script>
	export let title = 'Status';
	export let value = '0';
	export let unit = '';
	export let status = 'normal'; // normal, warning, error
	export let icon = null;
	export let trend = null; // up, down, stable
	export let trendValue = null;
	
	// Status colors
	const statusColors = {
		normal: 'text-green-600 bg-green-100',
		warning: 'text-yellow-600 bg-yellow-100',
		error: 'text-red-600 bg-red-100'
	};
	
	// Trend colors
	const trendColors = {
		up: 'text-green-600',
		down: 'text-red-600',
		stable: 'text-gray-600'
	};
	
	// Get trend icon
	function getTrendIcon(trend) {
		if (trend === 'up') {
			return `<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 17l9.2-9.2M17 17V7H7"></path></svg>`;
		} else if (trend === 'down') {
			return `<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 7l-9.2 9.2M7 7v10h10"></path></svg>`;
		} else {
			return `<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 12h14"></path></svg>`;
		}
	}
	
	// Default icon if none provided
	const defaultIcon = `<svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path></svg>`;
	
	const displayIcon = icon || defaultIcon;
</script>

<div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow">
	<div class="flex items-start justify-between">
		<div class="flex-1">
			<!-- Title and Icon -->
			<div class="flex items-center space-x-3 mb-2">
				<div class="flex-shrink-0">
					{@html displayIcon}
				</div>
				<h3 class="text-sm font-medium text-gray-600">{title}</h3>
			</div>
			
			<!-- Value -->
			<div class="mb-2">
				<span class="text-2xl font-bold text-gray-900">{value}</span>
				{#if unit}
					<span class="text-sm text-gray-500 ml-1">{unit}</span>
				{/if}
			</div>
			
			<!-- Status Badge -->
			<div class="flex items-center justify-between">
				<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium {statusColors[status]}">
					{status.charAt(0).toUpperCase() + status.slice(1)}
				</span>
				
				<!-- Trend -->
				{#if trend && trendValue}
					<div class="flex items-center space-x-1 {trendColors[trend]}">
						<span class="text-xs">{@html getTrendIcon(trend)}</span>
						<span class="text-xs font-medium">{trendValue}</span>
					</div>
				{/if}
			</div>
		</div>
	</div>
</div>

<style>
	/* Additional styles if needed */
</style>

