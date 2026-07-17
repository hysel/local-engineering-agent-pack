# MLX Model Validation Evidence

This record captures a bounded native Apple Silicon validation of a local MLX
server. It is sanitized and intentionally does not include machine paths,
addresses, credentials, or raw model transcripts.

## Environment

- Platform: native macOS on Apple Silicon.
- Runtime: `mlx-lm` 0.31.3 installed in a Python 3.12 virtual environment.
- Model: `mlx-community/Qwen3.5-9B-OptiQ-4bit`.
- Server: local OpenAI-compatible MLX endpoint bound to loopback only.
- Agent surface: Continue CLI 1.5.47.

## Results

| Capability | Result | External verification | Boundary |
| --- | --- | --- | --- |
| OpenAI-compatible structured tool call | Passed | The endpoint returned a required function call with valid JSON arguments. | Endpoint-level evidence only. |
| Continue CLI read tooling | Passed | The response referenced repository files inspected through the disposable fixture. | Does not prove editor Agent behavior. |
| Continue CLI implementation plan | Passed | The JSON response referenced the scenario and service files; Git stayed clean. | Read-only generated-sample evidence only. |
| Continue CLI code review | Passed | The JSON response referenced the service and test files; Git stayed clean. | Read-only generated-sample evidence only. |
| Continue CLI scoped write smoke | Passed | Only `README.md` changed, the exact final marker was present once, and `git diff --check` passed before cleanup. | One-file disposable write only; not broad approved-write or editor evidence. |

## Outcome

The tested model is a validated MLX candidate for bounded Continue CLI read,
planning, review, and disposable scoped-write smoke workflows on an Apple
Silicon host. It must be revalidated for a different MLX quantization, server
version, Continue version, editor surface, repository type, or write scope.
