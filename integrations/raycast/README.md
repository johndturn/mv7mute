# Raycast: toggle MV7 mute

`mv7-toggle-mute.sh` is a [Raycast script command](https://github.com/raycast/script-commands) that runs
`mv7mute toggle` and shows **Muted** or **Unmuted** as a HUD. It toggles the mic's own mute (the touch-pad state,
LED included), so it works in every app. On a ZSA Moonlander, one key sends Hyper+M (Cmd+Ctrl+Opt+Shift+M), and
Raycast runs this script on that hotkey.

## Prerequisites

- The CLI is installed at `~/.local/bin/mv7mute` (see AGENTS.md, "Local install"). Raycast runs scripts with a
  minimal `PATH`, so the script calls that absolute path, not `mv7mute`.

## Set up in Raycast

1. **Add the script directory.** Raycast Settings → Extensions → Script Commands → **Add Directories**. Choose this
   `integrations/raycast` folder in your clone. Raycast loads every script in the folder, and `test.sh` has no
   Raycast metadata, so it is ignored.
2. **Find the command.** Search Raycast for **Toggle MV7 Mute** (package **MV7**) and run it once from the Raycast
   window to check it works.
3. **Assign the hotkey.** In Settings → Extensions, select **Toggle MV7 Mute**, click **Record Hotkey**, and press
   Hyper+M (on the Moonlander, the key that sends all four modifiers + M). Raycast shows it as `⌃⌥⇧⌘M`, or `✦M`
   if Raycast's own Hyper Key is enabled.
4. **Check for conflicts.** If the hotkey doesn't fire:
   - Another Raycast command or extension may already use Hyper+M (Raycast warns when you record it).
   - A macOS shortcut may be bound to it: System Settings → Keyboard → Keyboard Shortcuts.
   - Another app may grab it globally.

## Behaviour

- **Success:** a HUD shows `Muted` or `Unmuted` after the Raycast window closes. A toggle takes about 30–40 ms.
- **Failure:** the script exits 1. Raycast then shows a "script failed" toast; in silent mode it may not show the
  message itself. To see the message (for example `Error: MV7 not found`), run the command from the Raycast
  window, or run `~/.local/bin/mv7mute toggle` in a terminal.
- **MOTIV Mix** can be open or closed: the CLI opens the mic in shared mode on macOS.

## Test

`integrations/raycast/test.sh` runs the script against stub binaries, using the `MV7MUTE_BIN` override. It never
touches the mic. Lint with `shellcheck integrations/raycast/*.sh`.
