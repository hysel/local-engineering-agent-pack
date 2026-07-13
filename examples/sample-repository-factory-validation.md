# Sample Repository Factory Validation Evidence

This file records sanitized validation evidence for generated sample repositories.

Do not include private repository names, private paths, private endpoints, usernames, hostnames, tokens, raw private source code, or raw transcripts.

## 2026-07-05 Initial Factory Validation

### Summary

- Validation type: Generated sample repository factory smoke test
- Repository categories: Python API sample, TypeScript frontend sample
- Operating system: Windows
- Editor surface: Not used for this evidence entry
- Continue version: Not used for this evidence entry
- Model: Not used for this evidence entry
- Provider: Not used for this evidence entry
- MCP state: Not used
- Pack version or commit: `0.2.0` plus sample factory implementation

### Setup

- Generated samples with the PowerShell sample repository factory using overwrite mode.
- Installed the pack into the generated Python API sample after dry-run preview.
- Installed the pack into the generated TypeScript frontend sample after dry-run preview.
- Generated runtime context files for both samples.
- Kept generated sample repositories and runtime context files under ignored runtime output.

### Results

| Sample | Factory generation | Pack install dry run | Pack install | Runtime context generation | Notes |
| --- | --- | --- | --- | --- | --- |
| `python-api` | Passed | Passed | Passed | Passed | Validates Python API repository shape and installed pack references. |
| `typescript-frontend` | Passed | Passed | Passed | Passed | Validates TypeScript frontend repository shape and installed pack references. |

### Tool Validation

- File listing worked: Not applicable; this entry validates scripts, not editor Agent tools.
- File content reading worked: Runtime context generation completed for both samples.
- Current-folder path resolution worked: Not applicable; no editor Agent write was performed.
- Apply target matched intended file: Not applicable; no approved write was performed.
- External shell or git verification passed: Yes, script exit codes were successful.
- Failure signals: None observed during script validation.

### Findings

1. The factory can create deterministic disposable validation repositories without needing additional real repositories.
2. The installer can copy the pack into generated samples after dry-run preview.
3. Runtime context generation can inspect generated Python and TypeScript sample repositories.
4. This evidence does not prove model or editor Agent behavior; those still require editor-based read-only and approved-write validation.

### Pack Follow-Up

- Prompt updates needed: None from this script-only validation pass.
- Rule updates needed: None from this script-only validation pass.
- Documentation updates needed: Keep sample factory docs linked from README, wiki, and roadmap.
- Script or test updates needed: None; validation and tests already cover factory shape and script behavior.
- No-change rationale: This evidence only records the first generated-sample smoke test. Model/editor validation should be recorded separately.

### Sanitization Checklist

- [x] No private repository names.
- [x] No private local paths.
- [x] No private endpoints, IP addresses, or hostnames.
- [x] No usernames.
- [x] No tokens or secrets.
- [x] No raw private source code.
- [x] No raw transcripts.
- [x] No customer, employer, or internal project identifiers.

## 2026-07-13 Generated Category Expansion Validation

### Summary

- Validation type: Generated sample repository category expansion
- Repository categories: Node service, Java/Spring API, Go service, Rust CLI, Infrastructure as Code, SQL migrations
- Operating system: Windows with Bash-compatible shell checks
- Editor surface: Not used for this evidence entry
- Continue version: Not used for this evidence entry
- Model: Not used for this evidence entry
- Provider: Not used
- MCP state: Not used
- Pack version or commit: `0.2.0` development branch after cross-platform workflow dispatcher work

### Setup

- Generated disposable samples with the PowerShell sample repository factory.
- Verified the generated fixture list includes Python, TypeScript, Node, Java, Go, Rust, Infrastructure as Code, and SQL samples.
- Generated runtime context for representative non-Python/non-TypeScript samples.
- Kept generated files under ignored runtime output or temporary test directories.

### Results

| Sample | Category | Factory generation | Runtime context generation | Grounding signals |
| --- | --- | --- | --- | --- |
| `node-service` | Service repository | Passed | Passed | `package.json`, `Dockerfile`, `src/server.js` |
| `java-spring-api` | Java API repository | Passed | Covered by fixture-shape tests | `pom.xml`, `HealthController.java`, `application.properties` |
| `go-service` | Go service repository | Passed | Covered by fixture-shape tests | `go.mod`, `cmd/server/main.go`, `cmd/server/main_test.go` |
| `rust-cli` | Rust CLI repository | Passed | Covered by fixture-shape tests | `Cargo.toml`, `src/main.rs` |
| `iac-terraform-kubernetes` | Infrastructure repository | Passed | Passed | `terraform/main.tf`, `k8s/deployment.yaml`, `.github/workflows/validate.yml` |
| `sql-migrations` | Database migration repository | Passed | Passed | `schema/001_create_items.sql`, `migrations/002_add_item_status.sql`, `seeds/items.sql` |

### Tool Validation

