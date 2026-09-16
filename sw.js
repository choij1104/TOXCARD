/* TOXCARD — offline shell.

   Shell: stale-while-revalidate. The cached copy answers immediately, so the app still
   opens with no network, and a background fetch refreshes it for the next launch. This is
   the part that was wrong before: a pure cache-first shell keeps serving the old build to
   every returning client until CACHE happens to change, so a release could go out and
   never reach the people already using the app.

   Data: network-first with cache fallback, so an online user silently gets the newest
   reviewed dataset and an offline user is never blocked. */

const CACHE = 'toxcard-2026.09.16.c';
const SHELL = ['./', './index.html', './manifest.json', './icon.svg'];
const DATA  = ['./data/toxins.json','./data/antidote-agents.json','./data/protocols.json',
               './data/toxidromes.json','./data/version.json'];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE)
      .then(c => c.addAll(SHELL).then(() => c.addAll(DATA).catch(() => {})))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const origin = new URL(req.url).origin;
  if (origin !== self.location.origin) {
    // Web fonts: cache on first sight so the typeface survives offline. Anything else
    // cross-origin is left alone. If the font never loads, the system stack takes over.
    if (/fonts\.(googleapis|gstatic)\.com$/.test(origin)) {
      e.respondWith(
        caches.match(req).then(hit => hit || fetch(req).then(res => {
          if (res && (res.ok || res.type === 'opaque')) { const copy = res.clone(); caches.open(CACHE).then(c => c.put(req, copy)); }
          return res;
        }))
      );
    }
    return;
  }

  if (req.url.includes('/data/')) {
    e.respondWith(
      fetch(req)
        .then(res => {
          if (res && res.ok) { const copy = res.clone(); caches.open(CACHE).then(c => c.put(req, copy)); }
          return res;
        })
        .catch(() => caches.match(req))
    );
    return;
  }

  e.respondWith(
    caches.match(req).then(hit => {
      const net = fetch(req)
        .then(res => {
          if (res && res.ok) { const copy = res.clone(); caches.open(CACHE).then(c => c.put(req, copy)); }
          return res;
        })
        .catch(() => null);
      e.waitUntil(net);                       // let the refresh finish after the response
      return hit || net.then(r => r || caches.match('./index.html'));
    })
  );
});
