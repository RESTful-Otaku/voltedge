<script>
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	
	import Hero from '$lib/components/Hero.svelte';
	import FeatureGrid from '$lib/components/FeatureGrid.svelte';
	import TechnologyStack from '$lib/components/TechnologyStack.svelte';
	import { simulationStore } from '$lib/stores/simulations.js';
	
	// Load recent simulations on mount
	onMount(async () => {
		try {
			await simulationStore.loadSimulations();
		} catch (error) {
			console.error('Failed to load simulations:', error);
		}
	});
</script>

<svelte:head>
	<title>VoltEdge - Real-Time Energy Grid Simulator</title>
	<meta name="description" content="Advanced energy grid simulation platform with real-time monitoring, fault injection, and comprehensive analytics." />
</svelte:head>

<div class="space-y-16">
	<!-- Hero Section -->
	<Hero />
	
	<!-- Features Grid -->
	<FeatureGrid />
	
	<!-- Technology Stack -->
	<TechnologyStack />
	
	<!-- Quick Actions -->
	<section class="bg-white rounded-xl shadow-sm border border-gray-200 p-8">
		<div class="text-center">
			<h2 class="text-2xl font-bold text-gray-900 mb-4">Ready to Start Simulating?</h2>
			<p class="text-gray-600 mb-8 max-w-2xl mx-auto">
				Create your first energy grid simulation and explore the power of real-time grid modeling, 
				fault injection, and comprehensive analytics.
			</p>
			
			<div class="flex flex-col sm:flex-row gap-4 justify-center">
				<button
					on:click={() => goto('/simulations/new')}
					class="bg-primary-600 text-white px-8 py-3 rounded-lg font-semibold hover:bg-primary-700 transition-colors shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 transition-all"
				>
					Create New Simulation
				</button>
				
				<button
					on:click={() => goto('/dashboard')}
					class="bg-gray-100 text-gray-700 px-8 py-3 rounded-lg font-semibold hover:bg-gray-200 transition-colors border border-gray-300"
				>
					View Dashboard
				</button>
			</div>
		</div>
	</section>
	
	<!-- Recent Simulations -->
	{#if $simulationStore.simulations.length > 0}
		<section class="bg-white rounded-xl shadow-sm border border-gray-200 p-8">
			<div class="flex items-center justify-between mb-6">
				<h2 class="text-2xl font-bold text-gray-900">Recent Simulations</h2>
				<button
					on:click={() => goto('/simulations')}
					class="text-primary-600 hover:text-primary-700 font-medium"
				>
					View All →
				</button>
			</div>
			
			<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
				{#each $simulationStore.simulations.slice(0, 6) as simulation}
					<div class="border border-gray-200 rounded-lg p-6 hover:shadow-md transition-shadow cursor-pointer"
						 on:click={() => goto(`/simulations/${simulation.id}`)}>
						<div class="flex items-start justify-between mb-3">
							<h3 class="font-semibold text-gray-900 truncate">{simulation.name}</h3>
							<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium
								{simulation.status === 'running' ? 'bg-green-100 text-green-800' : 
								 simulation.status === 'paused' ? 'bg-yellow-100 text-yellow-800' : 
								 simulation.status === 'error' ? 'bg-red-100 text-red-800' : 
								 'bg-gray-100 text-gray-800'}">
								{simulation.status}
							</span>
						</div>
						
						{#if simulation.description}
							<p class="text-gray-600 text-sm mb-3 line-clamp-2">{simulation.description}</p>
						{/if}
						
						<div class="flex items-center justify-between text-sm text-gray-500">
							<span>{simulation.config.power_plants.length} power plants</span>
							<span>{new Date(simulation.created_at).toLocaleDateString()}</span>
						</div>
					</div>
				{/each}
			</div>
		</section>
	{/if}
</div>

<style>
	.line-clamp-2 {
		display: -webkit-box;
		-webkit-line-clamp: 2;
		-webkit-box-orient: vertical;
		overflow: hidden;
	}
</style>
