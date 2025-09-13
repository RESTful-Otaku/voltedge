<script>
  import { onMount } from "svelte";
  import {
    generateId,
    announceToScreenReader,
    keyboardNavigation,
    screenReader,
  } from "$lib/utils/accessibility.js";

  export let title = "Status";
  export let value = "0";
  export let unit = "";
  export let status = "normal"; // normal, warning, error
  export let icon = null;
  export let trend = null; // up, down, stable
  export let trendValue = null;
  export let animated = true;
  export let clickable = false;
  export let onClick = null;

  let cardRef;
  let mounted = false;
  let cardId = generateId("status-card");
  let isFocused = false;

  onMount(() => {
    mounted = true;

    // Add entrance animation
    if (cardRef && animated) {
      cardRef.style.opacity = "0";
      cardRef.style.transform = "translateY(20px) scale(0.95)";

      setTimeout(() => {
        cardRef.style.transition = "all 0.5s cubic-bezier(0.4, 0, 0.2, 1)";
        cardRef.style.opacity = "1";
        cardRef.style.transform = "translateY(0) scale(1)";
      }, Math.random() * 200); // Stagger animation
    }
  });

  // Status colors
  const statusColors = {
    normal: "text-green-600 bg-green-100 border-green-200",
    warning: "text-yellow-600 bg-yellow-100 border-yellow-200",
    error: "text-red-600 bg-red-100 border-red-200",
  };

  // Trend colors
  const trendColors = {
    up: "text-green-600",
    down: "text-red-600",
    stable: "text-gray-600",
  };

  // Get trend icon
  function getTrendIcon(trend) {
    if (trend === "up") {
      return `<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 17l9.2-9.2M17 17V7H7"></path></svg>`;
    } else if (trend === "down") {
      return `<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 7l-9.2 9.2M7 7v10h10"></path></svg>`;
    } else {
      return `<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 12h14"></path></svg>`;
    }
  }

  // Default icon if none provided
  const defaultIcon = `<svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path></svg>`;

  const displayIcon = icon || defaultIcon;

  // Handle click events
  function handleClick() {
    if (clickable && onClick) {
      onClick();
      announceToScreenReader(`${title} card activated`);
    }
  }

  // Handle keyboard events
  function handleKeydown(event) {
    keyboardNavigation.handleActivation(event, handleClick);
  }

  // Handle focus events
  function handleFocus() {
    isFocused = true;
  }

  function handleBlur() {
    isFocused = false;
  }

  // Generate accessible description
  $: accessibleDescription = `${title}: ${value}${
    unit ? ` ${unit}` : ""
  }, status: ${status}${
    trend && trendValue ? `, trend: ${trend} ${trendValue}` : ""
  }`;
</script>

<div
  bind:this={cardRef}
  id={cardId}
  role={clickable ? "button" : "region"}
  tabindex={clickable ? 0 : undefined}
  aria-label={accessibleDescription}
  aria-describedby={`${cardId}-description`}
  class="group bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-lg hover:shadow-blue-100/50 transition-all duration-300 transform hover:-translate-y-1 hover:scale-105 {clickable
    ? 'cursor-pointer focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2'
    : ''} {isFocused ? 'ring-2 ring-blue-500 ring-offset-2' : ''}"
  on:click={handleClick}
  on:keydown={handleKeydown}
  on:focus={handleFocus}
  on:blur={handleBlur}
>
  <div class="flex items-start justify-between">
    <div class="flex-1">
      <!-- Title and Icon -->
      <div class="flex items-center space-x-3 mb-3">
        <div
          class="flex-shrink-0 p-2 rounded-lg bg-gray-50 group-hover:bg-blue-50 transition-colors duration-300"
          aria-hidden="true"
        >
          {@html displayIcon}
        </div>
        <h3
          class="text-sm font-medium text-gray-600 group-hover:text-gray-900 transition-colors duration-300"
          id={`${cardId}-title`}
        >
          {title}
        </h3>
      </div>

      <!-- Value -->
      <div class="mb-3">
        <span
          class="text-3xl font-bold text-gray-900 group-hover:text-blue-600 transition-colors duration-300"
          id={`${cardId}-value`}>{value}</span
        >
        {#if unit}
          <span class="text-sm text-gray-500 ml-1" id={`${cardId}-unit`}
            >{unit}</span
          >
        {/if}
      </div>

      <!-- Status Badge -->
      <div class="flex items-center justify-between">
        <span
          class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium border {statusColors[
            status
          ]} group-hover:scale-105 transition-transform duration-300"
          id={`${cardId}-status`}
        >
          <div
            class="w-2 h-2 rounded-full bg-current mr-2 animate-pulse"
            aria-hidden="true"
          />
          {status.charAt(0).toUpperCase() + status.slice(1)}
        </span>

        <!-- Trend -->
        {#if trend && trendValue}
          <div
            class="flex items-center space-x-1 {trendColors[
              trend
            ]} group-hover:scale-110 transition-transform duration-300"
            id={`${cardId}-trend`}
          >
            <span class="text-xs" aria-hidden="true"
              >{@html getTrendIcon(trend)}</span
            >
            <span class="text-xs font-medium">{trendValue}</span>
          </div>
        {/if}
      </div>
    </div>
  </div>

  <!-- Screen reader description -->
  <div id={`${cardId}-description`} class="sr-only">
    {accessibleDescription}
  </div>
</div>

<style>
  /* Additional styles if needed */
</style>
