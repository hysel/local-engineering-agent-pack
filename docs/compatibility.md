# Compatibility Notes

## Purpose

This document records compatibility expectations for Continue, local models, Ollama, MCP, and SonarQube-related workflows.

## Continue

The pack targets Continue YAML configuration with:

```yaml
schema: v1
```

Compatibility expectations:

- Continue can load `.continue/config.yaml`.
- Local prompts, rules, agents, and templates are referenced by repository-relative paths.
- MCP remains optional and disabled by default.
- MCP workflows require Continue agent mode.

## Editor Surfaces

The pack should work in both VS Code and VSCodium when the Continue extension can load the project-local `.continue/config.yaml`.

Expected differences:

- VS Code usually installs extensions from Microsoft's Marketplace.
- VSCodium usually installs extensions from Open VSX.
- Continue extension versions may differ between the two editors.
- Command palette names and availability may differ by extension version.
- User/global Continue config locations can differ by editor and operating system.
- Marketplace, authentication, telemetry, GitHub, and MCP-related flows may behave differently.

Recommended setup:

- Prefer the project-local `.continue/config.yaml` after installing this pack into a target repository.
- Avoid loading the same rules from both a global Continue config and the project-local `.continue` folder.
- Record the editor name, Continue extension version, operating system, and model when debugging behavior.
- Validate Agent mode and tool execution separately in VS Code and VSCodium when a workflow depends on tools.
- Keep `npx @continuedev/cli --config .continue/config.yaml` as a fallback when editor behavior is unclear.

Known risk:

- Duplicate rule warnings usually mean the same rule files are being loaded from more than one config source.
- Raw JSON tool-call output usually indicates a model/tool-execution mismatch, not a file patch.

## Ollama And Local Models

Default model assumptions:

- Chat/edit/apply/tool workflows: `qwen3-coder:30b`
- Embeddings: `nomic-embed-text`

Expected local setup:

```powershell
ollama pull qwen3-coder:30b
ollama pull nomic-embed-text
```

Tool-use guidance:

- `qwen3-coder:30b` is the current validated default for Agent mode tool execution in the tested VSCodium, Continue, and Ollama setup.
- `qwen2.5-coder:7b` may still be useful as a lightweight chat or planning model, but it produced raw JSON tool-call text instead of executable tool calls in validation.
- When a model prints tool-call JSON instead of executing tools, use the runtime-context fallback workflow in `docs/troubleshooting.md`.
- Use `docs/local-model-selection.md` before changing the committed default model or recommending a different local model tier.

Endpoint guidance:

- Use Continue's default local Ollama behavior for committed config.
- Use custom `apiBase` values only as local machine overrides.
- Do not commit private IP addresses, local hostnames, VPN endpoints, or machine-specific ports.

## MCP

Default configuration:

```yaml
mcpServers: []
```

Compatibility expectations:

- The pack works without MCP.
- Optional MCP setup is documented separately.
- Local `stdio` MCP servers are preferred for first adoption.
- Remote MCP transports require additional security review.
- MCP-derived evidence should be identified separately in review output.

## SonarQube

Supported documentation targets:

- SonarQube Server
- SonarQube Community Build
- SonarQube Cloud

Compatibility expectations:

- Manual SonarQube triage works without API access.
- Web API automation uses environment variables and read-only access.
- SonarQube MCP remains optional until validated.
- SonarQube hostnames, project keys, organization keys, and tokens are not committed.

## Operating System

The pack is documentation and configuration heavy, so it should remain broadly portable.

Validated and documented command examples should include Windows PowerShell plus Linux and macOS shell variants where the commands differ.

When adding commands:

- Prefer cross-platform commands where practical.
- Label shell-specific examples.
- Avoid paths that depend on one user's home directory.

## Line Endings

Git may report LF-to-CRLF normalization warnings on Windows.

These warnings do not automatically indicate a content problem, but contributors should avoid unrelated line-ending churn when editing files.

## Validation Checklist

- [ ] Continue loads `.continue/config.yaml`.
- [ ] VS Code or VSCodium is using the intended project-local config.
- [ ] Required prompt, rule, agent, and template files exist.
- [ ] Local Ollama models are available or documented as setup prerequisites.
- [ ] No committed machine-specific endpoint values are present.
- [ ] MCP remains disabled unless explicitly configured by the user.
- [ ] SonarQube guidance avoids committed secrets and private identifiers.
