# Shayar — AI Agent Guide

## Architecture

- **Shell engine**: Caelestia Shell (`caelestia-shell`) provides status bar, Bento dashboard (calendar, weather, system metrics), notification sidebar, quick utilities drawer, audio OSD pill, and session drawer.
- **Single visual source**: `config/shayar/themes/design-tokens.json` (7 sections, 218 tokens)
- **Single settings file**: `config/shayar/settings/shayar.conf` (24 lines, `KEY="value"`)
- **Generated token files**: CSS, Lua, Rasi, Env, Hyprlock, Kitty, `quickshell-tokens.json`, `shayar.json`, `fastfetch.jsonc` — run `shayar-design-tokens generate` after any change to `design-tokens.json`
- **Color pipeline**: `shayar.json` → matugen → per-component `colors.*` files + `~/.local/state/caelestia/scheme.json` → all desktop components
- **Startup order**: `autostart.lua` initializes environment, awww-daemon, scale propagation, listeners, polkit, `shayar-autostart` (wallpaper sync), hypridle, and launches `caelestia shell -d`.
- **Theme switching**: `themes/<name>/theme.sh` writes runtime values; `shayar-apply-theme` reads `themed.lst` manifest

## Conventions

1. **All visual values** come from `design-tokens.json`. Never hardcode colors, spacing, opacity, or animation values in config files.
2. **Settings** live in `shayar.conf`. Scripts source it with `${VAR:-default}` fallbacks.
3. **Hyprland config** is modular Lua loaded by `hyprland.lua` in this order:
   functions → monitors → input → gestures → autostart → colors → tokens → environment → window → decoration → layout → workspace → misc → keybinding → windowrule → animation → shayar → custom
4. **New scripts**: add to `config/shayar/bin/`, run `scripts/link.sh`.
5. **Hyprland scripts** (under `config/hypr/scripts/`) are for WM-integrated tools (keybinds, gtk).
6. **Caelestia shell config**: lives in `config/caelestia/shell.json` and symlinks to `~/.config/caelestia/shell.json`.
7. **Matugen templates** live in `config/matugen/templates/`. Each maps to a `[templates.*]` section in `config.toml`.
8. **Caelestia IPC & Drawers** (`session`, `utilities`, `dashboard`, `osd`, `launcher`, `sidebar`) are triggered via `qs -c caelestia ipc call drawers toggle <name>` or Hyprland global shortcuts (`caelestia:<name>`).

## Extensions

Available extensions in `config/shayar/extensions/available/`:

| Extension | Hook | Description |
|---|---|---|
| `hypridle-inhibitor` | `post-reload` | Toggles hypridle via flag file. Run with `status` arg for JSON status output. |
| `menu-items` | — | Custom menu items for the app launcher. |

## Key paths

| Path | Purpose |
|---|---|
| `config/hypr/` | Hyprland WM (Lua config entry: `hyprland.lua`) |
| `config/hypr/conf/` | Modular sub-configs with `load_variant()` system |
| `config/hypr/conf/keybindings/default.lua` | All keybindings |
| `config/hypr/conf/shayar.lua` | Window rules, env vars |
| `config/hypr/conf/autostart.lua` | Startup sequence |
| `config/caelestia/` | Caelestia shell configuration (`shell.json`) |
| `config/kitty/` | Terminal emulator |
| `config/shayar/` | Core engine: settings, themes, scripts, bin, listeners |
| `config/shayar/settings/shayar.conf` | All user-facing settings |
| `config/shayar/scripts/` | Core scripts (shayar-wallpaper, shayar-design-tokens, design_tokens.py, etc.) |
| `config/shayar/bin/` | 20 CLI tools/symlinks available system-wide (including `caelestia` shim) |
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
| Modify Caelestia config | `config/caelestia/shell.json` | Caelestia hot-reloads |
| Add a menu entry | `config/shayar/extensions/available/menu-items/` | Hot-reloads in `shayar-menu` |
| Change theme | `themes/<name>/theme.sh` | Run the theme.sh |
| New script | `shayar/bin/` | Run `scripts/link.sh` |
| Regenerate colors from wallpaper | — | Run `shayar-wallpaper <path>` or `matugen image <path>` |
| Sync SDDM login screen | — | Run `shayar-sddm-sync` (after wallpaper change) |

