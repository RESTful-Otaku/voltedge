<script>
  import { onMount } from "svelte";
  import { page } from "$app/stores";
  import { browser } from "$app/environment";

  import Header from "$lib/components/Header.svelte";
  import Sidebar from "$lib/components/Sidebar.svelte";
  import NotificationToast from "$lib/components/NotificationToast.svelte";
  import PerformanceMonitor from "$lib/components/PerformanceMonitor.svelte";
  import { notificationStore } from "$lib/stores/simulations.js";
  import { connectionStore } from "$lib/stores/simulations.js";

  // Reactive state
  $: isDashboard = $page.url.pathname.startsWith("/dashboard");
  $: isFullscreen =
    $page.url.pathname === "/grid" || $page.url.pathname.startsWith("/grid/");

  // Initialize connection monitoring
  onMount(() => {
    if (browser) {
      // Monitor WebSocket connection
      const ws = new WebSocket(
        `${import.meta.env.VITE_WS_URL || "ws://localhost:8080"}/ws`
      );

      ws.onopen = () => {
        connectionStore.setConnected(true);
        notificationStore.add({
          type: "success",
          message: "Connected to VoltEdge simulation engine",
          duration: 3000,
        });
      };

      ws.onclose = () => {
        connectionStore.setConnected(false);
        notificationStore.add({
          type: "error",
          message: "Disconnected from simulation engine",
          duration: 5000,
        });
      };

      ws.onerror = () => {
        connectionStore.setConnected(false);
        notificationStore.add({
          type: "error",
          message: "Connection error - check simulation engine",
          duration: 5000,
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

  <!-- Performance monitoring -->
  <PerformanceMonitor enabled={true} showMetrics={false} />
</div>

<style>
  /* Global styles */
  :global(body) {
    color: #111827;
  }

  /* Custom scrollbar */
  :global(::-webkit-scrollbar) {
    width: 0.5rem;
  }

  :global(::-webkit-scrollbar-track) {
    background-color: #f3f4f6;
  }

  :global(::-webkit-scrollbar-thumb) {
    background-color: #d1d5db;
    border-radius: 9999px;
  }

  :global(::-webkit-scrollbar-thumb:hover) {
    background-color: #9ca3af;
  }

  /* Focus styles */
  :global(*:focus) {
    outline: none;
    box-shadow: 0 0 0 2px #3b82f6, 0 0 0 4px rgba(59, 130, 246, 0.1);
  }

  /* Animation utilities - using Tailwind classes instead */

  /* Accessibility styles */
  :global(.sr-only) {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip: rect(0, 0, 0, 0);
    white-space: nowrap;
    border: 0;
  }

  :global(.visually-hidden) {
    position: absolute !important;
    width: 1px !important;
    height: 1px !important;
    padding: 0 !important;
    margin: -1px !important;
    overflow: hidden !important;
    clip: rect(0, 0, 0, 0) !important;
    white-space: nowrap !important;
    border: 0 !important;
  }

  /* Focus styles for better accessibility */
  :global(*:focus-visible) {
    outline: 2px solid #3b82f6;
    outline-offset: 2px;
  }

  /* Reduced motion support - handled by Tailwind CSS */
</style>
