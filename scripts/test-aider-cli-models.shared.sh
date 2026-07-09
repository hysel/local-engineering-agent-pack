#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/test-agent-cli-surface-models.shared.sh" \
  --surface-name "Aider CLI" \
  --surface-key "aider-cli" \
  --agent-command "aider" \
  --agent-arguments-template '--message "{Prompt}" --yes-always --no-auto-commits' \
  --model-argument-template '--model "ollama_chat/{Model}"' \
  --install-hint "Install with pipx install aider-chat or pass the command override." \
  "$@"
