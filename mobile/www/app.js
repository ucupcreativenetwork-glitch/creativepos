const STORAGE_KEY = "creativepos_server_url";

const loadingEl = document.getElementById("loading");
const setupEl = document.getElementById("setup");
const serverInput = document.getElementById("serverUrl");
const connectBtn = document.getElementById("connectBtn");
const errorEl = document.getElementById("error");

function normalizeServerUrl(raw) {
  let value = (raw || "").trim();
  if (!value) return null;
  if (!/^https?:\/\//i.test(value)) {
    value = `http://${value}`;
  }
  return value.replace(/\/+$/, "");
}

function showError(message) {
  errorEl.textContent = message;
  errorEl.classList.remove("hidden");
}

function clearError() {
  errorEl.textContent = "";
  errorEl.classList.add("hidden");
}

async function saveServerUrl(url) {
  localStorage.setItem(STORAGE_KEY, url);
  if (window.Capacitor?.Plugins?.Preferences) {
    await window.Capacitor.Plugins.Preferences.set({
      key: STORAGE_KEY,
      value: url,
    });
  }
}

async function loadServerUrl() {
  if (window.Capacitor?.Plugins?.Preferences) {
    const { value } = await window.Capacitor.Plugins.Preferences.get({
      key: STORAGE_KEY,
    });
    if (value) return value;
  }
  return localStorage.getItem(STORAGE_KEY);
}

async function verifyServer(url) {
  const healthUrl = `${url}/api/v1/health`;
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 10000);

  try {
    const response = await fetch(healthUrl, {
      method: "GET",
      headers: { Accept: "application/json" },
      signal: controller.signal,
    });
    if (!response.ok) {
      throw new Error(`Server merespons ${response.status}`);
    }
    return true;
  } finally {
    clearTimeout(timeout);
  }
}

function goToPos(url) {
  window.location.href = `${url}/pos`;
}

async function connect() {
  clearError();
  const url = normalizeServerUrl(serverInput.value);
  if (!url) {
    showError("Masukkan alamat server.");
    return;
  }

  connectBtn.disabled = true;
  connectBtn.textContent = "Menghubungkan...";

  try {
    await verifyServer(url);
    await saveServerUrl(url);
    goToPos(url);
  } catch (error) {
    showError(
      error?.name === "AbortError"
        ? "Server tidak merespons. Periksa IP dan jaringan WiFi."
        : `Gagal terhubung: ${error?.message || "tidak diketahui"}`
    );
  } finally {
    connectBtn.disabled = false;
    connectBtn.textContent = "Hubungkan & Buka POS";
  }
}

async function bootstrap() {
  loadingEl.classList.remove("hidden");
  setupEl.classList.add("hidden");

  const saved = await loadServerUrl();
  if (saved) {
    try {
      await verifyServer(saved);
      goToPos(saved);
      return;
    } catch {
      serverInput.value = saved;
    }
  }

  loadingEl.classList.add("hidden");
  setupEl.classList.remove("hidden");
}

connectBtn.addEventListener("click", connect);
serverInput.addEventListener("keydown", (event) => {
  if (event.key === "Enter") connect();
});

bootstrap();