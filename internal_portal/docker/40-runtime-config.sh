#!/bin/sh
set -eu

cat >/usr/share/nginx/html/assets/JavaScript/runtime-config.js <<EOF
window.__PORTAL_RUNTIME_CONFIG__ = {
    portalApiBase: "${PORTAL_API_BASE:-}",
    uxUiUrl: "${PORTAL_UX_UI_URL-}",
    cxUrl: "${PORTAL_CX_URL-}",
    cxAdminUrl: "${PORTAL_CX_ADMIN_URL-}",
    enableLegacyExternalScripts: ${PORTAL_ENABLE_LEGACY_EXTERNAL_SCRIPTS:-false},
    enableAnalytics: ${PORTAL_ENABLE_ANALYTICS:-false}
};
EOF
