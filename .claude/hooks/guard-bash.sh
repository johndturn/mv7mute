#!/usr/bin/env bash
# PreToolUse hook for Bash. Blocks commands that would publish, leak, or touch
# someone else's repo. Exit 2 = block (stderr goes back to the agent).
set -euo pipefail
cmd="$(jq -r '.tool_input.command // ""')"

block() { echo "guard-bash: $1" >&2; exit 2; }

# Interactive TUI that never returns.
if printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])bv([[:space:]]*($|[;&|]))'; then
  block "bare 'bv' opens an interactive TUI and hangs the session. Use 'bv --robot-next', 'bv --robot-triage' or 'bv --robot-plan'."
fi

# Publishing.
printf '%s' "$cmd" | grep -Eq 'cargo[[:space:]]+(publish|release)|release-plz|cargo[[:space:]]+dist' \
  && block "publishing/releasing is out of scope for this personal fork."

# Upstream is read-only.
printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+push[^;&|]*[[:space:]]upstream' \
  && block "never push to upstream (Justkant/mv7mute). Push to origin (johndturn/mv7mute)."
printf '%s' "$cmd" | grep -Eq 'gh[[:space:]]+(pr|issue)[[:space:]]+(create|comment|edit|close|merge|review)[^;&|]*(Justkant|-R[[:space:]]+Justkant)' \
  && block "acting on Justkant/mv7mute is outward-facing. Ask the maintainer to approve and run it."

# gh defaults to the parent repo for forks unless the default is set; require it.
if printf '%s' "$cmd" | grep -Eq 'gh[[:space:]]+pr[[:space:]]+create'; then
  if ! printf '%s' "$cmd" | grep -Eq -- '(--repo|-R)[[:space:]=]+johndturn/mv7mute'; then
    default="$(gh repo set-default --view 2>/dev/null || true)"
    [ "$default" = "johndturn/mv7mute" ] || block "gh pr create must target the fork: add --repo johndturn/mv7mute --base main (or run scripts/setup-dev.sh)."
  fi
fi

# Release tags and history rewrites on shared branches.
printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+push[^;&|]*(--tags|[[:space:]]v[0-9])' \
  && block "do not push tags; v* tags trigger release tooling upstream."
printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+push[^;&|]*(--force|-f([[:space:]]|$))[^;&|]*main' \
  && block "never force-push main."

# Hook bypass and missing privacy setup.
printf '%s' "$cmd" | grep -Eq -- '--no-verify|core\.hooksPath[[:space:]]*=|-c[[:space:]]+core\.hooksPath' \
  && block "do not bypass the git hooks; they keep personal data out of this public repo."
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+(commit|push)'; then
  [ "$(git config core.hooksPath || true)" = ".githooks" ] && [ -n "$(git config filter.beads-scrub.clean || true)" ] \
    || block "privacy hooks are not configured in this clone. Run scripts/setup-dev.sh first."
fi

exit 0
