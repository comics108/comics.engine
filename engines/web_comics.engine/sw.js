/**
 * Service Worker for Comics Viewer
 * Provides offline support for loaded comics
 */

const CACHE_NAME = 'comics-viewer-v1';
const STATIC_ASSETS = [
  './',
  './index.html',
  './src/comics-viewer.js',
  './src/comics-viewer.css',
  './src/models.js',
  './src/animation.js',
  './src/tile-loader.js',
  './src/sound-manager.js'
];

// Install - cache static assets
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(STATIC_ASSETS))
      .then(() => self.skipWaiting())
  );
});

// Activate - clean old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name !== CACHE_NAME)
          .map((name) => caches.delete(name))
      );
    }).then(() => self.clients.claim())
  );
});

// Fetch - serve from cache, fallback to network
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // Cache .comics files
  if (url.pathname.endsWith('.comics')) {
    event.respondWith(
      caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response) {
            return response;
          }

          return fetch(event.request).then((networkResponse) => {
            // Cache the comics file
            cache.put(event.request, networkResponse.clone());
            return networkResponse;
          });
        });
      })
    );
    return;
  }

  // Standard cache-first for static assets
  event.respondWith(
    caches.match(event.request).then((response) => {
      if (response) {
        return response;
      }

      return fetch(event.request).then((networkResponse) => {
        // Only cache same-origin requests
        if (url.origin === location.origin) {
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(event.request, networkResponse.clone());
          });
        }
        return networkResponse;
      });
    }).catch(() => {
      // Offline fallback
      if (event.request.mode === 'navigate') {
        return caches.match('./index.html');
      }
    })
  );
});

// Message handling for cache management
self.addEventListener('message', (event) => {
  if (event.data.type === 'CLEAR_CACHE') {
    caches.delete(CACHE_NAME).then(() => {
      event.ports[0].postMessage({ success: true });
    });
  }

  if (event.data.type === 'CACHE_COMICS') {
    const url = event.data.url;
    caches.open(CACHE_NAME).then((cache) => {
      fetch(url).then((response) => {
        cache.put(url, response);
        event.ports[0].postMessage({ success: true });
      }).catch(() => {
        event.ports[0].postMessage({ success: false });
      });
    });
  }
});
