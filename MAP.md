# The Shayar Codex

A complete map of every component in the Shayar dotfiles ecosystem. This is the reference document -- if you need to know where something lives or how it connects, start here.

---

## Core System (`config/shayar/`)

This is the central nervous system. Everything else plugs into it.

### `version.json`
Tracks the current release. Version lives here for the settings app and update checker.

### `library.sh`
Shared utilities. Three functions:
- `_writeLog()` — prefixes output with `::`
- `run_extensions()` — fires extension hooks at 5 hook points
- `config_path()` — resolves user override path before shipped default

### `listeners.sh`
The listener process manager. One background listener ships out of the box:

- **`low-bat-notification.sh`** -- Polls `/sys/class/power_supply/BAT*` every 60 seconds. Sends a notification at 20% and a critical one at 15%. Resets when the charger connects.

Commands: `--startall`, `--stopall`, `--restartall`, or target a specific listener by name. Uses `nohup` and checks for duplicates with `pgrep`.

### `shayar.conf`
Consolidated settings file. Replaced all individual value files. 25 lines with `<KEY>="<VALUE>"` format. Scripts source it directly. Encapsulated settings:

| Variable | Default | What it does |
|----------|---------|-------------|
| `TERMINAL` | `kitty` | Default terminal emulator |
| `BROWSER` | `firefox` | Default browser |
| `FILE_MANAGER` | `yazi` | Default file manager |
| `WALLPAPER_FOLDER` | `$HOME/Wallpaper` | Custom wallpaper directory |
| `WALLPAPER_EFFECT` | `off` | Active wallpaper effect |
| `WALLPAPER_AUTOMATION` | -- | Auto-rotation interval in seconds |
| `SCREENSHOT_FOLDER` | `$HOME/Pictures/Screenshots` | Where screenshots save |
| `WAYBAR_THEME` | `/shayar;/shayar/default` | Active Waybar theme |
| `SCREEN_LOCKER` | `hyprlock` | Lock screen command |
| `BLUR_AMOUNT` | `50x30` | Lock screen blur amount |

Executable wrappers in `config/shayar/settings/` (`terminal.sh`, `browser.sh`, `filemanager.sh`, `network-manager.sh`, `launcher.sh`, `emoji-picker.sh`, `calculator.sh`) source `shayar.conf` and fall back to defaults if it's missing.

### `themes/`
Only the glass theme ships with Shayar. Contains three files:

- **`shayar.json`** — Static Material Design 3 palette (source for matugen color generation).
- **`shayar-palette.yaml`** — YAML version named "Komorebi Ink".
- **`design-tokens.json`** — Single source of truth for **all** visual values: colors, typography, spacing, opacity, animation, shadows. Every hardcoded visual value should originate here. See "Design Tokens" below.

### Generated token files (from `design-tokens.json`):

| File | Format | Used By |
|------|--------|---------|
| `design-tokens.css` | `@define-color dt-*` | waybar, swaync |
| `quickshell.json` (matugen) | hex JSON | Quickshell power menu |
| `design-tokens.lua` | `dt.*` Lua table | hyprland `*.lua` configs |
| `design-tokens.rasi` | `dt-*` variables | rofi `*.rasi` configs |
| `design-tokens.env` | `DT_*` env vars | bash scripts via `source` |

Run `shayar-design-tokens generate` after changing `design-tokens.json` to regenerate all seven format outputs.

### Design tokens philosophy
Colors come from `shayar.json` → matugen → per-component `colors.*` files (colors.css, colors.lua, colors.conf, colors.rasi). The design-tokens.json mirrors the color palette for reference and adds every other visual value: spacing, rounding, gaps, font sizes, animation speeds, opacities, shadows, and window dimensions. Component configs reference these generated files instead of hardcoding values.

**Already migrated:**

