<script>
  import { onMount, onDestroy } from "svelte";
  import * as d3 from "d3";
  import { simulationStore } from "$stores/simulations";
  import { connectionStore } from "$stores/connection";

  export let simulationId;
  export let width = 800;
  export let height = 600;
  export let interactive = true;

  let svg;
  let container;
  let simulation;
  let zoom;
  let forceSimulation;
  let nodes = [];
  let links = [];
  let nodeElements;
  let linkElements;
  let labelElements;

  // Grid state
  let gridState = {
    totalGeneration: 0,
    totalConsumption: 0,
    frequency: 50.0,
    voltageLevels: [],
    activeFailures: [],
  };

  // Animation state
  let animationId;
  let isAnimating = false;

  // Color scales
  const plantTypeColors = {
    coal: "#374151",
    gas: "#f59e0b",
    nuclear: "#10b981",
    hydro: "#06b6d4",
    wind: "#8b5cf6",
    solar: "#f59e0b",
    battery: "#ef4444",
  };

  const statusColors = {
    healthy: "#10b981",
    warning: "#f59e0b",
    critical: "#ef4444",
    offline: "#6b7280",
  };

  onMount(() => {
    if (simulationId) {
      simulation = $simulationStore.simulations.find(
        (s) => s.id === simulationId
      );
      if (simulation) {
        initializeVisualization();
        startAnimation();
      }
    }

    // Subscribe to simulation updates
    const unsubscribe = simulationStore.subscribe((store) => {
      if (simulationId) {
        const updatedSimulation = store.simulations.find(
          (s) => s.id === simulationId
        );
        if (updatedSimulation && updatedSimulation !== simulation) {
          simulation = updatedSimulation;
          updateVisualization();
        }
      }
    });

    return unsubscribe;
  });

  onDestroy(() => {
    if (animationId) {
      cancelAnimationFrame(animationId);
    }
    if (forceSimulation) {
      forceSimulation.stop();
    }
  });

  function initializeVisualization() {
    if (!simulation || !container) return;

    // Clear previous visualization
    d3.select(container).selectAll("*").remove();

    // Create SVG
    svg = d3
      .select(container)
      .append("svg")
      .attr("width", width)
      .attr("height", height)
      .attr("viewBox", [0, 0, width, height])
      .style("background", "#f9fafb");

    // Set up zoom behavior
    zoom = d3
      .zoom()
      .scaleExtent([0.1, 10])
      .on("zoom", (event) => {
        if (interactive) {
          svg.select(".zoom-group").attr("transform", event.transform);
        }
      });

    svg.call(zoom);

    // Create main group for zoomable content
    const zoomGroup = svg.append("g").attr("class", "zoom-group");

    // Convert simulation data to D3 format
    convertDataToD3();

    // Create force simulation
    forceSimulation = d3
      .forceSimulation(nodes)
      .force(
        "link",
        d3
          .forceLink(links)
          .id((d) => d.id)
          .distance(100)
      )
      .force("charge", d3.forceManyBody().strength(-300))
      .force("center", d3.forceCenter(width / 2, height / 2))
      .force("collision", d3.forceCollide().radius(30));

    // Create link elements
    linkElements = zoomGroup
      .append("g")
      .attr("class", "links")
      .selectAll("line")
      .data(links)
      .join("line")
      .attr("stroke", "#d1d5db")
      .attr("stroke-width", 2)
      .attr("stroke-opacity", 0.6);

    // Create node elements
    nodeElements = zoomGroup
      .append("g")
      .attr("class", "nodes")
      .selectAll("circle")
      .data(nodes)
      .join("circle")
      .attr("r", (d) => getNodeRadius(d))
      .attr("fill", (d) => getNodeColor(d))
      .attr("stroke", "#ffffff")
      .attr("stroke-width", 2)
      .style("cursor", interactive ? "pointer" : "default")
      .on("click", interactive ? handleNodeClick : null)
      .on("mouseover", interactive ? handleNodeHover : null)
      .on("mouseout", interactive ? handleNodeLeave : null);

    // Create labels
    labelElements = zoomGroup
      .append("g")
      .attr("class", "labels")
      .selectAll("text")
      .data(nodes)
      .join("text")
      .attr("dx", 0)
      .attr("dy", (d) => getNodeRadius(d) + 15)
      .attr("text-anchor", "middle")
      .attr("font-size", "12px")
      .attr("font-weight", "500")
      .attr("fill", "#374151")
      .text((d) => d.name);

    // Update positions on tick
    forceSimulation.on("tick", () => {
      linkElements
        .attr("x1", (d) => d.source.x)
        .attr("y1", (d) => d.source.y)
        .attr("x2", (d) => d.target.x)
        .attr("y2", (d) => d.target.y);

      nodeElements.attr("cx", (d) => d.x).attr("cy", (d) => d.y);

      labelElements.attr("x", (d) => d.x).attr("y", (d) => d.y);
    });
  }

  function convertDataToD3() {
    // Convert power plants to nodes
    nodes = simulation.config.power_plants.map((plant) => ({
      id: plant.id,
      name: plant.name,
      type: "power_plant",
      plantType: plant.type,
      x: plant.location.x * width,
      y: plant.location.y * height,
      capacity: plant.max_capacity_mw,
      output: plant.current_output_mw,
      operational: plant.is_operational,
      fixed: true, // Keep plants in fixed positions
    }));

    // Convert transmission lines to links
    links = simulation.config.transmission_lines.map((line) => ({
      source: line.from_node,
      target: line.to_node,
      id: line.id,
      capacity: line.capacity_mw,
      length: line.length_km,
      operational: line.is_operational,
    }));
  }

  function updateVisualization() {
    if (!nodeElements || !linkElements) return;

    // Update node data
    nodeElements
      .data(nodes)
      .attr("r", (d) => getNodeRadius(d))
      .attr("fill", (d) => getNodeColor(d));

    // Update link data
    linkElements
      .data(links)
      .attr("stroke", (d) => getLinkColor(d))
      .attr("stroke-width", (d) => getLinkWidth(d));

    // Restart force simulation
    forceSimulation.nodes(nodes);
    forceSimulation.force("link").links(links);
    forceSimulation.alpha(0.3).restart();
  }

  function getNodeRadius(d) {
    // Base radius on capacity
    const baseRadius = Math.max(8, Math.min(20, d.capacity / 100));
    return baseRadius;
  }

  function getNodeColor(d) {
    if (!d.operational) return statusColors.offline;

    const plantColor = plantTypeColors[d.plantType] || "#6b7280";

    // Add pulsing effect for active plants
    if (d.output > 0 && isAnimating) {
      return d3.color(plantColor).brighter(0.3);
    }

    return plantColor;
  }

  function getLinkColor(d) {
    if (!d.operational) return statusColors.offline;

    // Color based on utilization (simplified)
    const utilization = Math.random(); // In real app, this would come from grid state

    if (utilization > 0.8) return statusColors.critical;
    if (utilization > 0.6) return statusColors.warning;
    return statusColors.healthy;
  }

  function getLinkWidth(d) {
    // Width based on capacity
    return Math.max(1, Math.min(6, d.capacity / 50));
  }

  function startAnimation() {
    if (isAnimating) return;

    isAnimating = true;

    function animate() {
      if (!isAnimating) return;

      // Update grid state (in real app, this would come from WebSocket)
      updateGridState();

      // Update visualization
      updateVisualization();

      animationId = requestAnimationFrame(animate);
    }

    animate();
  }

  function stopAnimation() {
    isAnimating = false;
    if (animationId) {
      cancelAnimationFrame(animationId);
    }
  }

  function updateGridState() {
    // Simulate real-time updates
    gridState.totalGeneration = simulation.config.power_plants.reduce(
      (sum, plant) => sum + (plant.current_output_mw || 0),
      0
    );

    gridState.totalConsumption =
      gridState.totalGeneration * (0.8 + Math.random() * 0.4);
    gridState.frequency = 50.0 + (Math.random() - 0.5) * 2;

    // Update plant outputs (simulate real-time changes)
    simulation.config.power_plants.forEach((plant) => {
      if (plant.is_operational) {
        plant.current_output_mw = Math.max(
          0,
          plant.current_output_mw + (Math.random() - 0.5) * 10
        );
        plant.current_output_mw = Math.min(
          plant.current_output_mw,
          plant.max_capacity_mw
        );
      }
    });
  }

  function handleNodeClick(event, d) {
    console.log("Node clicked:", d);
    // Emit event or handle node selection
  }

  function handleNodeHover(event, d) {
    // Show tooltip or highlight
    d3.select(event.target)
      .transition()
      .duration(200)
      .attr("r", getNodeRadius(d) * 1.2);
  }

  function handleNodeLeave(event, d) {
    // Hide tooltip or remove highlight
    d3.select(event.target)
      .transition()
      .duration(200)
      .attr("r", getNodeRadius(d));
  }

  // Expose methods for parent components
  export function startSimulation() {
    startAnimation();
  }

  export function stopSimulation() {
    stopAnimation();
  }

  export function resetView() {
    if (zoom && svg) {
      svg.transition().duration(750).call(zoom.transform, d3.zoomIdentity);
    }
  }