## Design tokens structure (`design-tokens.json`)

- **colors** (50): MD3 palette — surface, primary, secondary, tertiary, error + variants
- **typography** (18): font families, sizes, icon/cursor themes
- **spacing** (60): rounding, gaps, borders, shadows, blur, per-component dimensions
- **opacity** (6): active/inactive/fullscreen, swaync alpha values
- **animation** (24): bezier curves, speed values, transitions
- **kitty** (9): font, size, window dims, padding, scrollback, cursor blink, background opacity
- **quickshell** (51): QS-specific tokens — panel sizes, spacing, per-app radii, alphas, typography

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
4. Caelestia Shell (`pgrep -x qs >/dev/null || caelestia shell -d`)
5. Set cursor theme
6. Dynamic HiDPI scaling detection & env propagation (`shayar-scale-sync`)
7. Start listeners (`listeners.sh --startall`)
8. polkit agent
9. shayar-autostart (wallpaper sync & cache check)
10. GTK settings (`gtk.sh`)
11. hypridle (backlight idle monitor)
12. cliphist watcher (`wl-paste --watch cliphist store`)

### Wallpaper pipeline (`shayar-wallpaper`)
validate → cache → wait for awww → `awww img` → matugen → sync `scheme.json` & terminal/WM colors → generate blurred wallpaper

### Toggle scripts & Helpers

- `shayar-toggle-statusbar` — Caelestia bar toggle
- `shayar-toggle-scratchpad-window` — special:magic workspace
- `shayar-vol-toggle` — Volume panel (Caelestia utilities drawer)
- `shayar-vol-scroll` — Smooth volume scroll helper with safety clamping
- `shayar-brightness-get` — Direct sysfs backlight reader for brightness controls
- `shayar-bt-toggle` — Bluetooth panel (Caelestia utilities drawer)
- `shayar-net-toggle` — Network panel (Caelestia utilities drawer)
- `shayar-calendar-toggle` — Calendar panel (Caelestia dashboard drawer)
- `shayar-power-toggle` — Power menu (Caelestia session drawer)

## Performance notes

- Battery monitoring handled natively by Caelestia Shell via UPower event-driven architecture; fallback listener polls at **60s**
- Updates check at **30min interval**
- Startup: 12 steps in `autostart.lua` parallelized into async waves, instant bypass in `shayar-autostart` on cache hit (21 ms)
- ~26 shell scripts + 1 Python compiler script total, all lean (<150 lines each except `shayar-wallpaper` at 230)

- `caelestia-shell` — desktop shell engine (bar, dashboard, drawers, OSD, lock)
- `awww-daemon` — wallpaper setter
- `matugen` — Material You color generator
- `gum` — pretty CLI output (optional, used in update scripts)
- `grim` + `slurp` + `wl-copy` — screenshots & clipboard
- `fzf` + `jq` + `fuzzel` — launchers and data processing
- `quickshell` — Qt6 shell runtime
- `sddm` — Display manager (optional, for login screen theming)

## Credits & Acknowledgments

- **ML4W Dotfiles** by Stephan Raabe — The modular Hyprland configuration structure, window rules, and environment foundation.
- **Caelestia Shell** by Caelestia Dots — The desktop shell engine delivering the dynamic status bar, Bento dashboard, notification sidebar, quick utilities drawer, audio/brightness OSD, and session management.
- **Matugen** by InioX — Material You (Material 3) palette generation from wallpapers.
- **Quickshell** by Outfoxxed — The high-performance reactive QML desktop shell engine.
- **Hyprland** by Vaxry — The fluid, dynamic Wayland compositor.
