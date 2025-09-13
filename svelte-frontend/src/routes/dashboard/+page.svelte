<script>
  import { onMount } from "svelte";
  import StatusCard from "$lib/components/StatusCard.svelte";
  import LoadingSpinner from "$lib/components/LoadingSpinner.svelte";
  import { simulationStore, simulations } from "$lib/stores/simulations.js";

  let mounted = false;
  let loading = true;
  let error = null;

  onMount(async () => {
    try {
      mounted = true;
      loading = true;
      await simulations.loadSimulations();
    } catch (err) {
      error = err.message || "Failed to load dashboard data";
      console.error("Dashboard error:", err);
    } finally {
      loading = false;
    }
  });
</script>

<svelte:head>
  <title>Dashboard - VoltEdge</title>
  <meta name="description" content="VoltEdge Energy Grid Simulator Dashboard" />
</svelte:head>

<div class="min-h-screen bg-gradient-to-br from-gray-50 to-blue-50">
  {#if loading}
    <div class="min-h-screen flex items-center justify-center">
      <LoadingSpinner size="xl" color="blue" text="Loading Dashboard..." />
    </div>
  {:else if error}
    <div class="min-h-screen flex items-center justify-center">
      <div class="text-center">
        <div
          class="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4"
        >
          <svg
            class="w-8 h-8 text-red-600"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
        </div>
        <h2 class="text-xl font-semibold text-gray-900 mb-2">
          Error Loading Dashboard
        </h2>
        <p class="text-gray-600 mb-4">{error}</p>
        <button
          on:click={() => window.location.reload()}
          class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
        >
          Retry
        </button>
      </div>
    </div>
  {:else if mounted}
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <!-- Page Header -->
      <div class="mb-8 text-center">
        <h1 class="text-4xl font-bold text-gray-900 mb-2">
          Energy Grid Dashboard
        </h1>
        <p class="text-xl text-gray-600">
          Real-time monitoring and simulation control
        </p>
      </div>

      <!-- Status Cards Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <StatusCard
          title="Total Generation"
          value="550"
          unit="MW"
          status="normal"
          trend="up"
          trendValue="+5.2%"
          icon={`<svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path></svg>`}
        />

        <StatusCard
          title="Grid Frequency"
          value="50.0"
          unit="Hz"
          status="normal"
          trend="stable"
          trendValue="±0.1"
          icon={`<svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z"></path></svg>`}
        />

        <StatusCard
          title="Active Simulations"
          value="3"
          status="normal"
          icon={`<svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path></svg>`}
        />

        <StatusCard
          title="System Health"
          value="99.8"
          unit="%"
          status="normal"
          trend="up"
          trendValue="+0.2%"
          icon={`<svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>`}
        />
      </div>

      <!-- Recent Simulations -->
      <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">
          Recent Simulations
        </h2>
        <div class="overflow-hidden">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                  >Name</th
                >
                <th
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                  >Status</th
                >
                <th
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                  >Created</th
                >
                <th
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                  >Actions</th
                >
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr>
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="text-sm font-medium text-gray-900">
                    Test Grid Simulation
                  </div>
                  <div class="text-sm text-gray-500">Demo energy grid</div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span
                    class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800"
                  >
                    Running
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  Just now
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                  <button class="text-blue-600 hover:text-blue-900 mr-4"
                    >View</button
                  >
                  <button class="text-gray-600 hover:text-gray-900">Stop</button
                  >
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  {:else}
    <div class="min-h-screen flex items-center justify-center">
      <div class="text-center">
        <div
          class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"
        />
        <p class="text-gray-600">Loading Dashboard...</p>
      </div>
    </div>
  {/if}
</div>
