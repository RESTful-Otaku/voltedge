<script>
  import { onMount } from "svelte";
  import { goto } from "$app/navigation";

  let mounted = false;
  let heroRef;

  onMount(() => {
    mounted = true;

    // Add entrance animations
    if (heroRef) {
      heroRef.style.opacity = "0";
      heroRef.style.transform = "translateY(20px)";

      setTimeout(() => {
        heroRef.style.transition = "all 0.8s cubic-bezier(0.4, 0, 0.2, 1)";
        heroRef.style.opacity = "1";
        heroRef.style.transform = "translateY(0)";
      }, 100);
    }
  });

  function handleStartSimulation() {
    goto("/simulations/new");
  }

  function handleViewDashboard() {
    goto("/dashboard");
  }
</script>

<section
  class="relative bg-gradient-to-br from-blue-50 via-white to-purple-50 py-20 overflow-hidden min-h-screen flex items-center"
>
  <!-- Animated Background Pattern -->
  <div class="absolute inset-0 opacity-10">
    <div
      class="absolute inset-0 bg-gradient-to-br from-blue-100 to-purple-100"
    />
    <!-- Floating particles -->
    <div
      class="absolute top-20 left-10 w-2 h-2 bg-blue-400 rounded-full animate-pulse"
    />
    <div
      class="absolute top-40 right-20 w-3 h-3 bg-purple-400 rounded-full animate-pulse delay-1000"
    />
    <div
      class="absolute bottom-40 left-20 w-1 h-1 bg-green-400 rounded-full animate-pulse delay-2000"
    />
    <div
      class="absolute bottom-20 right-10 w-2 h-2 bg-yellow-400 rounded-full animate-pulse delay-500"
    />
  </div>

  <div
    class="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8"
    bind:this={heroRef}
  >
    <div class="text-center">
      <!-- Badge with animation -->
      <div
        class="inline-flex items-center px-6 py-3 rounded-full text-sm font-medium bg-gradient-to-r from-blue-100 to-purple-100 text-blue-800 mb-8 shadow-lg hover:shadow-xl transition-all duration-300 transform hover:scale-105"
      >
        <svg
          class="w-4 h-4 mr-2 animate-spin"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M13 10V3L4 14h7v7l9-11h-7z"
          />
        </svg>
        Real-time Energy Grid Simulation
      </div>

      <!-- Main Heading -->
      <h1 class="text-4xl md:text-6xl font-bold text-gray-900 mb-6">
        <span
          class="bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent"
        >
          VoltEdge
        </span>
      </h1>

      <!-- Subtitle -->
      <p
        class="text-xl md:text-2xl text-gray-600 mb-8 max-w-3xl mx-auto leading-relaxed"
      >
        Advanced energy grid simulation platform with real-time monitoring,
        fault injection, and comprehensive analytics powered by Zig, Go, and
        Svelte.
      </p>

      <!-- Key Features -->
      <div
        class="grid grid-cols-1 md:grid-cols-3 gap-8 mb-12 max-w-4xl mx-auto"
      >
        <div class="text-center">
          <div
            class="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4"
          >
            <svg
              class="w-8 h-8 text-blue-600"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M13 10V3L4 14h7v7l9-11h-7z"
              />
            </svg>
          </div>
          <h3 class="text-lg font-semibold text-gray-900 mb-2">
            High Performance
          </h3>
          <p class="text-gray-600">
            Zig-powered simulation engine processing 100,000+ events per second
          </p>
        </div>

        <div class="text-center">
          <div
            class="w-16 h-16 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-4"
          >
            <svg
              class="w-8 h-8 text-purple-600"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
              />
            </svg>
          </div>
          <h3 class="text-lg font-semibold text-gray-900 mb-2">
            Real-time Analytics
          </h3>
          <p class="text-gray-600">
            Live monitoring and comprehensive grid health metrics
          </p>
        </div>

        <div class="text-center">
          <div
            class="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4"
          >
            <svg
              class="w-8 h-8 text-green-600"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"
              />
            </svg>
          </div>
          <h3 class="text-lg font-semibold text-gray-900 mb-2">
            Fault Injection
          </h3>
          <p class="text-gray-600">
            Test grid resilience with simulated failures and cyber attacks
          </p>
        </div>
      </div>

      <!-- CTA Buttons -->
      <div class="flex flex-col sm:flex-row gap-4 justify-center">
        <button
          on:click={handleStartSimulation}
          class="group bg-gradient-to-r from-blue-600 to-purple-600 text-white px-8 py-4 rounded-lg font-semibold hover:from-blue-700 hover:to-purple-700 transition-all duration-300 shadow-lg hover:shadow-xl transform hover:-translate-y-1 hover:scale-105"
        >
          <span class="flex items-center">
            <svg
              class="w-5 h-5 mr-2 group-hover:rotate-12 transition-transform duration-300"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M14.828 14.828a4 4 0 01-5.656 0M9 10h1m4 0h1m-6 4h1m4 0h1m-6-8h8a2 2 0 012 2v8a2 2 0 01-2 2H8a2 2 0 01-2-2V8a2 2 0 012-2z"
              />
            </svg>
            Start Simulation
          </span>
        </button>
        <button
          on:click={handleViewDashboard}
          class="group bg-white text-gray-700 px-8 py-4 rounded-lg font-semibold hover:bg-gray-50 transition-all duration-300 border border-gray-300 shadow-lg hover:shadow-xl transform hover:-translate-y-1 hover:scale-105"
        >
          <span class="flex items-center">
            <svg
              class="w-5 h-5 mr-2 group-hover:scale-110 transition-transform duration-300"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
              />
            </svg>
            View Dashboard
          </span>
        </button>
      </div>
    </div>
  </div>
</section>
