# Cline Read-Only Validation Evidence

This file records sanitized Cline validation results. It starts as a template. Do not mark Cline validated until a real read-only run is completed and externally verified.

## Status

| Field | Value |
| --- | --- |
| Surface | Cline |
| Current status | Candidate only |
| Approved-write status | Blocked |
| Evidence state | Template ready; validation run not yet recorded |

## Validation Record Template

Copy this section for each validation run.

### YYYY-MM-DD Cline Read-Only Generated Sample Test

#### Summary

- Date: YYYY-MM-DD
- Surface: Cline
- Surface version: Not recorded
- Editor host: Not recorded
- Operating system: Not recorded
- CPU architecture: Not recorded
- Model: Not recorded
- Provider: Not recorded
- Config source: Not recorded
- Sample repository: Not recorded
- Tool permission mode: Read-only requested
- MCP state: Not recorded
- Private details removed: Yes

#### Prompt Used

```text
Use tools to inspect the opened repository root.

Do not modify files.
Do not create files.
Do not run package installation.
Do not guess.

Return:
1. The exact top-level files and folders you inspected.
2. The project type, based only on files you actually read.
3. The key source and test files you inspected.
4. Any risks or missing information.
5. The failure signal if tools are unavailable.

If tools are unavailable, say TOOLS_UNAVAILABLE.
```

#### Observed Files

| Evidence | Result |
| --- | --- |
| Exact top-level names listed | Not recorded |
| Project marker files read | Not recorded |
| Source files read | Not recorded |
| Test files read | Not recorded |
| Invented files observed | Not recorded |

#### External Verification

| Check | Result |
| --- | --- |
| `git status --short` before test | Not recorded |
| `git status --short` after test | Not recorded |
| `git diff --check` after test | Not recorded |
| Unexpected files created | Not recorded |
| Private details removed | Not recorded |

#### Decision

- Status: Candidate only
- Failure signal: Not recorded
- Promotion decision: Do not promote until the run is completed and externally verified.

## Sanitization Checklist

- [ ] No private endpoints.
- [ ] No private IP addresses.
- [ ] No local filesystem paths.
- [ ] No usernames.
- [ ] No private repository names.
- [ ] No customer names.
- [ ] No tokens or secrets.
- [ ] No raw private-code transcript.
## 2026-07-08 Cline Read-Only Generated Python Sample Test

### Summary

- Date: 2026-07-08
- Surface: Cline
- Surface version: Not recorded
- Editor host: VS Code-compatible editor, exact host not recorded
- Operating system: Windows
- CPU architecture: Not recorded
- Model: `devstral-small-2:24b`
- Provider: Ollama
- Config source: Cline local model configuration, exact config source not recorded
- Sample repository: generated `python-api` sample
- Tool permission mode: Read-only requested
- MCP state: Not recorded
- Private details removed: Yes

### Prompt Used

```text
Use tools to inspect the opened repository root.

Do not modify files.
Do not create files.
Do not run package installation.
Do not guess.

Return:
1. The exact top-level files and folders you inspected.
2. The project type, based only on files you actually read.
3. The key source and test files you inspected.
4. Any risks or missing information.
5. The failure signal if tools are unavailable.

If tools are unavailable, say TOOLS_UNAVAILABLE.
```

### Observed Result

The response announced an intent to inspect files and printed a `list_files` tool-call shape containing a local absolute path. It then switched to a generic task-planning response and asked the user to provide a task, instead of completing the requested repository inspection.

### Observed Files

| Evidence | Result |
| --- | --- |
| Exact top-level names listed | No |
| Project marker files read | No |
| Source files read | No |
| Test files read | No |
| Invented files observed | No generic invented repository structure observed, but the requested inspection did not complete. |

### External Verification

| Check | Result |
| --- | --- |
| `git status --short` after test | Clean |
| `git diff --check` after test | Clean |
| Unexpected files created | No |
| Private details removed | Yes |

### Decision

- Status: Candidate only
- Failure signal: `RAW_TOOL_CALL_OUTPUT`
- Secondary signal: `READ_TOOLS_UNAVAILABLE`
- Promotion decision: Do not promote Cline to read-only validated from this run. Retest only after Cline tool execution is configured so file listing and file reads complete without printed tool-call syntax or task reset behavior.
