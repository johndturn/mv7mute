# AGENTS.md

Single source of truth for AI coding agents (Claude Code, Codex, opencode, ...) working in this repository.
`CLAUDE.md` only imports this file: edit here, not there.

## What this repo is

A **personal, public fork** of [Justkant/mv7mute](https://github.com/Justkant/mv7mute), a small Rust CLI that
toggles the hardware mute of a **Shure MV7** USB microphone (the original model, USB `14ed:1012`, not the MV7+)
over its vendor HID interface. The fork lives at `johndturn/mv7mute`; its maintainer is `johndturn`.

**Why the fork exists:** to get one key on a ZSA Moonlander keyboard that mutes and unmutes the mic's *own* mute (the
same state the touch pad changes, LED included), on macOS, from code the maintainer has reviewed and builds from
source. The chain:

```
Moonlander key (Oryx) ─► Hyper+M (Cmd+Ctrl+Opt+Shift+M) ─► Raycast script command ─► mv7mute toggle ─► MV7 HID: micMute on|off
```

Scope: the `mv7mute` CLI and `mv7mute-core` on macOS. The tray app (`mv7mute-tray`) is upstream's and is not built
or used here; keep it compiling but don't extend it. No releases, no crates.io publishing.

The work plan lives in beads: epic `mv7-keyboard-mute-ipz` (`br show mv7-keyboard-mute-ipz`).

## Public repo hygiene (read this first)

This repository is **public**. Nothing personal goes into files, beads issues, commit messages or PR text:

- No home directory paths (write `~`), email addresses, real names (say "the maintainer"), employer or client
  names, device serial numbers or firmware dumps, personal Oryx layout links, account names, or screenshots of the
  desktop.
