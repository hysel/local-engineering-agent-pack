# Portable Development Package

Haven 42 can be built as an unsigned PyInstaller one-folder development package on Windows, Linux, and macOS. It reuses the exact browser UI and Python service from source. The package adds no installer, system service, administrator requirement, global Python requirement, Tauri/Rust runtime, updater activation, or machine-modification capability.

## Build And Run

Install the pinned build dependency in an isolated environment, then run:

```text
python -m pip install -r package/requirements-build.txt
python scripts/build-portable-development-package.py
```

The native executable is under `dist/portable/bundle/haven42/`. It accepts `--port` and `--no-open`. Port `0` asks the operating system for an unused loopback port. The build also creates a platform archive and evidence in `dist/portable/artifacts/`.

These outputs are unsigned development artifacts. They are not installers or production releases. Antivirus and operating-system reputation prompts are possible because signing and notarization are deliberately outside this batch.

## Security Boundary

The executable binds only to `127.0.0.1`. The browser URL is constructed from the server's actual loopback address and numeric port, then passed to the standard browser controller as a new tab. No user value becomes an executable or browser command.

Frozen resources are limited to three UI files and three server-owned data files. A build-generated manifest binds every allowed resource by relative path, size, and SHA-256. Startup fails closed if the embedded manifest or any listed resource is malformed, missing, or changed. HTTP routing independently allowlists the three asset paths; no general filesystem serving exists.

The service starts no child process except the already constrained, fixed-command readiness probes owned by the existing system-readiness registry. It exposes no arbitrary process, shell, filesystem, installer, or updater command. Shutdown is a same-origin JSON POST protected by the unpredictable in-memory session token. Models used by the session must be unloaded and verified before shutdown is accepted.

## Validation And Evidence

`scripts/test-portable-package.py` starts both source and native packaged runtimes on operating-system-selected loopback ports. It compares the capability, update, privacy, and browser-asset results; checks response security headers and Host rejection; verifies packaged integrity state; invokes protected shutdown; and requires a clean native exit.

The GitHub Actions packaging matrix has read-only repository permission, does not persist checkout credentials, pins PyInstaller, builds independently on each native operating system, runs the parity/smoke test, and retains artifacts for seven days. It does not publish a GitHub Release.

Each artifact set contains:

- the native unsigned development archive;
- `SHA256SUMS`;
- a build-environment dependency inventory;
- generated third-party notices from installed distribution metadata;
- a CycloneDX JSON SBOM.

The inventory and notices are evidence for review, not a legal conclusion. `NOASSERTION` is retained when installed package metadata lacks a license value.

## Installer And Updater Foundations

The existing installation broker remains simulation-only. The existing updater policy remains offline-only: it can validate committed fixture metadata and package hashes, but cannot query a release, download, stage, activate, roll back, or modify a machine. The portable package adds no call path to either foundation.

Signing, notarization, installer creation, public release publication, automatic updates, and production-readiness claims remain explicit stop gates.
