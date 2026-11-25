#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle MV7 Mute
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🎙️
# @raycast.packageName MV7
# @raycast.description Toggle the Shure MV7's own mute (same as the touch pad; the LED follows).

# Raycast runs scripts with a minimal PATH, so the binary is called by absolute path
# (AGENTS.md, "Local install"). MV7MUTE_BIN overrides it for tests (test.sh).
set -uo pipefail

bin="${MV7MUTE_BIN:-$HOME/.local/bin/mv7mute}"

if [ ! -x "$bin" ]; then
  echo "mv7mute not found or not executable: $bin"
  exit 1
fi

out="$("$bin" toggle 2>&1)"
code=$?
last="${out##*$'\n'}" # the CLI prints one line: muted | unmuted | Error: ...

if [ "$code" -ne 0 ]; then
  echo "$last"
  exit 1
fi

case "$last" in
  muted) echo "Muted" ;;
  unmuted) echo "Unmuted" ;;
  *)
    echo "Unexpected output from mv7mute: $last"
    exit 1
    ;;
esac
