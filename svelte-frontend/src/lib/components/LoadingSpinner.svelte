<script>
  export let size = "md";
  export let color = "blue";
  export let text = "Loading...";

  const sizeClasses = {
    sm: "w-4 h-4",
    md: "w-8 h-8",
    lg: "w-12 h-12",
    xl: "w-16 h-16",
  };

  const colorClasses = {
    blue: "text-blue-600",
    green: "text-green-600",
    purple: "text-purple-600",
    gray: "text-gray-600",
  };
</script>

<div class="flex flex-col items-center justify-center space-y-4">
  <div class="relative">
    <div
      class="animate-spin rounded-full border-4 border-gray-200 {sizeClasses[
        size
      ]}"
    />
    <div
      class="animate-spin rounded-full border-4 border-t-transparent {colorClasses[
        color
      ]} {sizeClasses[size]} absolute top-0 left-0"
    />
  </div>
  {#if text}
    <p class="text-sm text-gray-600 animate-pulse">{text}</p>
  {/if}
</div>
