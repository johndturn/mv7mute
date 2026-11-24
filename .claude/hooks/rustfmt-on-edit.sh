#!/usr/bin/env bash
# PostToolUse hook for Edit/Write/MultiEdit: format the edited Rust file.
set -euo pipefail
file="$(jq -r '.tool_input.file_path // ""')"
case "$file" in
  *.rs) [ -f "$file" ] && rustfmt --edition 2024 "$file" 2>&1 >/dev/null | head -20 >&2 || true ;;
esac
exit 0