| Component | Token source | Values replaced |
|-----------|-------------|-----------------|
| Hyprland decorations | `dt.spacing.*`, `dt.opacity.*` | rounding, gaps, blur, shadow, opacity |
| Hyprland windows | `dt.spacing.*` | gaps_in, gaps_out, border_size |
| Hyprland animations | `dt.animation.*` | all bezier curves + speeds |
| Waybar style.css | colors.css + `alpha()` | all hex/rgba colors → `@color-name` + alpha |
| SwayNC CSS | colors.css + `alpha()` | hardcoded black/white/red → `@scrim`/`@error`/`@primary` |
| Wlogout CSS | colors.css | `@foreground` → `@on_surface` |
| volume-slider.sh | `design-tokens.env` | position, size, colors |

**Not yet migrated** (still hardcoded, documented in design-tokens.json): hyprlock.conf sizing, kitty.conf font/size, GTK settings.ini theme names, Pango markup colors in waybar config, SVG asset colors. These require per-format generators (hyprlock.conf, kitty.conf, SVG) that can be added later.

### `colors/`
Matugen output. The primary color `#acc7ff` drives the whole palette. Files: `primary`, `secondary`, `onsurface`, `onprimary`. Other scripts source these for hardcoded color references.

### `assets/`
Branding. `shayar-logo.png`, `shayar-logo.svg`, `shayar.svg`. The logo is a geometric V-shape.

### `wallpapers/`
Default wallpapers. `default.png` is the only fallback wallpaper.

### `bin/`
18 CLI tools available system-wide after symlinking:

- **`shayar-apps`** -- Scans `/usr/share/applications` and `~/.local/share/applications` for `.desktop` files. Handles Flatpak apps. Feeds them to fzf. Icons: `󰀻 ` for system apps, `󰏖 ` for Flatpak.
- **`shayar-finder`** -- Traverses directories up to 4 levels deep. Returns `TYPE_DIR:` or `TYPE_FILE:` prefixes for shell integration.
- **`shayar-quicklinks`** -- Reads `~/.quicklinks` (pipe-delimited: `Name | Description | Command`). Shows in fzf.
- **`shayar-screenshot`** -- Wraps `grim`/`slurp`. Supports fullscreen, area selection, and window selection. Delay options: 0s, 2s, 5s, 10s. Copies to clipboard via `wl-copy`. Saves to the folder specified by `SCREENSHOT_FOLDER` in `shayar.conf`.
- **`shayar-wallpaper`** -- Fzf wallpaper picker. Reads the wallpaper directory from `WALLPAPER_FOLDER` in `shayar.conf`. Filters to jpg/jpeg/png/webp/gif.
- **`shayar-menu`** -- Unified settings menu (rofi). Supports extension menu items.
- **`shayar-power-toggle`** — Power menu (Quickshell). Closes other 4 panels.
- **`shayar-calendar-toggle`** — Calendar panel (Quickshell). Closes other 4 panels.
- **`shayar-net-toggle`** — Network panel (Quickshell). Closes other 4 panels.
- **`shayar-bt-toggle`** — Bluetooth panel (Quickshell). Closes other 4 panels.
- **`shayar-vol-toggle`** — Volume panel (Quickshell). Closes other 4 panels.
- **`shayar-panel-pos`** — Calculates approximate Waybar icon positions from CSS values and screen resolution. Used by toggle scripts for icon-relative panel placement.
- **`shayar-sddm-sync`** — Syncs current wallpaper and matugen colors to SDDM login screen. Requires `--install` first, then run after wallpaper changes. Requires sudo.
- **`shayar-welcome-toggle`** — Welcome screen (Quickshell). Closes other 5 panels.
- **`shayar-welcome`** — Opens the welcome screen (Quickshell).
- **`shayar-wifi-popup`** — WiFi popup (legacy).

### `scripts/`
13 scripts. Grouped by function:

