---
description: Review upstream (Justkant/mv7mute) changes and merge them into the fork on a branch
---

Bring upstream changes into the fork safely (docs/SDLC.md, "Upstream syncs").

1. `git fetch upstream`. Show `git log --oneline main..upstream/main`. If empty, say so and stop.
2. Review before merging: run the `rust-reviewer` subagent on `main...upstream/main` and the `dependency-auditor`
   subagent on the same range (in parallel). Summarise their findings for me and stop if anything is serious.
3. With my OK: `git switch main && git pull --ff-only origin main && git switch -c chore/sync-upstream-<yyyy-mm-dd>`,
   then `git merge --no-ff upstream/main`. Never rebase main.
   - Conflicts on `.github/workflows/release*.yml` (deleted here): keep the deletion.
   - `.github/workflows/ci.yml`: keep the fork's version (lint only, Linux, PR path filter; no test matrix, to
     avoid Actions minutes). Mention what upstream changed in it.
   - Conflicts in `mv7mute-core/src/mv7.rs` or `Cargo.toml`: keep our fixes (no `bootDSP C`; hidapi
     `macos-shared-device` on macOS) and explain each resolution.
4. Run /verify. Open a PR into the fork's main (`gh pr create --repo johndturn/mv7mute --base main`) with the
   review summary. A hardware re-check is needed if `mv7.rs` or hidapi changed.
