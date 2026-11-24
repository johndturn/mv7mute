#!/usr/bin/env bash
# SessionStart hook: short orientation printed into the agent's context.
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
echo "Branch: $(git branch --show-current 2>/dev/null)  |  $(git status --porcelain 2>/dev/null | wc -l | tr -d ' ') uncommitted change(s)"
if [ "$(git config core.hooksPath 2>/dev/null)" != ".githooks" ] || [ -z "$(git config filter.beads-scrub.clean 2>/dev/null)" ]; then
  echo "WARNING: privacy hooks/filter not configured in this clone. Run scripts/setup-dev.sh before committing."
fi
if command -v br >/dev/null; then
  echo "Ready work (br ready):"
  br ready 2>/dev/null | sed -n '3,8p'
fi
exit 0
