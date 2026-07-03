import type { CapacitorConfig } from "@capacitor/cli";

const config: CapacitorConfig = {
  appId: "id.creativenetwork.creativepos",
  appName: "CreativePOS",
  webDir: "www",
  android: {
    allowMixedContent: true,
    backgroundColor: "#0f172a",
  },
  server: {
    androidScheme: "https",
    cleartext: true,
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 1500,
      backgroundColor: "#0f172a",
      showSpinner: false,
    },
    StatusBar: {
      style: "DARK",
      backgroundColor: "#0f172a",
    },
  },
};

export default config;