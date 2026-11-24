#!/usr/bin/env bash
# One-time setup for a clone of this fork. Safe to re-run. Touches only .git/config.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

# 1. Strip br's absolute workspace path from .beads/issues.jsonl whenever it is staged
#    (paired with the attribute in .gitattributes). required=true makes git fail loudly
#    instead of committing unfiltered content if jq is missing.
command -v jq >/dev/null || { echo "jq is required (brew install jq)" >&2; exit 1; }
git config filter.beads-scrub.clean "jq -c 'del(.source_repo_path)'"
git config filter.beads-scrub.smudge cat
git config filter.beads-scrub.required true

# 2. Versioned git hooks: privacy scan on commit and push.
git config core.hooksPath .githooks

# 3. Remotes: origin = the public fork, upstream = the original project.
git remote get-url upstream >/dev/null 2>&1 || git remote add upstream git@github.com:Justkant/mv7mute.git
git remote set-url --push upstream DISABLED  # never push to someone else's repo by accident

# 4. gh defaults to the PARENT repo for forks; point it at the fork.
if command -v gh >/dev/null; then gh repo set-default johndturn/mv7mute >/dev/null; fi

# Re-stage the beads file through the filter if it is already tracked or staged.
git ls-files --error-unmatch .beads/issues.jsonl >/dev/null 2>&1 && git add .beads/issues.jsonl || true

echo "setup-dev: filter, hooks, remotes and gh default configured."
