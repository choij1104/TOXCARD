/* TOXCARD — offline shell.
   Strategy: cache-first for the shell so the app opens instantly with no network;
   network-first with cache fallback for the data, so an online user silently gets
   the newest reviewed dataset and an offline user is never blocked. */

const CACHE = 'toxcard-v2026.08.10';
const SHELL = ['./', './index.html', './manifest.json', './icon.svg'];
const DATA = ['./data/toxins.json','./data/antidote-agents.json','./data/protocols.json','./data/toxidromes.json','./data/version.json'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL).then(()=>c.addAll(DATA).catch(()=>{}))).then(() => self.skipWaiting()));
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
  const isData = req.url.includes('/data/');

  if (isData) {
    e.respondWith(
      fetch(req)
        .then(res => {
          const copy = res.clone();
          caches.open(CACHE).then(c => c.put(req, copy));
          return res;
        })
        .catch(() => caches.match(req))
    );
  } else {
    e.respondWith(
      caches.match(req).then(hit => hit || fetch(req).then(res => {
        const copy = res.clone();
        caches.open(CACHE).then(c => c.put(req, copy));
        return res;
      }))
    );
  }
});
