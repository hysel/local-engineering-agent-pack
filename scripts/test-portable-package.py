#!/usr/bin/env python3
"""Source/packaged parity and native one-folder smoke test."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import os
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request


ROOT = Path(__file__).resolve().parent.parent


def request(url: str, method: str = "GET", token: str = "", body: bytes | None = None):
    parsed = urllib.parse.urlsplit(url)
    origin = f"{parsed.scheme}://{parsed.netloc}"
    headers = {"Host": parsed.netloc}
    if method == "POST":
        headers.update({
            "Origin": origin,
            "Content-Type": "application/json",
            "X-Haven-Token": token,
        })
    return urllib.request.urlopen(
        urllib.request.Request(url, method=method, data=body, headers=headers),
        timeout=5,
    )


def launch(command: list[str]) -> tuple[subprocess.Popen[str], str]:
    process = subprocess.Popen(
        command + ["--port", "0", "--no-open"],
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        env={**os.environ, "PYTHONUNBUFFERED": "1"},
    )
    deadline = time.monotonic() + 15
    while time.monotonic() < deadline:
        line = process.stdout.readline() if process.stdout else ""
        match = re.search(r"http://127\.0\.0\.1:\d+", line)
        if match:
            return process, match.group(0)
        if process.poll() is not None:
            raise AssertionError(f"runtime exited early: {line}")
    process.kill()
    raise AssertionError("runtime did not announce its loopback URL")


def probe(command: list[str], packaged: bool) -> dict:
    process, origin = launch(command)
    try:
        with request(origin + "/api/bootstrap") as response:
            bootstrap = json.load(response)
            assert response.headers["X-Frame-Options"] == "DENY"
            assert "default-src 'self'" in response.headers["Content-Security-Policy"]
        with request(origin + "/app.js") as response:
            app_digest = __import__("hashlib").sha256(response.read()).hexdigest()
        try:
            urllib.request.urlopen(origin.replace("127.0.0.1", "localhost") + "/api/bootstrap", timeout=5)
            raise AssertionError("alternate Host was accepted")
        except urllib.error.HTTPError as error:
            assert error.code == 403
        assert bootstrap["runtime"]["bindScope"] == "loopback-only"
        assert bootstrap["updates"]["activationAllowed"] is False
        assert bootstrap["package"]["required"] is packaged
        assert bootstrap["package"]["verified"] is packaged
        token = bootstrap.pop("sessionToken")
        with request(
            origin + "/api/shutdown", "POST", token, b"{}",
        ) as response:
            assert json.load(response) == {
                "shutdownAccepted": True, "modelCleanupVerified": True,
            }
        process.wait(timeout=10)
        assert process.returncode == 0
        return {
            "capabilities": bootstrap["capabilities"],
            "updates": bootstrap["updates"],
            "privacy": bootstrap["privacy"],
            "appDigest": app_digest,
        }
    finally:
        if process.poll() is None:
            process.kill()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--executable", required=True)
    args = parser.parse_args()
    source = probe([sys.executable, str(ROOT / "web/server.py")], False)
    packaged = probe([str(Path(args.executable).resolve())], True)
    assert source == packaged, "source and packaged behavior diverged"
    print("Portable package parity and native smoke tests passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
