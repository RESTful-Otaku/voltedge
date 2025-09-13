// VoltEdge Service Worker for Performance Optimization
const CACHE_NAME = "voltedge-v1.0.0";
const STATIC_CACHE = "voltedge-static-v1.0.0";
const DYNAMIC_CACHE = "voltedge-dynamic-v1.0.0";

// Assets to cache immediately
const STATIC_ASSETS = ["/", "/dashboard", "/manifest.json", "/favicon.ico"];

// Install event - cache static assets
self.addEventListener("install", (event) => {
  console.log("[ServiceWorker] Install");

  event.waitUntil(
    caches
      .open(STATIC_CACHE)
      .then((cache) => {
        console.log("[ServiceWorker] Caching static assets");
        return cache.addAll(STATIC_ASSETS);
      })
      .then(() => {
        console.log("[ServiceWorker] Static assets cached");
        return self.skipWaiting();
      })
  );
});

// Activate event - clean up old caches
self.addEventListener("activate", (event) => {
  console.log("[ServiceWorker] Activate");

  event.waitUntil(
    caches
      .keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => {
            if (cacheName !== STATIC_CACHE && cacheName !== DYNAMIC_CACHE) {
              console.log("[ServiceWorker] Deleting old cache:", cacheName);
              return caches.delete(cacheName);
            }
          })
        );
      })
      .then(() => {
        console.log("[ServiceWorker] Claiming clients");
        return self.clients.claim();
      })
  );
});

// Fetch event - serve from cache with network fallback
self.addEventListener("fetch", (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Skip non-GET requests
  if (request.method !== "GET") {
    return;
  }

  // Skip external requests
  if (url.origin !== location.origin) {
    return;
  }

  event.respondWith(
    caches.match(request).then((cachedResponse) => {
      // Return cached version if available
      if (cachedResponse) {
        console.log("[ServiceWorker] Serving from cache:", request.url);
        return cachedResponse;
      }

      // Otherwise fetch from network
      return fetch(request)
        .then((response) => {
          // Don't cache non-successful responses
          if (
            !response ||
            response.status !== 200 ||
            response.type !== "basic"
          ) {
            return response;
          }

          // Clone the response
          const responseToCache = response.clone();

          // Cache dynamic content
          caches.open(DYNAMIC_CACHE).then((cache) => {
            console.log(
              "[ServiceWorker] Caching dynamic content:",
              request.url
            );
            cache.put(request, responseToCache);
          });

          return response;
        })
        .catch((error) => {
          console.log("[ServiceWorker] Fetch failed:", error);

          // Return offline page for navigation requests
          if (request.mode === "navigate") {
            return (
              caches.match("/offline.html") ||
              new Response(
                "<h1>Offline</h1><p>Please check your internet connection.</p>",
                { headers: { "Content-Type": "text/html" } }
              )
            );
          }

          throw error;
        });
    })
  );
});

// Background sync for offline data
self.addEventListener("sync", (event) => {
  console.log("[ServiceWorker] Background sync:", event.tag);

  if (event.tag === "simulation-sync") {
    event.waitUntil(syncSimulations());
  }
});

// Push notifications
self.addEventListener("push", (event) => {
  console.log("[ServiceWorker] Push received");

  const options = {
    body: event.data ? event.data.text() : "New simulation update available",
    icon: "/icon-192x192.png",
    badge: "/badge-72x72.png",
    vibrate: [100, 50, 100],
    data: {
      dateOfArrival: Date.now(),
      primaryKey: 1,
    },
    actions: [
      {
        action: "explore",
        title: "View Dashboard",
        icon: "/icon-192x192.png",
      },
      {
        action: "close",
        title: "Close",
        icon: "/icon-192x192.png",
      },
    ],
  };

  event.waitUntil(
    self.registration.showNotification("VoltEdge Update", options)
  );
});

// Notification click handler
self.addEventListener("notificationclick", (event) => {
  console.log("[ServiceWorker] Notification click received");

  event.notification.close();

  if (event.action === "explore") {
    event.waitUntil(clients.openWindow("/dashboard"));
  }
});

// Helper function to sync simulations when back online
async function syncSimulations() {
  try {
    console.log("[ServiceWorker] Syncing simulations...");

    // Get pending simulations from IndexedDB
    const pendingSimulations = await getPendingSimulations();

    for (const simulation of pendingSimulations) {
      try {
        await fetch("/api/simulations", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify(simulation),
        });

        // Remove from pending list
        await removePendingSimulation(simulation.id);
      } catch (error) {
        console.error("[ServiceWorker] Failed to sync simulation:", error);
      }
    }

    console.log("[ServiceWorker] Simulation sync completed");
  } catch (error) {
    console.error("[ServiceWorker] Sync failed:", error);
  }
}

// IndexedDB helpers (simplified)
async function getPendingSimulations() {
  // Implementation would use IndexedDB
  return [];
}

async function removePendingSimulation(id) {
  // Implementation would use IndexedDB
  console.log("[ServiceWorker] Removing pending simulation:", id);
}
