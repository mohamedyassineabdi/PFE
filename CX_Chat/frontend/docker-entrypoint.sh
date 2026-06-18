#!/bin/sh
set -e

API_BASE="${CX_API_BASE_URL:-/api/v1}"
BASE_PATH="${CX_FRONTEND_BASE_PATH:-}"

cat > /usr/share/nginx/html/runtime-config.js <<EOF
window.__CX_RUNTIME_CONFIG__ = { apiBaseUrl: "${API_BASE}", basePath: "${BASE_PATH}" };
EOF
