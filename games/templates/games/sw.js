// Xiangqi PWA — Service Worker
// Strategy:
//   - Static assets  → Cache-first (versioned cache)
//   - API calls      → Network-first (no caching)
//   - WebSocket      → Never intercept (bypass completely)
//   - Offline fallback page for navigation requests

const CACHE_VERSION = 'xiangqi-v1';
const STATIC_CACHE  = CACHE_VERSION + '-static';

// Files to pre-cache on install (app shell)
const APP_SHELL = [
    '/',
    '/offline/',
    '/static/games/css/style.css',
    '/static/games/css/start-screen.css',
    '/static/games/js/game.js',
    '/static/games/img/favicon.svg',
    '/static/games/img/icon-192.png',
    '/static/games/img/icon-512.png',
];

// ── Install: pre-cache app shell ──────────────────────────────────────────
self.addEventListener('install', function (event) {
    event.waitUntil(
        caches.open(STATIC_CACHE).then(function (cache) {
            return cache.addAll(APP_SHELL);
        }).then(function () {
            return self.skipWaiting(); // Activate immediately
        })
    );
});

// ── Activate: clean up old caches ────────────────────────────────────────
self.addEventListener('activate', function (event) {
    event.waitUntil(
        caches.keys().then(function (keys) {
            return Promise.all(
                keys.filter(function (key) {
                    return key.startsWith('xiangqi-') && key !== STATIC_CACHE;
                }).map(function (key) {
                    return caches.delete(key);
                })
            );
        }).then(function () {
            return self.clients.claim(); // Take control immediately
        })
    );
});

// ── Fetch: routing strategy ───────────────────────────────────────────────
self.addEventListener('fetch', function (event) {
    var url = event.request.url;

    // 1. Always bypass WebSocket upgrade requests
    if (event.request.headers.get('upgrade') === 'websocket') return;

    // 2. Bypass WebSocket URLs (/ws/...)
    var parsed = new URL(url);
    if (parsed.pathname.startsWith('/ws/')) return;

    // 3. Bypass non-GET requests (POST, etc.) — let them hit the network
    if (event.request.method !== 'GET') return;

    // 4. API calls → Network-first, no caching
    if (parsed.pathname.startsWith('/api/')) {
        event.respondWith(fetch(event.request));
        return;
    }

    // 5. Static files → Cache-first
    if (parsed.pathname.startsWith('/static/')) {
        event.respondWith(cacheFirst(event.request));
        return;
    }

    // 6. Navigation requests (HTML pages) → Network-first with offline fallback
    if (event.request.mode === 'navigate') {
        event.respondWith(
            fetch(event.request).catch(function () {
                return caches.match('/offline/');
            })
        );
        return;
    }

    // 7. Everything else → Network-first
    event.respondWith(
        fetch(event.request).catch(function () {
            return caches.match(event.request);
        })
    );
});

// ── Cache-first helper ───────────────────────────────────────────────────
function cacheFirst(request) {
    return caches.match(request).then(function (cached) {
        if (cached) return cached;
        return fetch(request).then(function (response) {
            // Cache valid responses
            if (response && response.status === 200 && response.type !== 'opaque') {
                var clone = response.clone();
                caches.open(STATIC_CACHE).then(function (cache) {
                    cache.put(request, clone);
                });
            }
            return response;
        });
    });
}