**Wallpaper pipeline:**
- `shayar-wallpaper` -- The main wallpaper engine. Full pipeline: validate image, cache path, apply effects, wait for awww-daemon, set wallpaper via `awww img`, run matugen, reload waybar/swaync, generate blurred wallpaper for lockscreen, create rofi rasi file. Flags: `--random`, `--effect`, `--monitor`, `--skip-wallpaper`, `--skip-theming`, `--crop-gravity`.
- `shayar-autostart` -- Main startup orchestrator. Creates cache folder, starts nm-applet, applies wallpaper theming.

**Toggles:**

- `shayar-toggle-statusbar` -- Toggles waybar on/off.
- `shayar-toggle-nmapplet` -- Start/stop NetworkManager applet.
- `shayar-toggle-scratchpad-window` -- Moves active window to/from the `special:magic` workspace.

**System tools:**
- `shayar-power` -- Power management capsule. Options: `--lock`, `--suspend`, `--logout`, `--reboot`, `--poweroff`. Overrides with hyprshutdown if available.
- `shayar-network` -- Starts NetworkManager if needed, opens nmtui.
- `shayar-notification-handler` -- Wrapper around `notify-send` with standardized options.
- `shayar-cliphist` -- Clipboard manager. Uses rofi. Modes: list, delete, wipe.

**Installation and updates:**
- `shayar-install-system-updates` -- Full system update. Supports Arch (yay/paru) and Fedora (dnf). Also updates Flatpak. Uses `gum` for colored output.

---



## Window Manager (`config/hypr/`)

### Entry point: `hyprland.lua`

Modular Lua config that loads everything in order:

1. `functions.lua` -- Helper functions (variant loader)
2. `monitors.lua` -- Monitor configuration
3. `input.lua` -- Keyboard and mouse
4. `gestures.lua` -- Touchpad gestures
5. `conf/autostart` -- Startup sequence
6. `colors` -- Color variables from matugen
7. `conf/environment` -- Environment variables
8. `conf/window` -- Window appearance
9. `conf/decoration` -- Blur, shadows, rounding
10. `conf/layout` -- Dwindle/master layout
11. `conf/workspace` -- Workspace config
12. `conf/misc` -- Miscellaneous settings
13. `conf/keybinding` -- All keybindings
14. `conf/windowrule` -- Window rules
15. `conf/animation` -- Animation settings
16. `conf/shayar` -- Shayar-specific rules and env vars
17. Optional `custom.lua` for user overrides

### `functions.lua`
- `load_variant(file, name)` -- Dynamically loads a variant file. Strips `.lua` and requires the module.

### `conf/autostart.lua`
Startup sequence on `hyprland.start`:
1. Export Wayland environment to systemd
2. Restart xdg-desktop-portal
3. Start awww-daemon (wallpaper daemon)
4. Set cursor theme
5. Start all listeners
6. Start polkit agent
7. Run `shayar-autostart` (wallpaper + nm-applet + waybar)
8. Run `gtk.sh` (GTK settings)
9. Start SwayNC
10. Start hypridle
11. Start Quickshell
12. Load cliphist history

### `conf/shayar.lua`
Shayar-specific configuration:
- PATH additions: `~/.local/bin`, `~/.cargo/bin`
- Window rules for: pavucontrol, Blueman, nwg-look, nwg-displays, MissionCenter, GNOME Calculator, Hyprland Share Picker, GTK File Picker, nm-connection-editor, Picture-in-Picture
- Environment variables: Wayland platform, Qt/GDK/Mozilla backends, cursor theme, SDL
- XWayland force zero scaling

### `colors.conf` / `colors.lua`
Material Design 3 color variables in Hyprland format. Primary: `#acc7ff`. Used by lock screen, decorations, and borders.

### `hyprlock.conf`
Lock screen:
- Background: blurred wallpaper from cache
- Input field: 200x50, primary color, rounded, password dots
- Clock: 70px, bottom-right
- User label: 20px, above clock
- Image: Square wallpaper preview, 280px, 40px rounding, border
- All colors pulled from `colors.conf`

### `hypridle.conf`
Idle management:
- 8 min: Dim to minimum brightness
- 10 min: Lock screen
- 11 min: Turn off display
- 30 min: Suspend

