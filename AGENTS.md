# Shayar — AI Agent Guide

## Architecture

- **Single theme**: solid backgrounds (waybar/swaync/rofi/QS applets)
- **Single visual source**: `config/shayar/themes/design-tokens.json` (~304 tokens across 9 sections)
- **Single settings file**: `config/shayar/settings/shayar.conf` (23 lines, `KEY="value"`)
- **9 generated token files**: CSS, Lua, Rasi, Env, Hyprlock, Kitty, GTK, `shayar.json`, `fastfetch.jsonc` — run `shayar-design-tokens generate` after any change to `design-tokens.json`
- **Color pipeline**: `shayar.json` → matugen → per-component `colors.*` files → all CSS/Lua/Rasi configs
- **Startup order**: `autostart.lua` fires `shayar-autostart` and `gtk.sh` concurrently via `hl.exec_cmd()` (non-blocking). `shayar-autostart` backgrounds `shayar-wallpaper` which runs matugen synchronously, then launches and reloads Waybar. This prevents stale colors on boot.
- **Theme switching**: `themes/<name>/theme.sh` writes runtime values; `shayar-apply-theme` reads `themed.lst` manifest

## Conventions

1. **All visual values** come from `design-tokens.json`. Never hardcode colors, spacing, opacity, or animation values in config files.
2. **Settings** live in `shayar.conf`. Scripts source it with `${VAR:-default}` fallbacks.
3. **Hyprland config** is modular Lua loaded by `hyprland.lua` in this order:
   functions → monitors → input → gestures → autostart → colors → tokens → environment → window → decoration → layout → workspace → misc → keybinding → windowrule → animation → shayar → custom
4. **New scripts**: add to `config/shayar/bin/`, run `scripts/link.sh`.
5. **Hyprland scripts** (under `config/hypr/scripts/`) are for WM-integrated tools (keybinds, power, volume).
6. **Waybar modules** are defined inline in the theme `config` and toggled by `launch.sh`.
7. **Matugen templates** live in `config/matugen/templates/`. Each maps to a `[templates.*]` section in `config.toml`.
8. **QML IPC targets** (`power`, `bt`, `net`, `calendar`, `vol`, `welcome`) are the contract between shell toggle scripts and Quickshell applets. If a target is renamed in QML `IpcHandler.target`, all corresponding `shayar-*-toggle` scripts must be updated.

## Extensions

Available extensions in `config/shayar/extensions/available/`:

| Extension | Hook | Description |
|---|---|---|
| `hypridle-inhibitor` | `post-reload` | Toggles hypridle via flag file. Run with `status` arg for waybar JSON output. |
| `menu-items` | — | Custom menu items for the app launcher. |

## Key paths

| Path | Purpose |
|---|---|
| `config/hypr/` | Hyprland WM (Lua config entry: `hyprland.lua`) |
| `config/hypr/conf/` | Modular sub-configs with `load_variant()` system |
| `config/hypr/conf/keybindings/default.lua` | All keybindings |
| `config/hypr/conf/shayar.lua` | Window rules, env vars |
| `config/hypr/conf/autostart.lua` | Startup sequence |
| `config/waybar/` | Status bar (`launch.sh`, `themes/`) |
| `config/swaync/` | Notification center |
| `config/quickshell/` | Quickshell applets: power menu, calendar, WiFi, Bluetooth, Volume, Welcome (`PowerApp/`, `CalendarApp/`, `NetApp/`, `BtApp/`, `VolApp/`, `WelcomeApp/`, `icons/`) |
| `config/rofi/` | App launcher (5 rasi config files) |
| `config/kitty/` | Terminal emulator |
| `config/shayar/` | Core engine: settings, themes, scripts, bin, listeners |
| `config/shayar/settings/shayar.conf` | All user-facing settings |
| `config/shayar/scripts/` | 13 shayar scripts (shayar-wallpaper, shayar-design-tokens, etc.) |
| `config/shayar/bin/` | 18 CLI tools available system-wide |
| `config/shayar/themes/design-tokens.json` | **Single source of truth** for all visual values |
| `config/shayar/themes/glass/theme.sh` | Theme activator |
| `config/matugen/` | Color generation pipeline (config.toml + templates) |
| `config/gtk-3.0/`, `config/gtk-4.0/` | GTK theme overrides |
| `config/bashrc/`, `config/zshrc/` | Modular shell configs |

## Common tasks

