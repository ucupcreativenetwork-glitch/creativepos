import type { NextConfig } from "next";
import withPWAInit from "@ducanh2912/next-pwa";
import { pwaRuntimeCaching } from "./src/config/pwa-runtime-caching";

const withPWA = withPWAInit({
  dest: "public",
  disable: process.env.NODE_ENV === "development",
  register: true,
  reloadOnOnline: true,
  cacheOnFrontEndNav: true,
  fallbacks: {
    document: "/offline",
  },
  workboxOptions: {
    disableDevLogs: true,
    runtimeCaching: pwaRuntimeCaching,
  },
});

const nextConfig: NextConfig = {
  output: "standalone",
  turbopack: {},
};

export default withPWA(nextConfig);