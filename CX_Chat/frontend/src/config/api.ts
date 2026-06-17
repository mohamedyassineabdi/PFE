declare global {
  interface Window {
    __CX_RUNTIME_CONFIG__?: {
      apiBaseUrl?: string;
      basePath?: string;
    };
  }
}

function normalizeApiBaseUrl(value: string): string {
  return value.replace(/\/$/, "");
}

function resolveApiBaseUrl(): string {
  const runtimeValue =
    typeof window !== "undefined"
      ? window.__CX_RUNTIME_CONFIG__?.apiBaseUrl
      : undefined;
  const envValue = import.meta.env.VITE_API_BASE_URL;
  return normalizeApiBaseUrl(runtimeValue || envValue || "/api/v1");
}

export const API_BASE_URL = resolveApiBaseUrl();

function normalizeBasePath(value: string): string {
  if (!value || value === "/") {
    return "";
  }
  return value.endsWith("/") ? value.slice(0, -1) : value;
}

export function getCxBasePath(): string {
  const runtimeValue =
    typeof window !== "undefined"
      ? window.__CX_RUNTIME_CONFIG__?.basePath
      : undefined;
  return normalizeBasePath(runtimeValue || "");
}
