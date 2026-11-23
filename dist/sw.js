const CACHE_NAME = 'pcm-cache-v1';
const ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/logo.png'
];

globalThis.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(ASSETS).catch(err => console.warn('PWA: caching assets failed on install:', err));
    })
  );
  globalThis.skipWaiting();
});

globalThis.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME) {
            return caches.delete(key);
          }
        })
      );
    })
  );
  globalThis.clients.claim();
});

globalThis.addEventListener('fetch', (event) => {
  // Pass through non-GET requests immediately
  if (event.request.method !== 'GET') {
    return;
  }

  // Network-first strategy with cache fallback
  event.respondWith(
    fetch(event.request)
      .then((response) => {
        // Cache valid basic GET requests, bypass Supabase data APIs and local hot-reloads
        if (
          response?.status === 200 &&
          response?.type === 'basic' &&
          !event.request.url.includes('supabase') &&
          !event.request.url.includes('chrome-extension') &&
          !event.request.url.includes('ws://')
        ) {
          const responseToCache = response.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(event.request, responseToCache);
          });
        }
        return response;
      })
      .catch(() => {
        // If network request fails, look up in cache
        return caches.match(event.request).then((cachedResponse) => {
          if (cachedResponse) {
            return cachedResponse;
          }
          return new Response('Network connection lost.', { status: 408, statusText: 'Network Connection Lost' });
        });
      })
  );
});
