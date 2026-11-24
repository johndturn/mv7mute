#!/usr/bin/env bash
# Fail if changes about to leave this machine contain personal data.
# This fork is PUBLIC. See AGENTS.md, "Public repo hygiene".
#
# Usage:
#   scripts/privacy-scan.sh --staged     # what `git commit` would record (pre-commit hook)
#   scripts/privacy-scan.sh --outgoing   # commits not on any remote yet (pre-push hook)
#   scripts/privacy-scan.sh --tree       # every tracked file as committed content (audit)
#
# Only ADDED lines are checked for --staged and --outgoing, so upstream history never trips it.
set -euo pipefail
export LC_ALL=C  # byte-wise matching; binary-ish content must not break sed/grep

mode="${1:---staged}"
cd "$(git rev-parse --show-toplevel)"

# Patterns that indicate personal data. Extended regex, case-insensitive.
patterns=(
  '/Users/[A-Za-z0-9._-]+'                       # macOS home paths
  '/home/[A-Za-z0-9._-]+'                        # Linux home paths
  'C:\\\\Users\\\\'                              # Windows home paths
  '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' # email addresses (allowlist below)
  'serial[N]um='                                 # MV7 serial number replies/events
  'configure\.zsa\.io/[A-Za-z0-9/_-]+'           # personal Oryx layout links
  '"source_repo[_]path"'                         # beads absolute workspace path (filter not active)
)
# Allowed matches (removed before checking): generic, non-personal addresses.
allow='(noreply@anthropic\.com|[A-Za-z0-9._%+-]*@users\.noreply\.github\.com|@example\.(com|org)|git@github\.com)'

case "$mode" in
  --staged)   content="$(git diff --cached -U0 --no-color --diff-filter=ACMR | grep -E '^\+[^+]' | sed 's/^+//' || true)" ;;
  --outgoing) content="$(git log -p -U0 --no-color --format= HEAD --not --remotes | grep -E '^\+[^+]' | sed 's/^+//' || true)" ;;
  --tree)     content="$(git grep --cached -I -h -e '' -- . || true)" ;;  # text files, as staged
  *) echo "usage: $0 [--staged|--outgoing|--tree]" >&2; exit 64 ;;
esac

[ -z "$content" ] && exit 0
filtered="$(printf '%s\n' "$content" | sed -E "s/${allow}//Ig")"

found=0
for p in "${patterns[@]}"; do
  hits="$(printf '%s\n' "$filtered" | grep -Ein -e "$p" || true)"
  if [ -n "$hits" ]; then
    found=1
    echo "privacy-scan: pattern /$p/ matched:" >&2
    printf '%s\n' "$hits" | head -5 | cut -c1-160 | sed 's/^/  /' >&2
  fi
done

if [ "$found" -ne 0 ]; then
  cat >&2 <<'EOF'

privacy-scan: blocked. This repository is public. Remove the personal data above
(use ~ for home paths, generic wording for people, no serials or emails), then retry.
If .beads/issues.jsonl tripped the beads path pattern, run scripts/setup-dev.sh to enable
the beads-scrub filter and re-stage the file (git add .beads/issues.jsonl).
EOF
  exit 1
fi
