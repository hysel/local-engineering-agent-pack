#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/test-agent-cli-surface-models.shared.sh" \
  --surface-name "Roo Code" \
  --surface-key "roo-code-cli" \
  --agent-command "roo-code" \
  --agent-arguments-template '--task "{Prompt}"' \
  --model-argument-template '--model "{Model}"' \
  --install-hint "Install or configure Roo Code CLI if available, or pass the command/template override. Editor extension validation is separate." \
  "$@"
