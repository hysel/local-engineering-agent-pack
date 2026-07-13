#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
EXPECTED_VERSION="0.2.0"
OUTPUT_PATH=""
AS_JSON=0
ALLOW_DIRTY=0
SKIP_VALIDATION=0
SKIP_TESTS=0
SKIP_PACKAGE=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --expected-version|-ExpectedVersion)
      EXPECTED_VERSION="$2"
      shift 2
      ;;
    --output-path|-OutputPath)
      OUTPUT_PATH="$2"
      shift 2
      ;;
    --as-json|-AsJson)
      AS_JSON=1
      shift
      ;;
    --allow-dirty|-AllowDirty)
      ALLOW_DIRTY=1
      shift
      ;;
    --skip-validation|-SkipValidation)
      SKIP_VALIDATION=1
      shift
      ;;
    --skip-tests|-SkipTests)
      SKIP_TESTS=1
      shift
      ;;
    --skip-package-dry-run|-SkipPackageDryRun)
      SKIP_PACKAGE=1
      shift
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

CHECKS=""
OVERALL="pass"

add_check() {
  id="$1"
  name="$2"
  status="$3"
  message="$4"
  CHECKS="${CHECKS}${id}|${name}|${status}|${message}
"
  if [ "$status" = "fail" ]; then
    OVERALL="fail"
  elif [ "$status" = "warn" ] && [ "$OVERALL" = "pass" ]; then
    OVERALL="warn"
  fi
}

run_command_check() {
  id="$1"
  name="$2"
  skip="$3"
  shift 3
  if [ "$skip" -eq 1 ]; then
    add_check "$id" "$name" "skip" "Skipped by request."
    return 0
  fi
  output="$("$@" 2>&1)"
  exit_code="$?"
  if [ "$exit_code" -eq 0 ]; then
    add_check "$id" "$name" "pass" "Command completed successfully."
  else
    add_check "$id" "$name" "fail" "Command failed."
  fi
}

status="$(git -C "$REPO_ROOT" status --short --branch 2>/dev/null)"
if [ "$?" -ne 0 ]; then
  add_check "git.status" "Git Status" "fail" "Git status failed."
else
  changes="$(printf '%s\n' "$status" | tail -n +2)"
  branch="$(printf '%s\n' "$status" | head -n 1)"
  if [ -n "$changes" ] && [ "$ALLOW_DIRTY" -ne 1 ]; then
    add_check "git.status" "Git Status" "fail" "Working tree has uncommitted changes."
  elif printf '%s\n' "$branch" | grep -Eq '\[(ahead|behind|diverged)'; then
    add_check "git.status" "Git Status" "warn" "Branch is not fully synced with upstream."
  elif [ -n "$changes" ]; then
    add_check "git.status" "Git Status" "warn" "Working tree has local changes; allowed for this run."
  else
    add_check "git.status" "Git Status" "pass" "Working tree is clean and branch appears synced."
  fi
fi

if grep -q '"schemaVersion"' "$REPO_ROOT/config/workflows.json"; then
  add_check "workflow.registry" "Workflow Registry" "pass" "JSON file includes schema version."
else
  add_check "workflow.registry" "Workflow Registry" "fail" "Workflow registry is missing schema version."
fi

if grep -q '"schemaVersion"' "$REPO_ROOT/config/agent-surface-capabilities.json"; then
  add_check "surface.parity" "Agent Surface Parity Matrix" "pass" "JSON file includes schema version."
else
  add_check "surface.parity" "Agent Surface Parity Matrix" "fail" "Agent surface parity matrix is missing schema version."
fi

run_command_check "validate-pack" "Pack Validation" "$SKIP_VALIDATION" "$REPO_ROOT/scripts/validate-pack.shared.sh" --expected-version "$EXPECTED_VERSION"
run_command_check "test-pack" "Pack Tests" "$SKIP_TESTS" "$REPO_ROOT/scripts/test-pack.shared.sh"
run_command_check "release-package-dry-run" "Release Package Dry Run" "$SKIP_PACKAGE" "$REPO_ROOT/scripts/build-release-package.shared.sh" --dry-run --allow-dirty

json_report() {
  printf '{\n'
  printf '  "SchemaVersion": 1,\n'
  printf '  "OverallStatus": "%s",\n' "$OVERALL"
  printf '  "ExpectedVersion": "%s",\n' "$EXPECTED_VERSION"
  printf '  "Checks": [\n'
  first=1
  while IFS='|' read -r id name status message; do
    [ -n "$id" ] || continue
    [ "$first" -eq 0 ] && printf ',\n'
    first=0
    printf '    {"Id":"%s","Name":"%s","Status":"%s","Message":"%s"}' "$id" "$name" "$status" "$message"
  done <<EOF
$CHECKS
EOF
  printf '\n  ]\n'
  printf '}\n'
}

if [ -n "$OUTPUT_PATH" ]; then
  mkdir -p "$(dirname "$OUTPUT_PATH")"
  json_report > "$OUTPUT_PATH"
fi

if [ "$AS_JSON" -eq 1 ] || [ -n "$OUTPUT_PATH" ]; then
  json_report
else
  printf 'Overall: %s\n' "$OVERALL"
  printf '%s' "$CHECKS" | while IFS='|' read -r id name status message; do
    [ -n "$id" ] || continue
    printf '%s %s: %s\n' "$status" "$name" "$message"
  done
fi

[ "$OVERALL" != "fail" ]
