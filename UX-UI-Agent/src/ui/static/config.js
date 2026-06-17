const UX_UI_AUDITOR_LOCAL_HOSTS = new Set(["localhost", "127.0.0.1", "0.0.0.0", ""]);
const UX_UI_AUDITOR_BACKEND_OVERRIDE = window.localStorage.getItem("UX_UI_AUDITOR_API_BASE_URL") || "";
const UX_UI_AUDITOR_PUBLIC_BACKEND_URL = "";
const UX_UI_AUDITOR_PARAMS = new URLSearchParams(window.location.search);
const UX_UI_AUDITOR_INFERRED_BASE_PATH = (() => {
  const pathname = window.location.pathname.replace(/\/+$/, "");
  return pathname === "/ux-ui" || pathname.startsWith("/ux-ui/") ? "/ux-ui" : "";
})();
const UX_UI_AUDITOR_QUERY_BACKEND = (
  UX_UI_AUDITOR_PARAMS.get("apiBaseUrl") ||
  UX_UI_AUDITOR_PARAMS.get("backend") ||
  UX_UI_AUDITOR_PARAMS.get("api") ||
  ""
).trim().replace(/\/+$/, "");

window.__UX_UI_AUDITOR_CONFIG__ = {
  // Leave empty when the Python backend serves this same static folder.
  // Query-string and localStorage overrides take precedence over the default URL.
  apiBaseUrl:
    UX_UI_AUDITOR_QUERY_BACKEND ||
    UX_UI_AUDITOR_BACKEND_OVERRIDE ||
    UX_UI_AUDITOR_INFERRED_BASE_PATH,
  basePath: UX_UI_AUDITOR_INFERRED_BASE_PATH,
};
