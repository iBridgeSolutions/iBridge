// Calendar Service Worker
const CACHE_NAME = 'calendar-cache-v1';
const OFFLINE_URL = '/offline.html';

const urlsToCache = [
  '/intranet/js/calendar-custom-loader.js',
  '/intranet/css/calendar-styles.css',
  '/data/mirrored/calendar-events.json',
  '/data/user-events.json',
  OFFLINE_URL
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(urlsToCache))
  );
});

self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => {
        if (response) {
          return response;
        }
        return fetch(event.request)
          .then(response => {
            if (!response || response.status !== 200 || response.type !== 'basic') {
              return response;
            }
            const responseToCache = response.clone();
            caches.open(CACHE_NAME)
              .then(cache => {
                cache.put(event.request, responseToCache);
              });
            return response;
          })
          .catch(() => {
            if (event.request.mode === 'navigate') {
              return caches.match(OFFLINE_URL);
            }
          });
      })
  );
});
