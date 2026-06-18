(() => {
    const config = window.__PORTAL_RUNTIME_CONFIG__ || {};

    // Strip backend-only ports (8000, 8081) from any URL so public links
    // always use the ALB standard HTTP/HTTPS port.
    const BACKEND_PORTS = new Set(["8000", "8081"]);

    function stripBackendPort(urlObj) {
        if (BACKEND_PORTS.has(urlObj.port)) {
            urlObj.port = "";
        }
        return urlObj;
    }

    // Derive a clean public origin (without backend ports) from the browser location.
    function getPublicOrigin() {
        try {
            const loc = stripBackendPort(new URL(window.location.href));
            return loc.origin;
        } catch (_e) {
            return window.location.origin;
        }
    }

    const publicOrigin = getPublicOrigin();

    function normalizeUrl(value, fallbackPath) {
        const raw = typeof value === "string" ? value.trim() : "";
        // Fallback uses the cleaned public origin so it never contains a backend port.
        const fallback = `${publicOrigin}${fallbackPath}`;
        if (!raw) {
            return fallback;
        }

        try {
            const url = stripBackendPort(new URL(raw, publicOrigin));
            return url.toString();
        } catch (_error) {
            return fallback;
        }
    }

    const mappings = {
        "ux-ui": normalizeUrl(config.uxUiUrl, "/ux-ui"),
        "cx-app": normalizeUrl(config.cxUrl, "/cx"),
        "cx-admin": normalizeUrl(config.cxAdminUrl, "/cx/admin/")
    };

    document.querySelectorAll("[data-portal-link]").forEach((anchor) => {
        const key = anchor.getAttribute("data-portal-link");
        const href = mappings[key];
        if (href) {
            anchor.setAttribute("href", href);
            return;
        }

        anchor.setAttribute("href", "#");
        anchor.removeAttribute("target");
        anchor.setAttribute("aria-disabled", "true");
    });
})();
