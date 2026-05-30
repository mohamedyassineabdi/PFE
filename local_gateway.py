from __future__ import annotations

import argparse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.error import HTTPError, URLError
from urllib.parse import urlsplit
from urllib.request import Request, urlopen


HOP_BY_HOP_HEADERS = {
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailers",
    "transfer-encoding",
    "upgrade",
}


class GatewayHandler(BaseHTTPRequestHandler):
    cx_backend = "http://127.0.0.1:8000"
    ux_backend = "http://127.0.0.1:8787"

    def log_message(self, fmt: str, *args: object) -> None:
        print(f"{self.address_string()} - - [{self.log_date_time_string()}] {fmt % args}")

    def end_headers(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization, ngrok-skip-browser-warning")
        super().end_headers()

    def do_OPTIONS(self) -> None:
        self.send_response(204)
        self.end_headers()

    def do_GET(self) -> None:
        self._proxy()

    def do_HEAD(self) -> None:
        self._proxy()

    def do_POST(self) -> None:
        self._proxy()

    def do_PUT(self) -> None:
        self._proxy()

    def do_PATCH(self) -> None:
        self._proxy()

    def do_DELETE(self) -> None:
        self._proxy()

    def _target_url(self) -> str:
        parsed = urlsplit(self.path)
        if parsed.path == "/cx" or parsed.path.startswith("/cx/"):
            stripped = parsed.path[3:] or "/"
            return f"{self.cx_backend}{stripped}{('?' + parsed.query) if parsed.query else ''}"
        return f"{self.ux_backend}{self.path}"

    def _proxy(self) -> None:
        target_url = self._target_url()
        body = None
        content_length = self.headers.get("Content-Length")
        if content_length:
            body = self.rfile.read(int(content_length))

        headers = {
            key: value
            for key, value in self.headers.items()
            if key.lower() not in HOP_BY_HOP_HEADERS and key.lower() != "host"
        }
        headers["X-Forwarded-Proto"] = "https"
        headers["X-Forwarded-Host"] = self.headers.get("Host", "")

        request = Request(target_url, data=body, headers=headers, method=self.command)
        try:
            with urlopen(request, timeout=120) as response:
                payload = response.read()
                self.send_response(response.status)
                for key, value in response.headers.items():
                    if key.lower() not in HOP_BY_HOP_HEADERS and key.lower() != "access-control-allow-origin":
                        self.send_header(key, value)
                self.end_headers()
                if self.command != "HEAD":
                    self.wfile.write(payload)
        except HTTPError as error:
            payload = error.read()
            self.send_response(error.code)
            for key, value in error.headers.items():
                if key.lower() not in HOP_BY_HOP_HEADERS and key.lower() != "access-control-allow-origin":
                    self.send_header(key, value)
            self.end_headers()
            if self.command != "HEAD":
                self.wfile.write(payload)
        except URLError as error:
            message = f"Gateway target unavailable: {error.reason}".encode("utf-8", errors="replace")
            self.send_response(502)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(message)))
            self.end_headers()
            self.wfile.write(message)


def main() -> None:
    parser = argparse.ArgumentParser(description="Local gateway for Vercel frontends.")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=9000)
    parser.add_argument("--cx-backend", default="http://127.0.0.1:8000")
    parser.add_argument("--ux-backend", default="http://127.0.0.1:8787")
    args = parser.parse_args()

    GatewayHandler.cx_backend = args.cx_backend.rstrip("/")
    GatewayHandler.ux_backend = args.ux_backend.rstrip("/")
    server = ThreadingHTTPServer((args.host, args.port), GatewayHandler)
    print(f"Gateway listening on http://{args.host}:{args.port}")
    print(f"  UX -> {GatewayHandler.ux_backend}")
    print(f"  CX -> {GatewayHandler.cx_backend} via /cx")
    server.serve_forever()


if __name__ == "__main__":
    main()
