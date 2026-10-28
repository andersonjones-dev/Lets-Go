// Let's Go offline support.
// Change VERSION whenever you change index.html so phones pick up the update.
const VERSION = "letsgo-v3";
const CORE = [
  "./",
  "index.html",
  "config.js",
  "manifest.webmanifest",
  "icons/apple-touch-icon.png",
  "icons/icon-192.png",
  "icons/icon-512.png",
  "icons/favicon-32.png"
];
const CDN = ["cdn.jsdelivr.net", "cdnjs.cloudflare.com", "fonts.googleapis.com", "fonts.gstatic.com"];

self.addEventListener("install", event => {
  event.waitUntil(caches.open(VERSION).then(cache => cache.addAll(CORE)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== VERSION).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", event => {
  const req = event.request;
  if (req.method !== "GET") return;
  const url = new URL(req.url);

  // The app page and settings: network first so updates arrive, saved copy when offline.
  if (req.mode === "navigate" || (url.origin === location.origin && url.pathname.endsWith("config.js"))) {
    const key = req.mode === "navigate" ? "index.html" : req;
    event.respondWith(
      fetch(req)
        .then(res => { const copy = res.clone(); caches.open(VERSION).then(c => c.put(key, copy)); return res; })
        .catch(() => caches.match(key))
    );
    return;
  }

  // Never cache sync traffic.
  if (url.hostname.endsWith("supabase.co")) return;

  // App files, libraries and fonts: saved copy first, fetch and save if missing.
  if (url.origin === location.origin || CDN.includes(url.hostname)) {
    event.respondWith(
      caches.match(req).then(hit => hit || fetch(req).then(res => {
        if (res.ok || res.type === "opaque") { const copy = res.clone(); caches.open(VERSION).then(c => c.put(req, copy)); }
        return res;
      }))
    );
  }
});
