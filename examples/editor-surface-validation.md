# Editor Surface Validation Evidence

This file records sanitized editor-surface validation evidence for this pack. It should not include private endpoints, local paths, usernames, raw transcripts, private repository names, or customer names.

## 2026-07-03 Windows Editor Preflight

### Summary

- Date: 2026-07-03
- Operating system: Windows
- CPU architecture: x64
- Repository state: clean before validation
- Config source tested: project-local `.continue/config.yaml`
- Private details removed: Yes

### Detected Editor Surfaces

| Surface | Detection result | Version | Continue extension | Status |
| --- | --- | --- | --- | --- |
| VS Code-compatible build | Found on `PATH` as `code` | 1.125.1 | `continue.continue@2.0.0` | Extension installed; GUI config loading not proven by terminal preflight. |
| VSCodium | Found on `PATH` as `codium` | 1.121.03429 | `continue.continue@2.1.0` | Extension installed; GUI config loading not proven by terminal preflight. |

### CLI Fallback Check

Command shape:

```powershell
npx -y @continuedev/cli --config .continue/config.yaml --readonly -p "Reply OK"
```

Result:

- Status: Failed
- Observed behavior: CLI returned a model connection error.
- Interpretation: The CLI command reached the model-backed execution path but could not connect to the model provider from the current shell using the committed shared config.
- Safe fallback: Confirm Ollama is running, confirm the starter model is installed, or use an ignored local config override for machine-specific endpoints.

### Decision

- VS Code-compatible build: Candidate editor surface. Continue extension is installed, but project-local config loading and Agent tools still require in-editor validation.
- VSCodium: Candidate editor surface. Continue extension is installed, but project-local config loading and Agent tools still require in-editor validation.
- Continue CLI: Not validated for model-backed execution in this run because the provider connection failed.

### Follow-Up

- Run the read-only editor test in VS Code-compatible build.
- Run the read-only editor test in VSCodium.
- Run the Agent tool test separately in each editor.
- Record whether duplicate-rule warnings appear.
- Record whether the model executes tools or prints raw JSON tool calls.

### Sanitization Checklist

- [x] No private endpoints.
- [x] No private IP addresses.
- [x] No local filesystem paths.
- [x] No usernames.
- [x] No private repository names.
- [x] No customer names.
- [x] No tokens or secrets.
- [x] No raw private-code transcript.
