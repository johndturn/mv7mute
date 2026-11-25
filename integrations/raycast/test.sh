#!/usr/bin/env bash
# Tests mv7-toggle-mute.sh against stub binaries. Never touches the microphone.
# Usage: integrations/raycast/test.sh
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
script="$here/mv7-toggle-mute.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

stub() { # stub <name> <stdout line or ''> <stderr line or ''> <exit>
  cat >"$tmp/$1" <<EOF
#!/bin/sh
[ "\$1" = toggle ] || { echo "stub: expected toggle, got \$1" >&2; exit 99; }
[ -n "$3" ] && echo "$3" >&2
[ -n "$2" ] && echo "$2"
exit $4
EOF
  chmod +x "$tmp/$1"
}

fail=0
check() { # check <name> <binary> <want stdout> <want exit>
  local out code
  set +e
  out="$(MV7MUTE_BIN="$2" "$script" 2>/dev/null)"
  code=$?
  set -e
  if [ "$out" = "$3" ] && [ "$code" -eq "$4" ]; then
    echo "ok   $1"
  else
    echo "FAIL $1: got exit $code, output '$out'; want exit $4, output '$3'"
    fail=1
  fi
}

stub muted muted '' 0
stub unmuted unmuted '' 0
stub error '' 'Error: MV7 not found' 1
stub weird 'something else' '' 0
stub warned muted 'warning: something on stderr' 0

check "muted -> HUD 'Muted'" "$tmp/muted" "Muted" 0
check "unmuted -> HUD 'Unmuted'" "$tmp/unmuted" "Unmuted" 0
check "CLI error -> error line, exit 1" "$tmp/error" "Error: MV7 not found" 1
check "unexpected output -> exit 1" "$tmp/weird" "Unexpected output from mv7mute: something else" 1
check "stderr noise before 'muted' -> HUD 'Muted'" "$tmp/warned" "Muted" 0
check "missing binary -> exit 1" "$tmp/does-not-exist" "mv7mute not found or not executable: $tmp/does-not-exist" 1

exit "$fail"
