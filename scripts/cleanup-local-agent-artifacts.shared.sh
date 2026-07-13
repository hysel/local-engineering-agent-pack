#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_REPO="$REPO_ROOT"
OUTPUT_PATH=""
APPLY=0
AS_JSON=0
INCLUDE_RUNTIME=0
INCLUDE_SAMPLES=0
INCLUDE_BACKUPS=0
INCLUDE_FAILED=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target-repo|-TargetRepo)
      TARGET_REPO="$2"
      shift 2
      ;;
    --output-path|-OutputPath)
      OUTPUT_PATH="$2"
      shift 2
      ;;
    --apply|-Apply)
      APPLY=1
      shift
      ;;
    --as-json|-AsJson)
      AS_JSON=1
      shift
      ;;
    --include-runtime-output|-IncludeRuntimeOutput)
      INCLUDE_RUNTIME=1
      shift
      ;;
    --include-generated-samples|-IncludeGeneratedSamples)
      INCLUDE_SAMPLES=1
      shift
      ;;
    --include-backups|-IncludeBackups)
      INCLUDE_BACKUPS=1
      shift
      ;;
    --include-failed-reports|-IncludeFailedReports)
      INCLUDE_FAILED=1
      shift
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

if [ "$INCLUDE_RUNTIME$INCLUDE_SAMPLES$INCLUDE_BACKUPS$INCLUDE_FAILED" = "0000" ]; then
  INCLUDE_RUNTIME=1
  INCLUDE_SAMPLES=1
  INCLUDE_BACKUPS=1
  INCLUDE_FAILED=1
fi

[ -d "$TARGET_REPO" ] || {
  printf 'Target repository path does not exist: %s\n' "$TARGET_REPO" >&2
  exit 1
}

TARGET_REPO="$(cd "$TARGET_REPO" && pwd)"
ITEMS=""

add_item() {
  category="$1"
  path="$2"
  reason="$3"
  [ -e "$path" ] || return 0
  case "$(cd "$(dirname "$path")" && pwd)/$(basename "$path")" in
    "$TARGET_REPO"/*) ;;
    *) printf 'Refusing to plan path outside target repository: %s\n' "$path" >&2; exit 1 ;;
  esac
  if [ -d "$path" ]; then
    type="directory"
    count="$(find "$path" -type f 2>/dev/null | wc -l | tr -d ' ')"
  else
    type="file"
    count="1"
  fi
  rel="${path#$TARGET_REPO/}"
  ITEMS="${ITEMS}${category}|${path}|${rel}|${type}|${count}|${reason}|false
"
}

if [ "$INCLUDE_RUNTIME" -eq 1 ]; then
  add_item "runtime-output" "$TARGET_REPO/runtime-validation-output" "Ignored runtime validation output can be regenerated."
fi

if [ "$INCLUDE_SAMPLES" -eq 1 ] && [ "$INCLUDE_RUNTIME" -eq 0 ]; then
  add_item "generated-samples" "$TARGET_REPO/runtime-validation-output/sample-repositories" "Generated sample repositories are disposable validation fixtures."
fi

if [ "$INCLUDE_BACKUPS" -eq 1 ]; then
  for path in "$TARGET_REPO"/.continue.backup-* "$TARGET_REPO"/*.backup-*; do
    [ -e "$path" ] || continue
    add_item "backup" "$path" "Installer or generated config backup can be removed after review."
  done
fi

if [ "$INCLUDE_FAILED" -eq 1 ] && [ "$INCLUDE_RUNTIME" -eq 0 ] && [ -d "$TARGET_REPO/runtime-validation-output" ]; then
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    add_item "failed-report" "$path" "Failed validation artifact is local diagnostic output."
  done <<EOF
$(find "$TARGET_REPO/runtime-validation-output" -type f \( -name '*failed*' -o -name '*.filename-fidelity-fallback.md' \) 2>/dev/null)
EOF
fi

ITEM_COUNT="$(printf '%s' "$ITEMS" | awk 'NF { count++ } END { print count + 0 }')"

if [ "$APPLY" -eq 1 ]; then
  while IFS='|' read -r category full rel type count reason removed; do
    [ -n "$full" ] || continue
    case "$full" in "$TARGET_REPO"/*) rm -rf "$full" ;; *) exit 1 ;; esac
  done <<EOF
$ITEMS
EOF
fi

json_report() {
  printf '{\n'
  printf '  "SchemaVersion": 1,\n'
  printf '  "TargetRepoChecked": true,\n'
  printf '  "Applied": %s,\n' "$([ "$APPLY" -eq 1 ] && printf true || printf false)"
  printf '  "ItemCount": %s,\n' "$ITEM_COUNT"
  printf '  "Items": [\n'
  first=1
  while IFS='|' read -r category full rel type count reason removed; do
    [ -n "$category" ] || continue
    [ "$first" -eq 0 ] && printf ',\n'
    first=0
    printf '    {"Category":"%s","Path":"%s","Type":"%s","FileCount":%s,"Reason":"%s","Removed":%s}' "$category" "$rel" "$type" "$count" "$reason" "$([ "$APPLY" -eq 1 ] && printf true || printf false)"
  done <<EOF
$ITEMS
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
  if [ "$APPLY" -eq 1 ]; then
    printf 'Cleanup applied. Removed %s item(s).\n' "$ITEM_COUNT"
  else
    printf 'Dry run only. Would remove %s item(s). Use --apply to remove planned items.\n' "$ITEM_COUNT"
  fi
fi
