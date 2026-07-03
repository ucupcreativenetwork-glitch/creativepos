import type { RuntimeCaching } from "workbox-build";

const FIFTEEN_MINUTES = 15 * 60;
const ONE_YEAR = 365 * 24 * 60 * 60;
const ONE_MONTH = 30 * 24 * 60 * 60;

/**
 * Workbox runtime caching rules.
 * POST requests are never listed here — they bypass the cache by default.
 */
export const pwaRuntimeCaching: RuntimeCaching[] = [
  {
    urlPattern: ({ request }: { request: Request }) =>
      request.destination === "style",
    handler: "CacheFirst",
    options: {
      cacheName: "static-styles",
      expiration: { maxEntries: 32, maxAgeSeconds: ONE_YEAR },
    },
  },
  {
    urlPattern: ({ request }: { request: Request }) =>
      request.destination === "script",
    handler: "CacheFirst",
    options: {
      cacheName: "static-scripts",
      expiration: { maxEntries: 64, maxAgeSeconds: ONE_YEAR },
    },
  },
  {
    urlPattern: ({ request }: { request: Request }) =>
      request.destination === "font" || request.destination === "image",
    handler: "CacheFirst",
    options: {
      cacheName: "static-assets",
      expiration: { maxEntries: 128, maxAgeSeconds: ONE_MONTH },
    },
  },
  {
    urlPattern: /\/_next\/static\/.*/i,
    handler: "CacheFirst",
    options: {
      cacheName: "next-static",
      expiration: { maxEntries: 200, maxAgeSeconds: ONE_YEAR },
    },
  },
  {
    urlPattern: /\/api\/v1\/pos\/catalog\/(products|categories|payment-methods)/i,
    handler: "NetworkFirst",
    method: "GET",
    options: {
      cacheName: "pos-catalog-api",
      networkTimeoutSeconds: 5,
      expiration: { maxEntries: 32, maxAgeSeconds: FIFTEEN_MINUTES },
      cacheableResponse: { statuses: [0, 200] },
    },
  },
];