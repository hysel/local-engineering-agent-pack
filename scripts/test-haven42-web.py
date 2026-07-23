#!/usr/bin/env python3
"""Offline integration tests for the Haven 42 local-web MVP."""

from __future__ import annotations

import importlib.util
import json
import threading
import urllib.error
import urllib.request
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
SPEC = importlib.util.spec_from_file_location("haven42_web_server", ROOT / "web/server.py")
assert SPEC and SPEC.loader
WEB = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(WEB)


class FakeState:
    models = ["qwen3.5:9b"]
    loaded: set[str] = set()
    requests: list[tuple[str, dict]] = []
    fail_chat = False


class FakeOllama(BaseHTTPRequestHandler):
    def log_message(self, _format, *_args):
        return

    def _json(self, status: int, value: dict):
        data = json.dumps(value).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):  # noqa: N802
        if self.path == "/api/version":
            self._json(200, {"version": "test-1.0"})
        elif self.path == "/api/tags":
            self._json(200, {"models": [{"name": name} for name in FakeState.models]})
        elif self.path == "/api/ps":
            self._json(200, {"models": [{"name": name} for name in sorted(FakeState.loaded)]})
        else:
            self._json(404, {"error": "not-found"})

    def do_POST(self):  # noqa: N802
        body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        FakeState.requests.append((self.path, body))
        model = str(body.get("model", ""))
        if self.path == "/api/chat":
            FakeState.loaded.add(model)
            if FakeState.fail_chat:
                self._json(500, {"error": "forced-chat-failure"})
            else:
                self._json(200, {"message": {"role": "assistant", "content": "LOCAL_WEB_OK"}})
        elif self.path == "/api/generate" and body.get("keep_alive") == 0:
            FakeState.loaded.discard(model)
            self._json(200, {"done": True})
        else:
            self._json(404, {"error": "not-found"})


def request_json(
    url: str,
    method: str = "GET",
    body: dict | None = None,
    token: str | None = None,
    origin: str | None = None,
) -> tuple[int, dict, dict]:
    data = json.dumps(body).encode() if body is not None else None
    headers = {}
    if body is not None:
        headers["Content-Type"] = "application/json"
    if token is not None:
        headers["X-Haven-Token"] = token
    if origin is not None:
        headers["Origin"] = origin
    request = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=5) as response:
            return response.status, json.loads(response.read()), dict(response.headers)
    except urllib.error.HTTPError as error:
        return error.code, json.loads(error.read()), dict(error.headers)


def main() -> int:
    checks = 0
    fake = ThreadingHTTPServer(("127.0.0.1", 0), FakeOllama)
    fake_thread = threading.Thread(target=fake.serve_forever, daemon=True)
    fake_thread.start()
    state = WEB.HavenState()
    app = WEB.HavenWebServer(("127.0.0.1", 0), state)
    app_thread = threading.Thread(target=app.serve_forever, daemon=True)
    app_thread.start()
    origin = app.expected_origin
    try:
        status, bootstrap, headers = request_json(origin + "/api/bootstrap")
        assert status == 200 and bootstrap["runtime"]["bindScope"] == "loopback-only"
        assert bootstrap["privacy"]["modelResidency"] == "unload-after-response"
        assert headers["X-Frame-Options"] == "DENY"
        assert "default-src 'self'" in headers["Content-Security-Policy"]
        token = bootstrap["sessionToken"]
        checks += 4

        status, error, _ = request_json(
            origin + "/api/connect",
            "POST",
            {"endpoint": "http://127.0.0.1:11434", "trustScope": "loopback", "timeoutSeconds": 30},
            token,
        )
        assert status == 403 and error["error"] == "invalid-origin"
        status, error, _ = request_json(
            origin + "/api/connect",
            "POST",
            {"endpoint": "http://127.0.0.1:11434", "trustScope": "loopback", "timeoutSeconds": 30},
            "wrong-token",
            origin,
        )
        assert status == 403 and error["error"] == "invalid-session-token"
        checks += 2

        for endpoint, scope, expected in (
            ("http://169.254.169.254", "trusted-lan", "unsafe-provider-address"),
            ("http://example.com", "trusted-lan", "provider-host-must-be-ip-literal"),
            ("http://user:secret@127.0.0.1", "loopback", "invalid-provider-url"),
        ):
            status, error, _ = request_json(
                origin + "/api/connect",
                "POST",
                {"endpoint": endpoint, "trustScope": scope, "timeoutSeconds": 30},
                token,
                origin,
            )
            assert status == 400 and error["error"] == expected
            checks += 1

        fake_url = f"http://127.0.0.1:{fake.server_port}"
        status, connected, _ = request_json(
            origin + "/api/connect",
            "POST",
            {"endpoint": fake_url, "trustScope": "loopback", "timeoutSeconds": 30},
            token,
            origin,
        )
        assert status == 200
        assert connected["models"] == ["qwen3.5:9b"]
        assert connected["configurationPersisted"] is False
        checks += 3

        status, error, _ = request_json(
            origin + "/api/chat",
            "POST",
            {"model": "invented:latest", "messages": [{"role": "user", "content": "hello"}]},
            token,
            origin,
        )
        assert status == 400 and error["error"] == "model-not-discovered"
        checks += 1

        status, reply, _ = request_json(
            origin + "/api/chat",
            "POST",
            {"model": "qwen3.5:9b", "messages": [{"role": "user", "content": "hello"}]},
            token,
            origin,
        )
        assert status == 200 and reply["content"] == "LOCAL_WEB_OK"
        assert reply["modelUnloaded"] is True and not FakeState.loaded
        chat_payload = next(body for path, body in FakeState.requests if path == "/api/chat")
        assert chat_payload["keep_alive"] == 0 and chat_payload["stream"] is False
        assert chat_payload["messages"][0]["role"] == "system"
        assert any(path == "/api/generate" and body["keep_alive"] == 0 for path, body in FakeState.requests)
        checks += 5

        FakeState.fail_chat = True
        status, error, _ = request_json(
            origin + "/api/chat",
            "POST",
            {"model": "qwen3.5:9b", "messages": [{"role": "user", "content": "force failure"}]},
            token,
            origin,
        )
        assert status == 502 and error["error"] == "ollama-chat-failed"
        assert not FakeState.loaded
        checks += 2

        try:
            WEB.HavenWebServer(("0.0.0.0", 0), WEB.HavenState())
        except ValueError:
            checks += 1
        else:
            raise AssertionError("non-loopback bind must be rejected")

        policy = json.loads((ROOT / "config/local-web-runtime-policy.json").read_text(encoding="utf-8"))
        assert policy["bind"]["remoteBindAllowed"] is False
        assert policy["chat"]["modelResidency"] == "unload-after-response"
        assert policy["browser"]["remoteAssetsAllowed"] is False
        javascript = (ROOT / "web/static/app.js").read_text(encoding="utf-8")
        assert "innerHTML" not in javascript and "X-Haven-Token" in javascript
        checks += 4
    finally:
        app.shutdown()
        app.server_close()
        fake.shutdown()
        fake.server_close()
    print(f"Haven 42 local-web self-test passed: {checks} security and behavior checks.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
