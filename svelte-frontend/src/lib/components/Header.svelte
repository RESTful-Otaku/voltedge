<script>
	import { onMount } from 'svelte';
	
	let mounted = false;
	
	onMount(() => {
		mounted = true;
	});
</script>

<header class="bg-white shadow-sm border-b border-gray-200">
	<div class="max-w-7xl mx-auto px-6">
		<div class="flex items-center justify-between h-16">
			<!-- Logo and title -->
			<div class="flex items-center space-x-4">
				<div class="flex items-center space-x-2">
					<div class="w-8 h-8 bg-gradient-to-r from-blue-600 to-purple-600 rounded-lg flex items-center justify-center">
						<span class="text-white font-bold text-sm">VE</span>
					</div>
					<h1 class="text-xl font-bold text-gray-900">VoltEdge</h1>
				</div>
				<span class="text-sm text-gray-500 hidden md:block">Energy Grid Simulator</span>
			</div>
			
			<!-- Navigation -->
			<nav class="hidden md:flex items-center space-x-8">
				<a href="/" class="text-gray-700 hover:text-blue-600 font-medium transition-colors">Dashboard</a>
				<a href="/simulations" class="text-gray-700 hover:text-blue-600 font-medium transition-colors">Simulations</a>
				<a href="/analytics" class="text-gray-700 hover:text-blue-600 font-medium transition-colors">Analytics</a>
				<a href="/grid" class="text-gray-700 hover:text-blue-600 font-medium transition-colors">Grid View</a>
			</nav>
			
			<!-- Status and actions -->
			<div class="flex items-center space-x-4">
				<!-- Connection status -->
				<div class="flex items-center space-x-2">
					<div class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
					<span class="text-sm text-gray-600 hidden sm:block">Connected</span>
				</div>
				
				<!-- Settings button -->
				<button class="p-2 text-gray-400 hover:text-gray-600 transition-colors">
					<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
					</svg>
				</button>
			</div>
		</div>
	</div>
</header>

<!-- Mobile navigation -->
<div class="md:hidden bg-white border-b border-gray-200">
	<div class="px-6 py-4">
		<nav class="flex space-x-6">
			<a href="/" class="text-gray-700 hover:text-blue-600 font-medium">Dashboard</a>
			<a href="/simulations" class="text-gray-700 hover:text-blue-600 font-medium">Simulations</a>
			<a href="/analytics" class="text-gray-700 hover:text-blue-600 font-medium">Analytics</a>
			<a href="/grid" class="text-gray-700 hover:text-blue-600 font-medium">Grid</a>
		</nav>
	</div>
</div>

<style>
	/* Additional styles if needed */
</style>