| Task | File(s) to edit | Post-step |
|---|---|---|
| Change a color/spacing/font | `themes/design-tokens.json` | Run `shayar-design-tokens generate` |
| Add a user setting | `settings/shayar.conf` + add to each script that reads it | Source with `${VAR:-default}` |
| Add a keybind | `hypr/conf/keybindings/default.lua` | `hyprctl reload` |
| Add a window rule | `hypr/conf/shayar.lua` | `hyprctl reload` |
| Add a waybar module | `waybar/themes/shayar/config` | Restart waybar |
| Add a rofi mode | `rofi/config-<name>.rasi` + wire into keybind | New keybind |
| Change theme | `themes/<name>/theme.sh` | Run the theme.sh |
| New script | `shayar/bin/` | Run `scripts/link.sh` |
| Modify power menu | `quickshell/PowerApp/PowerWindow.qml` + `quickshell/icons/*.svg` | Restart QS: `pkill qs; qs -p ~/.config/quickshell/shell.qml` |
| Modify calendar | `quickshell/CalendarApp/CalendarWindow.qml` | Restart QS: `pkill qs; qs -p ~/.config/quickshell/shell.qml` |
| Modify network | `quickshell/NetApp/NetWindow.qml` | Restart QS: `pkill qs; qs -p ~/.config/quickshell/shell.qml` |
| Modify bluetooth | `quickshell/BtApp/BtWindow.qml` | Restart QS: `pkill qs; qs -p ~/.config/quickshell/shell.qml` |
| Modify volume | `quickshell/VolApp/VolWindow.qml` | Restart QS: `pkill qs; qs -p ~/.config/quickshell/shell.qml` |
| Modify welcome | `quickshell/WelcomeApp/WelcomeWindow.qml` | Restart QS: `pkill qs; qs -p ~/.config/quickshell/shell.qml` |
| Regenerate QS colors | — | Run `shayar-design-tokens generate --with-colors` or change wallpaper |
| Regenerate colors from wallpaper | — | Run `shayar-wallpaper <path>` or `matugen image <path>` |
| Sync SDDM login screen | — | Run `shayar-sddm-sync` (after wallpaper change) |

## Design tokens structure (`design-tokens.json`)

- **colors** (50): MD3 palette — surface, primary, secondary, tertiary, error + variants
- **typography** (22): font families, sizes, icon/cursor/GTK theme names
- **spacing** (105): rounding, gaps, borders, shadows, blur, per-component dimensions
- **opacity** (26): active/inactive, per-component opacities
- **animation** (29): 14 bezier curves, 10 speed values, 6 transitions
- **shadow** (5): waybar + swaync CSS shadow strings
- **quickshell** (60): QS-specific tokens — panel sizes, spacing, per-app radii, alphas
- **kitty** (9): font, size, window dims, padding, scrollback, cursor blink
- **gtk** (6): GTK theme names

Generated output files write token values in the target format's native syntax (CSS `@define-color`, Lua `dt.*`, env `DT_*`, rasi `$dt-*`, etc.).

## Key scripts

### SDDM Sync (`shayar-sddm-sync`)
Syncs current wallpaper and matugen colors to the SDDM login screen. Run after every wallpaper change if SDDM is installed.
- `--install` — Install the SDDM theme (first time)
- `--status` — Show sync status
- Requires SDDM + root access for theme dir operations

### Startup (`autostart.lua`)
1. dbus-update-activation-environment
2. Restart xdg-desktop-portal services
3. awww-daemon (wallpaper daemon)
4. Set cursor theme
5. Start listeners (low-bat-notification)
6. polkit agent
7. shayar-autostart (wallpaper + nm-applet + waybar)
8. GTK settings
9. swaync
10. hypridle
11. cliphist watcher

### Wallpaper pipeline (`shayar-wallpaper`)
validate → cache → wait for awww → `awww img` → matugen → reload waybar/swaync/quickshell → generate blurred wallpaper

### Toggle scripts

- `shayar-toggle-statusbar` — waybar on/off via `waybar-disabled` flag
- `shayar-toggle-nmapplet` — NetworkManager applet
- `shayar-toggle-scratchpad-window` — special:magic workspace
- `shayar-vol-toggle` — Volume panel (Quickshell)
- `shayar-bt-toggle` — Bluetooth panel (Quickshell)
- `shayar-net-toggle` — Network panel (Quickshell)
- `shayar-calendar-toggle` — Calendar panel (Quickshell)
- `shayar-power-toggle` — Power menu (Quickshell)
- `shayar-welcome-toggle` — Welcome screen (Quickshell)
- `shayar-panel-pos` — Calculates icon positions from Waybar CSS for panel placement

## Performance notes

- Battery waybar module polls at **60s interval** (P0 fix: was 1s)
- Updates check at **30min interval**
- Low battery listener polls at **60s**
- Startup: ~13 steps in `autostart.lua`, ~5 actions in `shayar-autostart`
- ~26 shell scripts total, all lean (<150 lines each except shayar-design-tokens at 326 and shayar-wallpaper at 228)

## Dependencies

- `awww-daemon` — wallpaper setter
- `matugen` — Material You color generator
- `gum` — pretty CLI output (optional, used in update scripts)
- `grim` + `slurp` + `wl-copy` — screenshots
- `fzf` + `jq` — launchers and data processing
- `quickshell` — Qt6 shell for power menu and calendar
- `sddm` — Display manager (optional, for login screen theming)

## Evolution plan

See the git log for the full history. Key completed milestones:
- Dual color source reconciliation (design-tokens.json is single source)
- Shell hardening (26/26 scripts with strict mode)
- CI pipeline (130 tests on push/PR)
- Extension hooks system (5 hook points)
- Layered config with user overrides
- Themed overlay system
