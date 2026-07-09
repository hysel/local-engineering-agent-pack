#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/test-agent-cli-surface-models.shared.sh" \
  --surface-name "Kilo Code" \
  --surface-key "kilo-code-cli" \
  --agent-command "kilo-code" \
  --agent-arguments-template '--task "{Prompt}"' \
  --model-argument-template '--model "{Model}"' \
  --install-hint "Install or configure Kilo Code CLI if available, or pass the command/template override. Editor extension validation is separate." \
  "$@"
