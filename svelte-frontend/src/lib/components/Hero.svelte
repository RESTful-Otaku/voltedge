<script>
	import { onMount } from 'svelte';
	
	let mounted = false;
	
	onMount(() => {
		mounted = true;
	});
</script>

<section class="relative bg-gradient-to-br from-blue-50 via-white to-purple-50 py-20 overflow-hidden">
	<!-- Background Pattern -->
	<div class="absolute inset-0 opacity-5">
		<div class="absolute inset-0 bg-gradient-to-br from-blue-100 to-purple-100"></div>
	</div>
	
	<div class="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		<div class="text-center">
			<!-- Badge -->
			<div class="inline-flex items-center px-4 py-2 rounded-full text-sm font-medium bg-blue-100 text-blue-800 mb-8">
				<svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
				</svg>
				Real-time Energy Grid Simulation
			</div>
			
			<!-- Main Heading -->
			<h1 class="text-4xl md:text-6xl font-bold text-gray-900 mb-6">
				<span class="bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
					VoltEdge
				</span>
			</h1>
			
			<!-- Subtitle -->
			<p class="text-xl md:text-2xl text-gray-600 mb-8 max-w-3xl mx-auto leading-relaxed">
				Advanced energy grid simulation platform with real-time monitoring, fault injection, and comprehensive analytics powered by Zig, Go, and Svelte.
			</p>
			
			<!-- Key Features -->
			<div class="grid grid-cols-1 md:grid-cols-3 gap-8 mb-12 max-w-4xl mx-auto">
				<div class="text-center">
					<div class="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
						<svg class="w-8 h-8 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
						</svg>
					</div>
					<h3 class="text-lg font-semibold text-gray-900 mb-2">High Performance</h3>
					<p class="text-gray-600">Zig-powered simulation engine processing 100,000+ events per second</p>
				</div>
				
				<div class="text-center">
					<div class="w-16 h-16 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-4">
						<svg class="w-8 h-8 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
						</svg>
					</div>
					<h3 class="text-lg font-semibold text-gray-900 mb-2">Real-time Analytics</h3>
					<p class="text-gray-600">Live monitoring and comprehensive grid health metrics</p>
				</div>
				
				<div class="text-center">
					<div class="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
						<svg class="w-8 h-8 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"></path>
						</svg>
					</div>
					<h3 class="text-lg font-semibold text-gray-900 mb-2">Fault Injection</h3>
					<p class="text-gray-600">Test grid resilience with simulated failures and cyber attacks</p>
				</div>
			</div>
			
			<!-- CTA Buttons -->
			<div class="flex flex-col sm:flex-row gap-4 justify-center">
				<button class="bg-blue-600 text-white px-8 py-4 rounded-lg font-semibold hover:bg-blue-700 transition-colors shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 transition-all">
					Start Simulation
				</button>
				<button class="bg-white text-gray-700 px-8 py-4 rounded-lg font-semibold hover:bg-gray-50 transition-colors border border-gray-300 shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 transition-all">
					View Dashboard
				</button>
			</div>
		</div>
	</div>
</section>