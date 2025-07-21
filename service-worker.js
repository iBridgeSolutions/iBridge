const CACHE_NAME = 'ibridge-cache-v1';
const ASSETS_TO_CACHE = [
    '/',
    '/index.html',
    '/css/styles.css',
    '/css/theme.css',
    '/js/main.js',
    '/js/theme.js',
    '/js/enhancements.js',
    '/images/iBridge_Logo-removebg-preview.png',
    '/offline.html',
    'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css',
    'https://fonts.googleapis.com/css2?family=Montserrat:wght@400;500;600;700&family=Playfair+Display:wght@400;700&display=swap'
];

// Install Service Worker
self.addEventListener('install', (event) => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then((cache) => {
                console.log('Opened cache');
                return cache.addAll(ASSETS_TO_CACHE);
            })
    );
});

// Activate Service Worker
self.addEventListener('activate', (event) => {
    event.waitUntil(
        caches.keys().then((cacheNames) => {
            return Promise.all(
                cacheNames.map((cacheName) => {
                    if (cacheName !== CACHE_NAME) {
                        return caches.delete(cacheName);
                    }
                })
            );
        })
    );
});

// Fetch Strategy: Cache First, Network Fallback
self.addEventListener('fetch', (event) => {
    event.respondWith(
        caches.match(event.request).then((cachedResponse) => {
            if (cachedResponse) {
                // Return cached version if found
                return cachedResponse;
            }
            // Clone the request because it can only be used once
            const fetchRequest = event.request.clone();
            return fetch(fetchRequest)
                .then((networkResponse) => {
                    // Check if response is valid
                    if (!networkResponse || networkResponse.status !== 200 || networkResponse.type !== 'basic') {
                        return networkResponse;
                    }
                    // Clone response because it can only be used once
                    const responseToCache = networkResponse.clone();
                    // Cache the new resource
                    caches.open(CACHE_NAME).then((cache) => {
                        cache.put(event.request, responseToCache);
                    });
                    return networkResponse;
                })
                .catch(() => {
                    // If network request fails, return offline page
                    if (event.request.mode === 'navigate') {
                        return caches.match('/offline.html');
                    }
                    // Optionally, return a fallback for other requests
                    return new Response('Network error occurred', {
                        status: 408,
                        statusText: 'Network error'
                    });
                });
        })
    );
});
