<script>
  import { page } from "$app/stores";

  // Navigation items
  const navItems = [
    { href: "/", label: "Dashboard", icon: "dashboard" },
    { href: "/simulations", label: "Simulations", icon: "simulations" },
    { href: "/analytics", label: "Analytics", icon: "analytics" },
    { href: "/grid", label: "Grid View", icon: "grid" },
    { href: "/settings", label: "Settings", icon: "settings" },
  ];

  // Check if current route is active
  function isActive(href) {
    if (href === "/") {
      return $page.url.pathname === "/";
    }
    return $page.url.pathname.startsWith(href);
  }

  // Get icon SVG
  function getIcon(iconName) {
    const icons = {
      dashboard: `<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2H5a2 2 0 00-2-2z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 5a2 2 0 012-2h4a2 2 0 012 2v6H8V5z"></path></svg>`,
      simulations: `<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path></svg>`,
      analytics: `<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path></svg>`,
      grid: `<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"></path></svg>`,
      settings: `<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>`,
    };
    return icons[iconName] || icons.dashboard;
  }
</script>

<aside class="w-64 bg-white shadow-sm border-r border-gray-200 h-full">
  <div class="p-6">
    <!-- Logo -->
    <div class="flex items-center space-x-3 mb-8">
      <div
        class="w-10 h-10 bg-gradient-to-r from-blue-600 to-purple-600 rounded-lg flex items-center justify-center"
      >
        <span class="text-white font-bold">VE</span>
      </div>
      <div>
        <h2 class="text-lg font-bold text-gray-900">VoltEdge</h2>
        <p class="text-sm text-gray-500">Grid Simulator</p>
      </div>
    </div>

    <!-- Navigation -->
    <nav class="space-y-2">
      {#each navItems as item}
        <a
          href={item.href}
          class="flex items-center space-x-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors
						{isActive(item.href)
            ? 'bg-blue-50 text-blue-700 border-r-2 border-blue-700'
            : 'text-gray-700 hover:bg-gray-50 hover:text-gray-900'}"
        >
          <span class="flex-shrink-0" class:fill-current={isActive(item.href)}>
            {@html getIcon(item.icon)}
          </span>
          <span>{item.label}</span>
        </a>
      {/each}
    </nav>

    <!-- Quick Actions -->
    <div class="mt-8 pt-6 border-t border-gray-200">
      <h3
        class="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3"
      >
        Quick Actions
      </h3>
      <div class="space-y-2">
        <button
          class="w-full flex items-center space-x-3 px-3 py-2 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50 hover:text-gray-900 transition-colors"
        >
          <svg
            class="w-5 h-5"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M12 6v6m0 0v6m0-6h6m-6 0H6"
            />
          </svg>
          <span>New Simulation</span>
        </button>
        <button
          class="w-full flex items-center space-x-3 px-3 py-2 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50 hover:text-gray-900 transition-colors"
        >
          <svg
            class="w-5 h-5"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
            />
          </svg>
          <span>Import Grid</span>
        </button>
      </div>
    </div>

    <!-- System Status -->
    <div class="mt-8 pt-6 border-t border-gray-200">
      <h3
        class="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3"
      >
        System Status
      </h3>
      <div class="space-y-3">
        <div class="flex items-center justify-between">
          <span class="text-sm text-gray-600">Zig Engine</span>
          <div class="flex items-center space-x-1">
            <div class="w-2 h-2 bg-green-500 rounded-full" />
            <span class="text-xs text-green-600">Running</span>
          </div>
        </div>
        <div class="flex items-center justify-between">
          <span class="text-sm text-gray-600">API Gateway</span>
          <div class="flex items-center space-x-1">
            <div class="w-2 h-2 bg-green-500 rounded-full" />
            <span class="text-xs text-green-600">Healthy</span>
          </div>
        </div>
        <div class="flex items-center justify-between">
          <span class="text-sm text-gray-600">WebSocket</span>
          <div class="flex items-center space-x-1">
            <div class="w-2 h-2 bg-green-500 rounded-full" />
            <span class="text-xs text-green-600">Connected</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</aside>

<style>
  /* Additional styles if needed */
</style>
