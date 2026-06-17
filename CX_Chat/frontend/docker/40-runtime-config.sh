#!/bin/sh
set -eu

cat >/usr/share/nginx/html/runtime-config.js <<EOF
window.__CX_RUNTIME_CONFIG__ = {
  apiBaseUrl: "${CX_API_BASE_URL:-/api/v1}",
  basePath: "${CX_FRONTEND_BASE_PATH:-}"
};
EOF