### `hyprpaper.conf`
Preloads `blank.png` as placeholder. Splash disabled. awww-daemon handles the actual wallpaper.

### `monitors.lua`
Default monitor: preferred mode, auto position, scale 1.

### `input.lua`
- Keyboard: US layout, `grp:alt_shift_toggle`
- Follow mouse: enabled
- Sensitivity: 0
- Touchpad: natural scroll off

### `gestures.lua`
- 3-finger vertical: workspace switch
- 3-finger horizontal: scroll (0.9 scale)
- 4-finger pinch out: fullscreen set
- 4-finger pinch in: fullscreen unset

### Keybindings (`conf/keybindings/default.lua`)

Main modifier: SUPER.

| Key | Action |
|-----|--------|
| `SUPER+Return` | Terminal |
| `SUPER+B` | Browser |
| `SUPER+E` | File manager |
| `SUPER+CTRL+E` | Emoji picker |
| `SUPER+CTRL+C` | Calculator / Calendar |
| `SUPER+1-0` | Focus workspace 1-10 |
| `SUPER+SHIFT+1-0` | Move window to workspace 1-10 |
| `SUPER+Q` | Kill active window |
| `SUPER+F` | Toggle fullscreen |
| `SUPER+T` | Toggle floating |
| `SUPER+J` | Toggle split |
| `SUPER+arrows` | Move focus |
| `SUPER+PRINT` | Screenshot |
| `SUPER+CTRL+L` | Power menu |
| `SUPER+CTRL+H` | Welcome screen |
| `SUPER+CTRL+N` | Network applet |
| `SUPER+CTRL+B` | Bluetooth applet |
| `SUPER+CTRL+W` | Wallpaper picker |
| `SUPER+CTRL+Return` | App launcher |
| `SUPER+CTRL+K` | Show keybindings |
| `SUPER+V` | Clipboard manager |

| `SUPER+SHIFT+L` | Lock screen |
| `SUPER+S` | Toggle special workspace "magic" |
| `SUPER+SHIFT+S` | Toggle window in/out scratchpad |
| `SUPER+scroll` | Switch workspace |
| `XF86Audio*` | Volume controls |
| `XF86MonBrightness*` | Brightness controls |
| `XF86AudioNext/Prev/Play/Pause` | Media controls |

### Decorations (`conf/decorations/`)
Only `default.lua` ships. Rounding 10, inactive opacity 0.9, shadow (range 32), blur (size 4, passes 4, vibrancy 0.1696).

### Animations (`conf/animations/`)
Only `default.lua` ships. MD3 standard. 12 bezier curves (linear, md3_standard, md3_decel, md3_accel, overshot, crazyshot, etc.). Window in/out speed 3, border speed 10, layers speed 1.6-3, workspace speed 5.

### Windows (`conf/windows/`)
Only `default.lua` ships. gaps_in 10, gaps_out 20, border_size 2, active_border gradient (primary->on_primary 90deg), inactive on_primary, dwindle layout.

### Monitor presets (`conf/monitors/`)
12 presets: 1366x768, 1440x1080, 1600x900, 1920x1080, 1920x1200, 2560x1440, 2560x1440@120, 2560x1440@120x125, 3440x1440, default-125, default, highres.

### Helper scripts (`scripts/`)
4 scripts: gtk, keybindings, launcher, power.

---

## Status Bar (`config/waybar/`)

### `launch.sh`
Main launcher with flock-based duplicate prevention:
1. Kills all running waybar instances
2. Sources `settings/shayar.conf` for `WAYBAR_THEME` and module toggles
3. Loads config/style from theme directory (supports config-custom/style-custom overrides)
4. Resolves `@DT_*@` tokens in JSON config and CSS via `design-tokens.env`
5. Flattens CSS `@import` chains into single temp file, re-resolves tokens
6. Respects `waybar-disabled` flag
7. Sets HYPRLAND_INSTANCE_SIGNATURE for IPC
8. Auto-restarts on crash (up to 5 retries)

