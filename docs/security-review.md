# Security and code review: baseline

Reviewed commit: upstream `5fb02cb` (`docs: align README with current release flow and tray platform support`,
2026-05-02), the state the fork was created from on 2026-11-24. Scope: the `mv7mute` CLI and `mv7mute-core`, their
dependency tree, and the build scripts that run during `cargo build`. The tray app (`mv7mute-tray`) was skimmed only;
it is not built or used here.

This document records what was true at that commit. Open work lives in beads (`br list`), not here.

## Summary

Safe to build. No malicious or surprising behaviour. Two functional problems must be fixed before the CLI is used
on the microphone (both tracked as P1 beads issues).

## What the CLI does

`mv7mute [toggle|on|off|status|lock|unlock|version]` opens HID interface 3 of the Shure MV7 (`14ed:1012`), sends
fixed ASCII commands, reads `name=value` replies, prints one or two words, and exits. Per invocation:

1. `su adm`, wait for `su=adm` (3 s)
2. `bootDSP C`, wait for `dspBooted` (5 s)  ← finding 1
3. `lock`; if `lock=on`, send `lock off`
4. the requested command (`micMute`, `micMute on|off`, `lock on|off`)
5. `lock on` again if it was locked (also in `Drop`)

## Capabilities

- No network, filesystem, process spawning or environment access in the CLI path. No `unsafe`.
- No user input reaches the device: every command string is a constant.
- The tray app reads one Windows registry key (`HKCU\...\Run`) on Windows only.

## Dependencies (CLI path)

24 crates (macOS host target), all from crates.io with checksums in `Cargo.lock`. Build-time code:

- `hidapi 2.6.5` `build.rs`: on macOS compiles the vendored `etc/hidapi/mac/hid.c` with `cc` and links IOKit,
  CoreFoundation and AppKit. No downloads.
- `clap_derive` (proc macro) with `syn`, `quote`, `proc-macro2`: standard.
- `cc`, `pkg-config`, `shlex`, `find-msvc-tools`: build helpers used by hidapi.

## Findings

1. **`bootDSP C` on every run (fix before use).** The protocol write-up
   ([schlarpc/shure-mv7-firmware-re](https://github.com/schlarpc/shure-mv7-firmware-re), `hid-protocol.md`, command
   8) describes it as "Start the DSP again with the default data". Doing that on each key press risks an audible
   dropout and may reset DSP settings made in MOTIV Mix. It was copied from mv7config, which sends it once when its
   GUI starts. `micMute` needs only privilege level `nor`.
2. **Exclusive HID open on macOS (fix before use).** hidapi's macOS backend opens devices with
   `kIOHIDOptionsTypeSeizeDevice` unless the Rust crate's `macos-shared-device` feature is enabled
   (`hidapi-2.6.5/src/lib.rs`). mv7mute uses default features, so it seizes the console while it runs: it fails or
   cuts MOTIV Mix off. Upstream's "coexists with MOTIV" note is about Windows.
3. **Stale event read (low).** `get_mute` accepts the first report containing `micMute=on|off`; an unsolicited pad
   event could be read instead of the reply.
4. **Lock left off if interrupted (low).** Killing the process between unlock and re-lock leaves the settings lock
   off.
5. **`su adm` is not an escalation.** `adm` is the power-on level; the command is effectively a no-op guard.

## Device facts relied on

From `hid-protocol.md` (tested on package 1.2.17): interface 3 is a vendor HID console (64-byte reports, no report
ID, NUL-terminated ASCII); privilege levels `nor` < `dev` < `adm` (power-on) < `sup`, settable without a password;
`micMute` is the device mute that the touch pad changes (the device emits `micMute=%s` when the pad is touched).
