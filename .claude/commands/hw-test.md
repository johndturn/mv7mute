---
description: Guided hardware test on the real MV7, with the maintainer watching the mic
argument-hint: "[issue-id]"
---

Run a hardware check of the current build on the real Shure MV7. Read AGENTS.md "Hardware safety" first.

Rules: only the CLI's own subcommands (`status`, `toggle`, `on`, `off`); no other HID commands; at most ~10 toggles
in a row; one command at a time, then wait for the maintainer to report what the mic did.

1. `cargo build --release --locked -p mv7mute`. Confirm the build includes the fixes the test is for
   (`git log --oneline -5`).
2. Ask the maintainer to: plug in the mic, note the current MOTIV Mix settings (mode, EQ, limiter/compressor,
   gain), and say whether MOTIV Mix is open. Wait for the answer.
3. Walk the checklist from the issue (`br show $ARGUMENTS`, default the hardware validation issue), e.g.:
   - `./target/release/mv7mute status` matches the LED.
   - `toggle`, `on`, `off` flip the LED; time one toggle with `/usr/bin/time -p`.
   - Maintainer taps the pad, then `status` reports the new state.
   - After the toggles, MOTIV settings unchanged; no audible dropout.
   - Repeat with MOTIV Mix open and closed.
4. Record results as a note: `br update <id> --notes "..."`. Keep it generic (no serials, paths or names).
5. If anything fails, stop and report. Don't change code during the test.
