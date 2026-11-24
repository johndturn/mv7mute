---
description: Audit the repo for personal data before pushing (public fork)
---

This fork is public. Check that nothing personal is committed or about to be.

1. `scripts/privacy-scan.sh --staged`, `scripts/privacy-scan.sh --outgoing` and `scripts/privacy-scan.sh --tree`.
2. `git config core.hooksPath` is `.githooks` and `git config filter.beads-scrub.clean` is set; if not, say to run
   `scripts/setup-dev.sh`.
3. `git show :.beads/issues.jsonl | grep -c source_repo_path` is 0 (the staged copy is filtered).
4. Read the outgoing commit messages (`git log --format='%an <%ae>%n%B' HEAD --not --remotes`): author emails must
   be GitHub noreply addresses; messages must not name people, employers or local paths.
5. Skim new docs and beads issues for anything the scanner can't catch: names, workplace details, device serials,
   personal layout links, account names.

Report findings with file:line. Fix only what I approve.
