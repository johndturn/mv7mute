# Lightweight SDLC

A personal fork with one maintainer and AI agents doing most of the typing. The process exists to keep three things
true: the code that touches the microphone was reviewed, `main` always builds, and nothing personal reaches this
public repo.

## The loop

1. **Issue first.** Every change has a beads issue (`br ready`, `bv --robot-next`, or `br create`). The issue holds
   the context, acceptance criteria and decisions; nothing else is a task list.
2. **Claim and branch.** `br update <id> --status=in_progress`, then from fresh `main`:
   `git switch -c <type>/<issue-id>-<slug>` (types: `fix`, `feat`, `chore`, `docs`). Never commit to `main`.
   The `/next` command does this.
3. **Test first.** For code: a failing test in `mv7mute-core/src/tests/` (mock transport, exact command sequence),
   then the change. Small diffs, upstream's style.
4. **Definition of done** (the `/verify` command or the `verifier` subagent):
   - `cargo fmt -p mv7mute-core -p mv7mute -- --check`
   - `cargo clippy --workspace --all-targets --locked -- -D warnings`
   - `cargo test --workspace --locked`
   - `cargo build --release --locked -p mv7mute`
   - privacy scan clean (the git hooks run it on commit and push)
5. **Review.** Anything touching `mv7mute-core`, `Cargo.toml` or `Cargo.lock` gets the `rust-reviewer` subagent;
   dependency changes also get `dependency-auditor`. Fix or answer every finding.
6. **Hardware check when behaviour changes.** Code that changes what is sent to the device is checked on the real
   mic with the maintainer watching (`/hw-test`), and results go on the issue as a note.
7. **Commit.** Conventional commits referencing the issue: `fix(core): drop bootDSP from init (mv7-keyboard-mute-ipz.1)`.
   Include `.beads/issues.jsonl` changes on the same branch (`br sync --flush-only && git add .beads/`).
8. **PR into the fork.** `git push -u origin HEAD`, then
   `gh pr create --repo johndturn/mv7mute --base main` (for a fork, gh otherwise targets the parent repo).
   Body: summary, verification output, hardware notes, beads IDs. CI (`ci.yml`) runs on the PR.
9. **Close and merge.** `br close <id> --reason "..."` on the branch, flush and commit `.beads/`, push. The
   maintainer merges (`gh pr merge --merge`); then delete the branch locally and on origin, and
   `git switch main && git pull --ff-only`.

Small docs-only or beads-only changes may skip steps 3, 5 and 6, never 4 or the privacy scan.

## Upstream syncs

`upstream` (Justkant/mv7mute) is read-only (push URL disabled). To take its changes: `/sync-upstream`. Review the
incoming range with `rust-reviewer` and `dependency-auditor` *before* merging, merge `upstream/main` into a
`chore/sync-upstream-<date>` branch (merge, never rebase `main`), keep the fork's fixes and the deleted release
workflows on conflict, verify, PR. A hardware re-check is needed if `mv7.rs` or hidapi changed.

## Contributing back

Fixes that help everyone (the two P1 findings) may go upstream as PRs, but only with the maintainer's explicit
approval, from a clean branch that contains only the fix: no `AGENTS.md`, `.claude/`, `.beads/`, `docs/` or
`scripts/` files.

## Installing

The installed binary is built only from a reviewed commit on the fork's `main` with `--locked`. Record the commit
in AGENTS.md ("Local install") whenever it changes.