### `toggle.sh`
Creates or removes the `waybar-disabled` flag, then relaunches.

### `config` (in theme dir)
Bar layout defined in `themes/shayar/config`:

```
modules-left:    clock
modules-center:  workspaces
modules-right:   pulseaudio | bluetooth | network | battery | divider | notification | exit
```

### `colors.css`
106 lines of matugen-generated CSS color variables (Material Design 3 palette).

### Themes (`themes/`)
Single glass theme in `themes/shayar/`.

---

## Application Launcher (`config/rofi/`)

### `config.rasi`
256 lines. Main launcher config:
- Modes: drun, filebrowser, run
- Font: Geist 11
- Icon theme: Tela-circle-dracula
- Window: 56em x 35em, rounded (24px), transparent with wallpaper background
- Two-panel layout: left (imagebox with inputbar + mode-switcher), right (listview)
- Loads: colors.rasi, rofi-font, rofi-border, rofi-border-radius, current wallpaper rasi

### `colors.rasi`
Material Design 3 color definitions for Rofi.

### Rofi config modes:

| File | Purpose | Window |
|------|---------|--------|
| `config.rasi` | Main app launcher | 56em x 35em, centered, two-panel |
| `config-cliphist.rasi` | Clipboard history | 30em, northeast, single-column |
| `config-cliphist.rasi` | Clipboard history | 30em, northeast, single-column |
| `config-screenshot.rasi` | Screenshot mode selector | 30em, northeast, single-column width |

---

---

## Notification Center (`config/swaync/`)

### `config.json`
- Position: right, top, overlay layer
- Control center: 360x700px
- Notification window: 360px wide
- Timeouts: 4s normal, 2s low, 6s critical
- Transition: 200ms
- Mutes Spotify notifications
- Widgets: dnd, buttons-grid, title, notifications
- Quick toggles: WiFi (nmcli), Bluetooth (rfkill), Mute (pactl), Lock (hyprlock)

### Themes:
- `glass/` -- style.css, control_center.css, notifications.css (solid backgrounds, token-driven)

---

## Quickshell Applets (`config/quickshell/`)

Replaced wlogout in 2026-07. Native QML panels with solid background, persistent Quickshell process, toggled via IPC. Each applet is self-contained (inline colors/tokens QtObjects). Color/token pipeline from `quickshell-tokens.json`.

### Panel style (all applets)
Solid `surface_container` background at 0.95 alpha, primary-tinted border, `RectangularShadow` with `z: -1`. No blur, no gradient. Tokens: `panel_bg_alpha`, `border_alpha`, `shadow_alpha`, `shadow_blur`.

### Toggle mechanism
All popups (power, calendar, net, bt, vol, welcome) use mutual exclusion — opening one closes the others via `qs ipc call <target> close`. Each toggle script calls `shayar-panel-pos` to calculate icon coordinates, then passes them via IPC so panels appear directly under their Waybar trigger icons. Power and Welcome center on screen.

### `PowerApp/PowerWindow.qml`
PanelWindow with 6 buttons (Lock, Suspend, Log Out, Hibernate, Restart, Shut Down), slide-from-right animation, keyboard navigation. Centers on right edge of screen.

### `CalendarApp/CalendarWindow.qml`
PanelWindow with a full month calendar, date picker, and quick navigation. Anchored top-left, positioned under clock icon on open. Auto-loads current month on open. Day cells have hover state.

### `NetApp/NetWindow.qml`
WiFi applet. Scans `nmcli` for nearby networks, shows SSID, signal strength, lock icon if secured, connected state. Actions: connect by BSSID, disconnect, toggle radio on/off, rescan. Auto-refreshes every 3s while open. Fully tokenized spacing/sizes.