- File listing worked: Not applicable; this entry validates deterministic generated samples and runtime context, not editor Agent tools.
- File content reading worked: Runtime context generation included representative files for Node, Infrastructure as Code, and SQL samples.
- Current-folder path resolution worked: Not applicable; no editor Agent write was performed.
- Apply target matched intended file: Not applicable; no approved write was performed.
- External shell or git verification passed: Yes, validation and pack tests passed with generated fixture checks.
- Failure signals: None observed during script-level generated-category validation.

### Pack Follow-Up

- Prompt updates needed: None from this script-level validation pass.
- Rule updates needed: None from this script-level validation pass.
- Documentation updates needed: Milestone 13 can treat generated category coverage as available when real repositories are not available.
- Script or test updates needed: Keep fixture-shape and runtime-context assertions for the expanded sample categories.
- Remaining validation: Model/editor repository-discovery, implementation-planning, code-review, and approved-write validation still require separate evidence before promoting language or agent support.

### Sanitization Checklist

- [x] No private repository names.
- [x] No private local paths.
- [x] No private endpoints, IP addresses, or hostnames.
- [x] No usernames.
- [x] No tokens or secrets.
- [x] No raw private source code.
- [x] No raw transcripts.
- [x] No customer, employer, or internal project identifiers.

## 2026-07-05 Focused CLI Repository Discovery Validation

### Summary

- Validation type: Focused Continue CLI repository-discovery validation with supplied runtime context
- Repository categories: Python API sample, TypeScript frontend sample
- Operating system: Windows
- Editor surface: Not used for this evidence entry
- Continue version: CLI path through `npx @continuedev/cli`
- Model: Local Ollama coding model through ignored local-only config
- Provider: Ollama-compatible local endpoint, endpoint omitted
- MCP state: Not used
- Pack version or commit: `0.2.0` development branch after sample factory and runtime context fixes

### Setup

- Regenerated disposable samples under ignored runtime output.
- Installed the pack into the generated Python API and TypeScript frontend samples.
- Regenerated runtime context files for both samples.
- Ran repository discovery through Continue CLI in read-only mode using supplied context only.
- Saved raw CLI outputs only under ignored runtime output.

### Results

| Sample | CLI exit | Final text produced | Exact file signals | Notes |
| --- | --- | --- | --- | --- |
| `python-api` | Passed | Passed | `README.md`, `app/main.py`, `app/settings.py`, `tests/test_main.py` | Output identified the sample and key files. It still lightly inferred standard Python dependency context, so this is read-only discovery evidence, not dependency-analysis proof. |
| `typescript-frontend` | Passed | Passed | `package.json`, `README.md`, `tsconfig.json`, `src/App.tsx`, `src/app.test.ts` | After adding project metadata excerpts to runtime context, output correctly identified Vite, Vitest, scripts, and dependencies. It still used placeholder-style language for the source file, so deeper workflow validation remains pending. |

### Findings

1. The PowerShell sample factory had a README generation bug: Markdown command backticks inside a double-quoted here-string caused factory script text to leak into the generated Python sample README.
2. The factory was fixed by using a single-quoted here-string for the Python README.
3. Regression checks now assert generated sample README and source files do not contain factory script text or here-string markers.
4. Runtime context generation previously inherited parent repository git status when a target sample lived under this repository's ignored runtime folder.
5. Runtime context generation now records parent-repository containment explicitly and falls back to target-local file enumeration instead of parent git metadata.
6. Runtime context generation now includes common multi-language project metadata excerpts such as `package.json`, improving TypeScript grounding.

### Tool Validation

- File listing worked: Not applicable; CLI was instructed to use supplied context only.
- File content reading worked: Runtime context generation included README and project metadata excerpts.
- Current-folder path resolution worked: Not applicable; no editor Agent write was performed.
- Apply target matched intended file: Not applicable; no approved write was performed.
- External shell or git verification passed: Yes, script exit codes and regenerated fixture checks passed before evidence was recorded.
- Failure signals: No raw tool-call-only output observed in the focused CLI path. Minor output-quality caveats remain as noted above.

### Pack Follow-Up

- Prompt updates needed: Keep evidence-fidelity guardrails for language/framework claims.
- Rule updates needed: None from this validation pass.
- Documentation updates needed: Record that generated samples are suitable for focused read-only CLI validation but do not replace editor approved-write validation.
- Script or test updates needed: Completed for the factory escaping bug, generated fixture leakage checks, parent git-status isolation, and multi-language metadata excerpts.
- Remaining validation: Run implementation-planning and code-review workflows against generated Python and TypeScript samples before marking multi-language workflow validation complete.

### Sanitization Checklist

- [x] No private repository names.
- [x] No private local paths.
- [x] No private endpoints, IP addresses, or hostnames.
- [x] No usernames.
- [x] No tokens or secrets.
- [x] No raw private source code.
- [x] No raw transcripts.
- [x] No customer, employer, or internal project identifiers.
