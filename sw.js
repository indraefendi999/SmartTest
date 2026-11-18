/* ============================================================================
   SmartTest V. 1.2 - Progressive Web App Service Worker (Network-First)
   SMPN 1 MESUJI MAKMUR
   Strategi: Network-First agar data ujian & pembaruan selalu segar, sekaligus
   memenuhi syarat instalasi PWA Android/iOS/Desktop (Standalone Mode).
   ============================================================================ */

var CACHE_NAME = "smarttest-pwa-v2.2.0";
var CORE_ASSETS = [
  "./",
  "./index.html",
  "./manifest.json",
  "./assets/logo-smpn1.png",
  "./assets/logo-oki.png",
  "./assets/icon-192.png",
  "./assets/icon-512.png"
];

self.addEventListener("install", function (event) {
  event.waitUntil(
    caches.open(CACHE_NAME).then(function (cache) {
      return cache.addAll(CORE_ASSETS).catch(function () {
        // Jangan gagalkan instalasi jika salah satu aset belum tersedia
        return Promise.resolve();
      });
    })
  );
  self.skipWaiting();
});

self.addEventListener("activate", function (event) {
  event.waitUntil(
    caches.keys().then(function (keys) {
      return Promise.all(
        keys.map(function (key) {
          if (key !== CACHE_NAME) {
            return caches.delete(key);
          }
        })
      );
    })
  );
  self.clients.claim();
});

self.addEventListener("fetch", function (event) {
  var req = event.request;

  // Hanya tangani GET pada origin aplikasi; lewati API Supabase & domain eksternal
  if (req.method !== "GET") return;
  var url = new URL(req.url);
  if (url.origin !== self.location.origin) return;
  if (url.pathname.indexOf("/rest/v1/") !== -1) return;

  // Network-First: utamakan jaringan terbaru, fallback ke cache jika offline
  event.respondWith(
    fetch(req)
      .then(function (networkRes) {
        if (networkRes && networkRes.status === 200 && networkRes.type === "basic") {
          var resClone = networkRes.clone();
          caches.open(CACHE_NAME).then(function (cache) {
            cache.put(req, resClone);
          });
        }
        return networkRes;
      })
      .catch(function () {
        return caches.match(req).then(function (cachedRes) {
          return cachedRes || caches.match("./index.html");
        });
      })
  );
});