### `BtApp/BtWindow.qml`
Bluetooth applet. Scans `bluetoothctl` for devices, shows name, MAC, paired/connected/trusted state. Actions: power toggle, connect/disconnect, pair+trust+connect, bounded 12s scan. Keyboard navigation (arrows + Enter). Fully tokenized spacing/sizes.

### `VolApp/VolWindow.qml`
Volume applet. Shows sink/source with slider, mute toggle, icon + label. Scroll wheel adjusts in 5% steps. Keyboard navigation (left/right + space). Per-app `vol_panel_radius`.

### `WelcomeApp/WelcomeWindow.qml`
First-boot welcome screen. Solid background, centered on screen. Displays keybindings list + quick launch buttons (Terminal, Browser, Launcher). Auto-shows on first boot via `.welcomed` flag file. IPC target: `welcome`.

### Toggle scripts
| Script | IPC target | Position |
|--------|-----------|----------|
| `shayar-power-toggle` | `power` | Centered on right edge |
| `shayar-calendar-toggle` | `calendar` | Under clock icon |
| `shayar-net-toggle` | `net` | Under network icon |
| `shayar-bt-toggle` | `bt` | Under bluetooth icon |
| `shayar-vol-toggle` | `vol` | Under volume icon |
| `shayar-welcome-toggle` | `welcome` | Centered on screen |
| `shayar-welcome` | `welcome` (open) | Centered on screen |

### Color pipeline
`matugen` → `~/.config/shayar/colors/quickshell.json` → read by `Process` in QML at startup. Reloaded via `qs ipc call theme-manager reload` on wallpaper change.


---

## Terminal (`config/kitty/`)

### `kitty.conf`
- Font: GeistMono Nerd Font, 12pt
- Window: 950x500, no decorations, padding 10, transparency 0.7, dynamic opacity
- Cursor: blink interval 0.5s, stop after 1s
- Scrollback: 2000 lines
- Audio bell: disabled
- Selection: transparent foreground/background
- Includes: cursor trail setting, `colors-matugen.conf`, `custom.conf`

### `colors-matugen.conf`
Matugen-generated terminal colors. Foreground: `#e4e1ee`, Background: `#12131b`. Full 16-color palette from Material Design 3.

---

## Material You Color Generation (`config/matugen/`)

### `config.toml`
11 template definitions. Each one takes a template file and generates output with matugen, then runs a post-hook:

| Template | Output | Post-hook |
| `kitty` | `kitty/colors-matugen.conf` | `pkill -SIGUSR1 kitty` |
| `hyprland` | `hypr/colors.conf` | `hyprctl reload` |
| `hyprland-lua` | `hypr/colors.lua` | `hyprctl reload` |
| `waybar` | `waybar/colors.css` | -- |
| `rofi` | `rofi/colors.rasi` | -- |
| `gtk3` | `gtk-3.0/colors.css` | -- |
| `gtk4` | `gtk-4.0/colors.css` | -- |
| `pywalfox` | `~/.cache/wal/colors.json` | -- |
| `swaync` | `swaync/colors.css` | -- |
| `sequences` | `~/.cache/wal/sequences` | -- |
| `primary` | `shayar/colors/primary` | -- |
| `secondary` | `shayar/colors/secondary` | -- |
| `onsurface` | `shayar/colors/onsurface` | -- |
| `onprimary` | `shayar/colors/onprimary` | -- |

### Templates (`templates/`)
11 template files that matugen processes.

### Post-hooks:
(none currently shipped)

---

## Shell Configs (`config/bashrc/`, `config/zshrc/`)

Both shells share the same structure and aliases.

### Init (`00-init`):
- `EDITOR=nvim`
- PATH: `/usr/lib/ccache/bin/`, `~/.cargo/bin/`, `~/.local/bin/`

### Aliases (`10-aliases`):