</script>

<div class="grid-visualization">
  <!-- Controls -->
  <div class="flex items-center justify-between mb-4">
    <div class="flex items-center space-x-4">
      <div class="flex items-center space-x-2">
        <div
          class="w-3 h-3 rounded-full {connectionStore.connected
            ? 'bg-green-500'
            : 'bg-red-500'}"
        />
        <span class="text-sm text-gray-600">
          {connectionStore.connected ? "Connected" : "Disconnected"}
        </span>
      </div>

      {#if simulation}
        <div class="text-sm text-gray-600">
          Status: <span class="font-medium">{simulation.status}</span>
        </div>
      {/if}
    </div>

    <div class="flex items-center space-x-2">
      <button
        on:click={resetView}
        class="px-3 py-1 text-sm bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors"
      >
        Reset View
      </button>

      {#if isAnimating}
        <button
          on:click={stopSimulation}
          class="px-3 py-1 text-sm bg-red-100 text-red-700 hover:bg-red-200 rounded-lg transition-colors"
        >
          Stop
        </button>
      {:else}
        <button
          on:click={startSimulation}
          class="px-3 py-1 text-sm bg-green-100 text-green-700 hover:bg-green-200 rounded-lg transition-colors"
        >
          Start
        </button>
      {/if}
    </div>
  </div>

  <!-- Grid State Info -->
  <div
    class="grid grid-cols-4 gap-4 mb-4 p-4 bg-white rounded-lg border border-gray-200"
  >
    <div class="text-center">
      <div class="text-2xl font-bold text-green-600">
        {gridState.totalGeneration.toFixed(1)}
      </div>
      <div class="text-sm text-gray-600">Generation (MW)</div>
    </div>
    <div class="text-center">
      <div class="text-2xl font-bold text-blue-600">
        {gridState.totalConsumption.toFixed(1)}
      </div>
      <div class="text-sm text-gray-600">Consumption (MW)</div>
    </div>
    <div class="text-center">
      <div class="text-2xl font-bold text-purple-600">
        {gridState.frequency.toFixed(2)}
      </div>
      <div class="text-sm text-gray-600">Frequency (Hz)</div>
    </div>
    <div class="text-center">
      <div class="text-2xl font-bold text-orange-600">
        {gridState.activeFailures.length}
      </div>
      <div class="text-sm text-gray-600">Active Failures</div>
    </div>
  </div>

  <!-- Visualization Container -->
  <div class="bg-white rounded-lg border border-gray-200 overflow-hidden">
    <div bind:this={container} class="w-full h-full" />
  </div>

  <!-- Legend -->
  <div class="mt-4 p-4 bg-white rounded-lg border border-gray-200">
    <h3 class="font-semibold text-gray-900 mb-3">Legend</h3>
    <div class="grid grid-cols-2 gap-4">
      <div>
        <h4 class="text-sm font-medium text-gray-700 mb-2">
          Power Plant Types
        </h4>
        <div class="space-y-1">
          {#each Object.entries(plantTypeColors) as [type, color]}
            <div class="flex items-center space-x-2">
              <div
                class="w-4 h-4 rounded-full"
                style="background-color: {color}"
              />
              <span class="text-sm text-gray-600 capitalize">{type}</span>
            </div>
          {/each}
        </div>
      </div>
      <div>
        <h4 class="text-sm font-medium text-gray-700 mb-2">Status</h4>
        <div class="space-y-1">
          {#each Object.entries(statusColors) as [status, color]}
            <div class="flex items-center space-x-2">
              <div
                class="w-4 h-4 rounded-full"
                style="background-color: {color}"
              />
              <span class="text-sm text-gray-600 capitalize">{status}</span>
            </div>
          {/each}
        </div>
      </div>
    </div>
  </div>
</div>

<style>
  .grid-visualization {
    @apply w-full;
  }

  :global(.grid-visualization .zoom-group) {
    transition: transform 0.3s ease;
  }

  :global(.grid-visualization .nodes circle) {
    transition: all 0.3s ease;
  }

  :global(.grid-visualization .links line) {
    transition: all 0.3s ease;
  }
</style>
