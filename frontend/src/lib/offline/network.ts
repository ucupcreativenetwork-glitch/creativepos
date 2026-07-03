import axios from "axios";

export function isBrowserOnline(): boolean {
  return typeof navigator !== "undefined" ? navigator.onLine : true;
}

export function isNetworkError(error: unknown): boolean {
  if (!isBrowserOnline()) return true;

  if (axios.isAxiosError(error)) {
    if (!error.response) return true;
    if (error.code === "ERR_NETWORK") return true;
    if (error.message.toLowerCase().includes("network")) return true;
  }

  if (error instanceof TypeError && error.message === "Failed to fetch") {
    return true;
  }

  return false;
}