| Alias | Command |
|-------|---------|
| `nf` | `neofetch` |
| `ls` | `eza -a --icons=always` |
| `ll` | `eza -al --icons=always` |
| `lt` | `eza -a --tree --level=1 --icons=always` |
| `v/vim` | `$EDITOR` (nvim) |
| `wifi` | `nmtui` |
| `apps` | `shayar-apps` |
| `screenshot` | `shayar-screenshot` |
| `updates` | `shayar-install-system-updates` |
| `lock` | `hyprlock` |
| `system` | system monitor |
| `quick` | `shayar-quicklinks` |
| `wallpaper` | `shayar-wallpaper` |
| `gs/ga/gc/gp/gpl` | git commands |

### Customization (`20-customization`):
ZSH uses oh-my-zsh with plugins (git, sudo, web-search, archlinux, zsh-autosuggestions, zsh-syntax-highlighting, fast-syntax-highlighting, copyfile, copybuffer, dirhistory) and FZF keybindings.

### Autostart (`30-autostart`):
- `finder()` function wrapping `shayar-finder` (cd into dirs, edit files)

### `themes/matugen.theme`
89 lines. Generated Material Design 3 theme with full gradient definitions.

---

## Vim (`config/vim/`)

### `.vimrc`
72 lines. Line numbers, filetype detection, syntax highlighting, 4-space indentation (expandtab), no backup, scroll offset 10, mouse support, incremental search, smart case, show command/mode/match, 1000 history lines.

---

## GTK Theming (`config/gtk-3.0/`, `config/gtk-4.0/`)

### GTK 3.0:
- `settings.ini` -- Theme: Adwaita, Icons: Tela-circle-dracula, Font: Geist Semi-Bold 11, Cursor: Bibata-Modern-Ice 24, Dark mode: enabled, Antialiasing: hintslight rgb
- `gtk.css` -- Custom CSS overrides
- `colors.css` -- Matugen-generated GTK colors

### GTK 4.0:
- `settings.ini` -- Same as GTK3
- `gtk.css` -- Custom CSS overrides
- `colors.css` -- Matugen-generated GTK colors

---

## Qt Theming (`config/qt6ct/`)

### `qt6ct.conf`
- Color scheme: darker.conf (custom palette)
- Icon theme: Tela-circle-dracula
- Style: Breeze
- Standard dialogs: default
- Single-click activation, no button icons, no context menu shortcuts

---

## Static Assets (`assets/`)

- `icons/` -- Empty directory
- `wallpapers/` -- Empty directory

The actual wallpaper and icon assets live in `config/shayar/assets/` and `config/shayar/wallpapers/`.

---

## Browser Flags

- `chromium-flags.conf` -- `--ozone-platform=wayland`, `--ozone-platform-hint=wayland`, touchpad overscroll history
- `edge-flags.conf` -- `--ozone-platform-hint=auto`, `--enable-features=UseOzonePlatform`, `--ozone-platform=wayland`

---

## Color Palette

Source color: `#acc7ff` (blue)

| Role | Color | Usage |
|------|-------|-------|
| Primary | `#acc7ff` | Main accent, borders, highlights |
| On Primary | `#062f64` | Text on primary |
| Secondary | `#aed280` | Success, active states |
| Tertiary | `#ffb3b0` | Warnings, errors |
| Surface | `#12131b` | Background |
| On Surface | `#e4e1ee` | Main text |
| Surface Container | `#1f1f28` | Card backgrounds |
| Outline | `#8e909b` | Subtle borders |
| Error | `#ffb4ab` | Error states |
| Error Container | `#93000a` | Error backgrounds |

---

## Dependency Graph

```
shayar-wallpaper (core)
  -> awww-daemon (wallpaper setter)
  -> matugen (color generation)
    -> generates: kitty, waybar, rofi, gtk, hypr, swaync colors
  -> waybar/launch.sh
  -> swaync-client

shayar-autostart
  -> nm-applet
  -> shayar-wallpaper
  -> listeners.sh --startall
  -> waybar/launch.sh
  -> swaync
  -> hypridle
  -> cliphist

Keybinds -> scripts -> bin/ tools -> fzf/gum/grim/slurp
```
