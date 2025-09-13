<script>
  import { onMount, onDestroy } from "svelte";

  export let enabled = true;
  export let showMetrics = false;

  let performanceData = {
    fps: 0,
    memoryUsage: 0,
    loadTime: 0,
    renderTime: 0,
  };

  let frameCount = 0;
  let lastTime = performance.now();
  let animationId;

  // Performance monitoring
  function measurePerformance() {
    if (!enabled) return;

    const now = performance.now();
    frameCount++;

    // Calculate FPS
    if (now - lastTime >= 1000) {
      performanceData.fps = Math.round((frameCount * 1000) / (now - lastTime));
      frameCount = 0;
      lastTime = now;
    }

    // Memory usage (if available)
    if (performance.memory) {
      performanceData.memoryUsage = Math.round(
        performance.memory.usedJSHeapSize / 1024 / 1024
      );
    }

    // Page load time
    if (performance.timing) {
      performanceData.loadTime =
        performance.timing.loadEventEnd - performance.timing.navigationStart;
    }

    animationId = requestAnimationFrame(measurePerformance);
  }

  onMount(() => {
    if (enabled) {
      measurePerformance();
    }
  });

  onDestroy(() => {
    if (animationId) {
      cancelAnimationFrame(animationId);
    }
  });

  // Performance status based on metrics
  $: performanceStatus = (() => {
    if (performanceData.fps < 30) return "poor";
    if (performanceData.fps < 50) return "fair";
    if (performanceData.memoryUsage > 100) return "warning";
    return "good";
  })();

  $: statusColor = {
    good: "text-green-600 bg-green-100",
    fair: "text-yellow-600 bg-yellow-100",
    warning: "text-orange-600 bg-orange-100",
    poor: "text-red-600 bg-red-100",
  }[performanceStatus];
</script>

{#if showMetrics}
  <div
    class="fixed bottom-4 right-4 bg-white rounded-lg shadow-lg border border-gray-200 p-4 z-50"
  >
    <div class="flex items-center justify-between mb-2">
      <h3 class="text-sm font-semibold text-gray-900">Performance</h3>
      <span
        class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium {statusColor}"
      >
        {performanceStatus}
      </span>
    </div>

    <div class="space-y-1 text-xs text-gray-600">
      <div class="flex justify-between">
        <span>FPS:</span>
        <span class="font-mono">{performanceData.fps}</span>
      </div>
      <div class="flex justify-between">
        <span>Memory:</span>
        <span class="font-mono">{performanceData.memoryUsage}MB</span>
      </div>
      <div class="flex justify-between">
        <span>Load Time:</span>
        <span class="font-mono">{performanceData.loadTime}ms</span>
      </div>
    </div>
  </div>
{/if}

<!-- Performance indicator (always visible when enabled) -->
{#if enabled && !showMetrics}
  <div
    class="fixed bottom-4 right-4 w-3 h-3 rounded-full {statusColor} z-50"
    title="Performance: {performanceStatus} (FPS: {performanceData.fps})"
  />
{/if}
