import { apiClient } from "@/lib/api/client";

const INSTALL_ID_KEY = "creativepos_install_id";
const FINGERPRINT_KEY = "creativepos_device_fingerprint";
const AGENT_VERSION = "1.0.0";

let heartbeatTimer: ReturnType<typeof setInterval> | null = null;
let pollTimer: ReturnType<typeof setInterval> | null = null;

function getInstallId(): string {
  let id = localStorage.getItem(INSTALL_ID_KEY);
  if (!id) {
    id = crypto.randomUUID();
    localStorage.setItem(INSTALL_ID_KEY, id);
  }
  return id;
}

function getFingerprint(): string {
  let fingerprint = localStorage.getItem(FINGERPRINT_KEY);
  if (!fingerprint) {
    fingerprint = `web-${getInstallId()}`;
    localStorage.setItem(FINGERPRINT_KEY, fingerprint);
  }
  return fingerprint;
}

function getBrowserName(): string {
  const ua = navigator.userAgent;
  if (ua.includes("Edg/")) return "Edge";
  if (ua.includes("Chrome/")) return "Chrome";
  if (ua.includes("Firefox/")) return "Firefox";
  if (ua.includes("Safari/")) return "Safari";
  return "Browser";
}

async function registerRemoteAgent(): Promise<void> {
  const fingerprint = getFingerprint();
  await apiClient.post("/remote/register", {
    device_name: `CreativePOS Web (${getBrowserName()})`,
    fingerprint,
    install_id: getInstallId(),
    platform: "web",
    browser: getBrowserName(),
    app_version: process.env.NEXT_PUBLIC_APP_VERSION ?? "web",
    os_version: navigator.platform,
    device_model: navigator.userAgent.slice(0, 120),
    mac_address: null,
    api_base_url: process.env.NEXT_PUBLIC_API_URL ?? "",
    agent_version: AGENT_VERSION,
  });
}

async function sendHeartbeat(): Promise<void> {
  await apiClient.post("/remote/heartbeat", {
    fingerprint: getFingerprint(),
    app_version: process.env.NEXT_PUBLIC_APP_VERSION ?? "web",
  });
}

async function executeCommand(command: string): Promise<string> {
  switch (command) {
    case "ping":
      return "pong";
    case "collect_info":
      return JSON.stringify({
        userAgent: navigator.userAgent,
        language: navigator.language,
        platform: navigator.platform,
        screen: `${window.screen.width}x${window.screen.height}`,
        url: window.location.href,
        fingerprint: getFingerprint(),
      });
    case "collect_logs":
      return `Web remote snapshot ${new Date().toISOString()}`;
    case "check_update":
      return JSON.stringify({ update_available: false, platform: "web" });
    case "clear_cache":
      if ("caches" in window) {
        const keys = await caches.keys();
        await Promise.all(keys.map((key) => caches.delete(key)));
      }
      return "web cache cleared";
    case "force_sync":
      return "web sync not applicable";
    case "open_remote_assist":
      return `Buka halaman ini di browser klien: ${window.location.origin}`;
    default:
      throw new Error(`Unknown command: ${command}`);
  }
}

async function pollCommands(): Promise<void> {
  const { data } = await apiClient.get<{
    data: Array<{ id: number; command: string; payload?: Record<string, unknown> }>;
  }>("/remote/commands", {
    params: { fingerprint: getFingerprint() },
  });

  for (const item of data.data ?? []) {
    try {
      const result = await executeCommand(item.command);
      await apiClient.post(`/remote/commands/${item.id}/complete`, {
        fingerprint: getFingerprint(),
        status: "completed",
        result,
      });

      if (item.command === "collect_info" || item.command === "collect_logs") {
        await apiClient.post("/remote/diagnostics", {
          fingerprint: getFingerprint(),
          type: item.command === "collect_info" ? "device_info" : "logs",
          title: `Web ${item.command}`,
          content: result,
        });
      }
    } catch (error) {
      await apiClient.post(`/remote/commands/${item.id}/complete`, {
        fingerprint: getFingerprint(),
        status: "failed",
        result: error instanceof Error ? error.message : "failed",
      });
    }
  }
}

export function startRemoteAgent(): void {
  stopRemoteAgent();

  void registerRemoteAgent().catch(() => undefined);
  heartbeatTimer = setInterval(() => {
    void sendHeartbeat().catch(() => undefined);
  }, 2 * 60 * 1000);
  pollTimer = setInterval(() => {
    void pollCommands().catch(() => undefined);
  }, 30 * 1000);
  void pollCommands().catch(() => undefined);
}

export function stopRemoteAgent(): void {
  if (heartbeatTimer) clearInterval(heartbeatTimer);
  if (pollTimer) clearInterval(pollTimer);
  heartbeatTimer = null;
  pollTimer = null;
}