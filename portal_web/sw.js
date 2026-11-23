const CACHE_NAME = 'pcm-wayanad-pwa-v28';
const PRECACHE_ASSETS = [
  './',
  './index.html',
  './200.html',
  './portal.html',
  './style.css',
  './logo.png',
  './logo-192.png',
  './logo-512.png',
  './favicon.ico',
  './apple-touch-icon.png',
  './manifest.json',
  './ants.js',
  './auth.js',
  './calculator.js',
  './portal.js',
  './before_after_slider.js',
  './router.js',
  './images/hero.jpg',
  './images/after.jpg',
  './images/before.jpg'
];

// Install: pre-cache application shell assets
self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(PRECACHE_ASSETS).catch((err) => {
        console.warn('Pre-cache notice (continuing):', err);
      });
    })
  );
});

// Activate: clean up previous caches immediately
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

// Fetch: network first with cache fallback
self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;

  const url = new URL(event.request.url);
  // Only cache local origin static requests
  if (url.origin !== self.location.origin) return;

  event.respondWith(
    fetch(event.request)
      .then((networkResponse) => {
        if (networkResponse && networkResponse.status === 200) {
          const responseClone = networkResponse.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(event.request, responseClone);
          });
        }
        return networkResponse;
      })
      .catch(async () => {
        const cachedResponse = await caches.match(event.request);
        if (cachedResponse) return cachedResponse;
        if (event.request.mode === 'navigate') {
          const indexMatch = await caches.match('./index.html');
          if (indexMatch) return indexMatch;
        }
        return new Response('Resource offline', {
          status: 503,
          headers: { 'Content-Type': 'text/plain' }
        });
      })
  );
});
