---
description: Pick the next beads issue, claim it, and branch for it
argument-hint: "[issue-id]"
---

Start the next piece of work, following docs/SDLC.md.

1. If `$ARGUMENTS` names an issue, use it. Otherwise run `bv --robot-next` and `br ready`, and pick the top
   unblocked issue (say which and why in one line). Never run bare `bv`.
2. `br show <id>`. If it is labelled `human` or `hardware`, say what the maintainer needs to do or be present for,
   and stop until they confirm.
3. Make sure the tree is clean, then `git switch main && git pull --ff-only origin main`.
4. `br update <id> --status=in_progress`, then `git switch -c <type>/<id>-<short-slug>` (type from the issue:
   fix, feat, chore, docs).
5. Summarise the acceptance criteria and your plan in a few lines. For code changes, hand the implementation to
   the `rust-implementer` subagent or do it test-first yourself.
