function resolveApiOrigin(): string {
  const apiUrl =
    process.env.NEXT_PUBLIC_API_URL ?? "http://10.110.1.15:8000/api/v1";

  if (apiUrl.startsWith("/")) {
    return "";
  }

  return apiUrl.replace(/\/api\/v\d+\/?$/, "");
}

const API_ORIGIN = resolveApiOrigin();

export function resolveMediaUrl(url?: string | null): string | undefined {
  if (!url) return undefined;
  if (url.startsWith("http://") || url.startsWith("https://") || url.startsWith("data:")) {
    return url;
  }
  if (url.startsWith("/")) {
    return `${API_ORIGIN}${url}`;
  }
  return `${API_ORIGIN}/${url}`;
}