#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/test-agent-cli-surface-models.shared.sh" \
  --surface-name "OpenCode" \
  --surface-key "opencode-cli" \
  --agent-command "opencode" \
  --agent-arguments-template 'run "{Prompt}"' \
  --model-argument-template '--model "{Model}"' \
  --install-hint "Install OpenCode or pass the command/template override." \
  "$@"