- Keep hardware test notes generic: what was run and what happened, not where or on whose machine.
- Guards (run `scripts/setup-dev.sh` once per clone; the SessionStart hook warns if it's missing):
  - `.githooks/pre-commit` and `pre-push` run `scripts/privacy-scan.sh` on added lines (home paths, emails,
    serial-number replies, Oryx links, beads `source_repo_path`). Never bypass them (`--no-verify` is blocked).
  - `.gitattributes` + the `beads-scrub` filter strip `source_repo_path` (an absolute local path br writes) from
    `.beads/issues.jsonl` when it is staged. br records the public handle `johndturn` as actor
    (`.beads/config.yaml`).
  - `/privacy-check` audits the whole repo before a push.
- `.claude/settings.local.json`, `CLAUDE.local.md` and `.env*` are gitignored; put anything machine-specific there.

## Hardware safety

The MV7's HID console has no authentication: `su sup` grants factory level, and some commands rewrite EEPROM, DSP
memory or start the bootloader. Rules:

- **Allowlist.** Code in this repo may send only: `su adm`, `lock`, `lock on`, `lock off`, `micMute`,
  `micMute on`, `micMute off`. Anything else needs the maintainer's approval recorded on a beads issue. The test
  `every_path_sends_only_allowlisted_commands` (`mv7mute-core/src/tests/command_contract.rs`) enforces this.
- **Never send** `bootLoad`, `bootDSP`, `update`, `setEE`, `setDSP`, `setBlock`, `setSN`, `setSAPSN`, `dspPower`,
  `disableUI`, `su sup`, or `getBlock` with a long argument (a 114+ character argument overflows the firmware's
  stack). `bootDSP` was removed from init in mv7-keyboard-mute-ipz.1 (finding 1 in `docs/security-review.md`).
- **The binary only runs with the maintainer present.** Agents don't run `./target/*/mv7mute`, `cargo run` or the
  installed `mv7mute` (except `mv7mute version`) outside a hardware test (`/hw-test`). Settings put these behind a
  permission prompt. At most ~10 toggles in a row.
- Tests use the mock `Transport` (`mv7mute-core/src/tests/support.rs`), which records every command sent.

## Repository map

```
mv7mute-core/src/mv7.rs       # HID transport + device protocol (open, init, lock, micMute, toggle, Drop re-lock)
mv7mute-core/src/lib.rs       # Command enum, run(), lock-restore wrapper (with_device)
mv7mute-core/src/tests/       # Mock transport tests: command_contract.rs, failure_paths.rs, support.rs
mv7mute/src/main.rs           # clap CLI: toggle (default) | on | off | status | lock | unlock | version
mv7mute-tray/                 # Upstream tray app (unused here)
.github/workflows/ci.yml      # Lint only: fmt + clippy (CLI crates) on Linux, PRs touching Rust/Cargo files; tests/builds are local
docs/security-review.md       # Baseline review of upstream 5fb02cb: findings and dependency baseline
docs/SDLC.md                  # The development loop (referenced below)
scripts/setup-dev.sh          # One-time clone setup: beads filter, git hooks, remotes, gh default repo
scripts/privacy-scan.sh       # Personal-data scanner used by the git hooks and /privacy-check
.githooks/                    # pre-commit, pre-push
integrations/raycast/         # Raycast script command (created by mv7-keyboard-mute-ipz.5)
.beads/                       # beads_rust issues (issues.jsonl tracked; DB gitignored)
.claude/                      # settings.json, hooks/, agents/, commands/
```

## Device protocol (what the code relies on)

Source: [schlarpc/shure-mv7-firmware-re](https://github.com/schlarpc/shure-mv7-firmware-re) `hid-protocol.md`, and
[matteodelabre/mv7config](https://github.com/matteodelabre/mv7config).

- Interface 3: vendor HID (usage page `0xFF00`), 64-byte in/out reports, no report ID. hidapi writes 65 bytes (a
  leading `0x00` report-ID slot). Commands are ASCII ending in NUL; replies are NUL-terminated `name=value` lines.
  No end-of-reply marker: read until quiet.
- `micMute` (level `nor`): query or set the mic mute; the device also emits `micMute=on|off` when the pad is
  touched. `lock` (level `adm`): settings lock (hold Mute + Monitor for 2 s on the mic).
- Power-on privilege level is `adm`.
- macOS: hidapi seizes the device unless the crate feature `macos-shared-device` is on (finding 2).

## Commands

| Command | What it does |
| --- | --- |
| `scripts/setup-dev.sh` | One-time per clone: filter, hooks, remotes, `gh` default repo |
| `cargo fmt -p mv7mute-core -p mv7mute` | Format the crates we own (upstream's tray is not rustfmt-clean; leave it) (a PostToolUse hook also runs rustfmt on every edited `.rs` file) |
| `cargo clippy --workspace --all-targets --locked -- -D warnings` | Lint, warnings are errors (CI runs the same on the CLI crates only) |
| `cargo test --workspace --locked` | Unit tests (mock transport; never touches hardware) |
| `cargo build --release --locked -p mv7mute` | Build only the CLI |
| `cargo tree -p mv7mute --locked -e normal,build` | CLI dependency tree |
| `scripts/privacy-scan.sh --staged\|--outgoing\|--tree` | Personal-data scan |

Always pass `--locked`. On a fresh macOS clone the workspace builds without extra system packages. GitHub Actions
runs lint only (fmt + clippy on Linux, PRs that touch Rust/Cargo files; needs `libudev-dev`); all tests and builds
are local, to keep Actions minutes near zero.

**Definition of done** for any code change: fmt check, clippy, tests and the locked release build pass, the privacy
scan is clean, and `git status` shows only intended changes. Behaviour changes to what is sent to the device also
need a hardware check (`/hw-test`).

## Development workflow

Follow **[docs/SDLC.md](docs/SDLC.md)**: issue → claim → branch from `main` → test first → definition of done →
review subagents → hardware check if needed → commit with `.beads/` → PR into the fork
(`gh pr create --repo johndturn/mv7mute --base main`) → close issue on the branch → maintainer merges → delete the
branch. Never commit to `main`; never push to `upstream`; merge (don't rebase) upstream syncs.

Git remotes: `origin` = `johndturn/mv7mute` (push here), `upstream` = `Justkant/mv7mute` (fetch only; push URL
disabled). `gh` defaults to the fork via `gh repo set-default`.

Commits: Conventional Commits with the issue ID, e.g. `fix(core): drop bootDSP from init (mv7-keyboard-mute-ipz.1)`.
Author email must be a GitHub noreply address.

## Claude Code setup (`.claude/`)

- `settings.json`: allows build/test/lint, `br`, `bv --robot-*`, read-only git/gh; **asks** before running the
  binary, `cargo run`/`install`, pushes, merges, PR creation and `gh workflow`/`gh repo`; **denies**
  `cargo publish`, pushes to `upstream`, force pushes.
- Hooks: `guard-bash.sh` (PreToolUse: blocks bare `bv`, publishing, upstream writes, tag pushes, hook bypass, commits
  without the privacy setup, `gh pr create` aimed at the parent repo), `rustfmt-on-edit.sh` (PostToolUse),
  `session-start.sh` (branch, privacy-setup warning, `br ready`).
- Subagents:

| Agent | Use it when | Writes? |
| --- | --- | --- |
| `rust-implementer` | Implementing one beads issue test-first in core/CLI | Yes |
| `rust-reviewer` | Before merging a branch; on every upstream sync (code, security, hardware allowlist, privacy) | No |
| `verifier` | After a change: runs the definition of done | No |
| `dependency-auditor` | Any Cargo.lock / Cargo.toml / feature change; upstream syncs | Only if asked |

- Commands: `/next` (pick, claim, branch), `/verify`, `/hw-test`, `/sync-upstream`, `/privacy-check`.

## MCP servers

`.mcp.json` registers **context7** (current docs for crates such as hidapi and clap, and for Raycast script
commands). Use it before relying on memory for library behaviour. GitHub work goes through the `gh` CLI, so no
GitHub MCP is configured.

## Local install

Not installed yet (mv7-keyboard-mute-ipz.4). When it is, record here: install path (written with `~`), the fork
commit it was built from, and the build command.

## Issue tracking with br (beads_rust) and bv (beads_viewer)

**Beads (`.beads/`) is the source of truth for all work**: context, priority, dependencies, acceptance criteria,
decisions and follow-ups. No TODO lists in Markdown or code comments. If a doc and an issue disagree, the issue
wins. Issue prefix: `mv7`.

`br` never runs git. After any `br` change: `br sync --flush-only && git add .beads/` and commit it on the same
branch as the code.

```bash
br ready                                   # open, unblocked work
br list --status=open                      # everything open
br show <id>                               # details, acceptance criteria, deps
br search "keyword"
br create --title "..." --type task --priority 2 --labels hid \
  --description "..." --acceptance-criteria "..." --parent mv7-keyboard-mute-ipz
br update <id> --status=in_progress        # claim
br update <id> --notes "..."               # append findings (generic, no personal data)
br update <id> --design "..."              # design decisions
br dep add <issue> <depends-on>            # <issue> is blocked by <depends-on>
br close <id> --reason "..."
br sync --flush-only                       # export DB -> .beads/issues.jsonl
```

- Priority: 0 critical, 1 high, 2 medium, 3 low, 4 backlog. Types: task, bug, feature, epic, chore, docs.
- Labels in use: `hid`, `macos`, `review-finding`, `hardware`, `human` (needs the maintainer), `install`,
  `raycast`, `moonlander`, `ci`, `fork`, `tooling`, `security`, `upstream`, `idea`.

`bv` with no flags opens an interactive TUI: **agents must never run bare `bv`** (the guard hook blocks it). Use
robot mode:

```bash
bv --robot-next        # single best next pick
bv --robot-triage      # ranked recommendations
bv --robot-plan        # dependency-ordered execution plan
bv --robot-insights    # bottlenecks, critical path
bv --robot-help        # all robot commands
```

The SQLite DB (`.beads/*.db*`) is gitignored; `.beads/issues.jsonl` is tracked. Never leave `br` changes
uncommitted at the end of a session.
