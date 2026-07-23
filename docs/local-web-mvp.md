# Local Web MVP

Haven 42 now has a runnable first product slice for Windows, Linux, and macOS. It opens a local browser page, reports sanitized host readiness, connects to an explicitly selected Ollama endpoint, discovers installed models, and provides repository-free chat.

This is a local application, not a hosted website. It does not require Node.js, Rust, Tauri, a cloud account, executable signing, or a public deployment.

## Start Haven 42

Windows PowerShell:

```powershell
.\scripts\start-haven42-web.ps1
```

Linux:

```bash
./scripts/start-haven42-web.linux.sh
```

macOS:

```bash
./scripts/start-haven42-web.macos.sh
```

The launcher opens `http://127.0.0.1:4242`. Use `-NoOpen` on Windows or `--no-open` on Linux and macOS to start without opening the default browser. Use `-Port` or `--port` to select another loopback port.

## Connect Ollama

For Ollama on the same computer, keep the default loopback endpoint and **This computer** scope.

For an Ollama server on your trusted home or work network:

1. Enter its literal IP endpoint, such as `http://<trusted-lan-ip>:11434`.
2. Open **Advanced connection settings**.
3. Select **Trusted local network**.
4. Select **Connect**.
5. Choose one of the installed models returned by Ollama.

Hostnames, credentials in URLs, paths, query strings, redirects, link-local addresses, public addresses under the trusted-LAN scope, and unsafe address classes are rejected. Connection settings remain in memory and are lost when Haven 42 closes.

## Chat And Model Cleanup

Chat uses the registered `general.chat` capability and `ollama.local-text` provider. It does not read a repository, write files, download models, or persist the endpoint, prompt, conversation, or response.

Every chat request sends `keep_alive: 0`. Haven 42 then makes an explicit unload request and verifies that the selected model left Ollama's process list. The same cleanup runs after a provider failure and again when the local web process closes.

## Security Boundary

The MVP:

- binds only to IPv4 loopback (`127.0.0.1`);
- rejects unexpected `Host`, `Origin`, and cross-site request metadata;
- requires an unpredictable in-memory token on every state-changing request;
- accepts JSON only and bounds request, message, conversation, timeout, and response sizes;
- serves only committed local HTML, CSS, and JavaScript;
- sends a restrictive Content Security Policy and denies framing, MIME sniffing, referrer leakage, caching, remote assets, and telemetry;
- uses the shared provider-security module for endpoint classification, no-redirect requests, and bounded JSON;
- returns sanitized error codes instead of provider responses or local exception details.

The renderer never receives a shell, executable, arbitrary process, filesystem, model-download, or repository-access surface.

The machine-readable boundary is `config/local-web-runtime-policy.json`. The offline integration suite is `scripts/test-haven42-web.py`.

## Current MVP Boundary

This first slice intentionally includes only system status, Ollama connection, installed-model selection, and chat. Software workflows, images, model management, persistence, multi-user access, remote browser access, automatic updates, and native packaging remain unavailable until their separate runtime and security gates pass.

Tauri remains an optional later packaging path. It is not required to run or validate this local-web slice.

## Validation Evidence

The sanitized Windows application-host and trusted-LAN Ollama validation cell is recorded in `examples/local-web-mvp-validation.md`. It covers page rendering, secure session bootstrap, discovery, model selection, bounded chat, response-content exclusion, application unload, and an independently empty Ollama process list.
