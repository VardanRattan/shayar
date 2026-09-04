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

#### `shayar.conf`
Consolidated settings file. Replaced all individual value files. 24 lines with `<KEY>="<VALUE>"` format. Scripts source it directly. Encapsulated settings:

| Variable | Default | What it does |
|----------|---------|-------------|
| `TERMINAL` | `kitty` | Default terminal emulator |
| `BROWSER` | `firefox` | Default browser |
| `FILE_MANAGER` | `nautilus --new-window` | Default file manager |
| `CALCULATOR` | `flatpak run org.gnome.Calculator` | Default calculator application |
| `EMOJI_PICKER` | `flatpak run com.tomjwatson.Emote` | Default emoji picker |
| `SYSTEM_MONITOR` | `missioncenter` | Default system monitor |
| `BLUETOOTH_MANAGER` | `blueman-manager` | Default bluetooth manager |
| `WALLPAPER_FOLDER` | `${HOME}/.config/shayar/wallpapers` | Custom wallpaper directory |
| `WALLPAPER_TRANSITION` | `simple` | awww wallpaper transition effect |
| `BLUR` | `50x30` | Lock screen blur amount |
| `SCREENSHOT_FOLDER` | `${HOME}/Pictures` | Where screenshots save |
| `SCREENSHOT_FILENAME` | `screenshot_$(date +%Y%m%d_%H%M%S).jpg` | Screenshot naming pattern |

Executable wrappers in `config/shayar/settings/` (`terminal.sh`, `browser.sh`, `filemanager`, `networkmanager.sh`, `emojipicker.sh`, `calculator.sh`, `calendar.sh`, `systemmonitor`) source `shayar.conf` and fall back to defaults if it's missing.

### `themes/`
Only the glass theme ships with Shayar. Contains:

- **`shayar.json`** — Material Design 3 palette (source for matugen color generation).
- **`design-tokens.json`** — Single source of truth for **all** visual values: colors, typography, spacing, opacity, animation, kitty, quickshell (218 tokens across 7 sections). Every hardcoded visual value originates here.

### Generated token files (from `design-tokens.json`):

| File | Format | Used By |
|------|--------|---------|
| `design-tokens.css` | `@define-color dt-*` | GTK and desktop styling |
| `design-tokens.lua` | `dt.*` Lua table | hyprland `*.lua` configs |
| `design-tokens.rasi` | `dt-*` variables | rasi styling |
| `design-tokens.env` | `DT_*` env vars | bash scripts via `source` |
| `design-tokens-hyprlock.conf` | `$dt-*` variables | hyprlock lockscreen |
| `design-tokens-kitty.conf` | kitty config directives | kitty terminal |
| `shayar.json` | hex JSON palette | matugen color engine |
| `quickshell-tokens.json` | JSON tokens | Quickshell singleton |
| `fastfetch.jsonc` | JSONC config | fastfetch system info |

Run `shayar-design-tokens generate` after changing `design-tokens.json` to regenerate all format outputs.

### Design tokens philosophy
Colors come from `shayar.json` → matugen → per-component `colors.*` files (colors.css, colors.lua, colors.conf, colors.rasi). The `design-tokens.json` mirrors the color palette for reference and defines every other visual value: spacing, rounding, gaps, font sizes, animation speeds, opacities, shadows, and window dimensions. Component configs reference these generated files instead of hardcoding values.

**Already migrated:**

| Component | Token source | Values replaced |
|-----------|-------------|-----------------|
| Hyprland decorations | `dt.spacing.*`, `dt.opacity.*` | rounding, gaps, blur, shadow, opacity |
| Hyprland windows | `dt.spacing.*` | gaps_in, gaps_out, border_size |
| Hyprland animations | `dt.animation.*` | all bezier curves + speeds |
| Hyprlock lockscreen | `design-tokens-hyprlock.conf` | sizes, dots, rounding, positions, shadow |
| Kitty terminal | `design-tokens-kitty.conf` | font, size, window dims, padding, scrollback |
| GTK styling | `gtk.css`, `colors.css` | Material You dynamic theme colors |
| Caelestia Shell | `shell.json`, `scheme.json` | dynamic tokens, palette, logo, and drawer configurations |
| SDDM lockscreen | `sddm-theme.conf` | tokens, avatar, blur, and color variables |

### `colors/`
Matugen output. The primary color `#acc7ff` drives the whole palette. Files: `primary`, `secondary`, `onsurface`, `onprimary`. Other scripts source these for dynamic color references.

### `assets/`
Branding. `shayar-logo.png`, `shayar.svg`. The official mark is the **Geometric Quill "V"** — an aerodynamic fountain-pen nib converging into a "V" with a floating celestial star (*nuqta*), symbolizing poetry, precision, and velocity. Rendered in vector SVG and high-res PNG.

### `wallpapers/`
Default wallpapers. `default.png` is the shipped default wallpaper.

### `bin/`
19 CLI tools and extension symlinks available system-wide after linking:

- **`shayar-apps`** -- Scans `/usr/share/applications` and `~/.local/share/applications` for `.desktop` files. Handles Flatpak apps. Feeds them to fzf. Icons: `󰀻 ` for system apps, `󰏖 ` for Flatpak.
- **`shayar-finder`** -- Traverses directories up to 4 levels deep. Returns `TYPE_DIR:` or `TYPE_FILE:` prefixes for shell integration.
- **`shayar-quicklinks`** -- Reads `~/.quicklinks` (pipe-delimited: `Name | Description | Command`). Shows in fzf.
- **`shayar-screenshot`** -- Wraps `grim`/`slurp`. Supports fullscreen, area selection, and window selection. Delay options: 0s, 2s, 5s, 10s. Copies to clipboard via `wl-copy`. Saves to the folder specified by `SCREENSHOT_FOLDER` in `shayar.conf`.
- **`shayar-wallpaper`** -- Fzf wallpaper picker. Reads the wallpaper directory from `WALLPAPER_FOLDER` in `shayar.conf`. Filters to jpg/jpeg/png/webp/gif.
- **`shayar-menu`** -- Unified settings menu (rofi). Supports extension menu items.
- **`caelestia`** — CLI bridge shim routing wallpaper commands to `shayar-wallpaper` and passing other subcommands to `/usr/bin/caelestia`.
- **`shayar-power-toggle`** — Power / Session menu (Caelestia session drawer).
- **`shayar-calendar-toggle`** — Calendar / Dashboard (Caelestia dashboard drawer).
- **`shayar-net-toggle`** — Network & quick controls (Caelestia utilities drawer).
- **`shayar-bt-toggle`** — Bluetooth & quick controls (Caelestia utilities drawer).
- **`shayar-vol-toggle`** — Audio OSD pill (Caelestia osd drawer).
- **`shayar-vol-scroll`** — Smooth volume scroll helper with safety clamping.
- **`shayar-brightness-get`** — Direct sysfs backlight reader for brightness controls.
- **`shayar-sddm-sync`** — Syncs current wallpaper and matugen colors to SDDM login screen. Requires `--install` first, then run after wallpaper changes. Requires sudo.
- **`shayar-wifi-popup`** — WiFi popup (legacy).
- **`hypridle-inhibitor`** — Symlink to extension script for toggling idle inhibition.

### `scripts/`
14 scripts. Grouped by function:

**Core & Design Tokens:**
- `design_tokens.py` -- Python compiler generating 10 configuration formats from `design-tokens.json`.
- `shayar-design-tokens` -- CLI wrapper for `design_tokens.py` (`generate`, `validate`, `--with-colors`).
- `shayar-apply-theme` -- Reads theme manifest `themed.lst` and activates themes.
- `shayar-init-overrides` -- Scaffolds user override skeleton in `~/.config/overrides/`.

**Wallpaper pipeline:**
- `shayar-wallpaper` -- The main wallpaper engine. Full pipeline: validate image, cache path, apply effects, wait for awww-daemon, set wallpaper via `awww img`, run matugen, sync Caelestia Shell palette (`scheme.json`), and generate blurred wallpaper for lockscreen. Flags: `--random`, `--effect`, `--monitor`, `--skip-wallpaper`, `--skip-theming`, `--crop-gravity`.
- `shayar-autostart` -- Main startup orchestrator. Creates cache folder, applies wallpaper theming.

**Toggles:**
- `shayar-toggle-statusbar` -- Toggles Caelestia status bar via IPC (`drawers toggle bar`).
- `shayar-toggle-scratchpad-window` -- Moves active window to/from the `special:magic` workspace.

**System tools:**
- `shayar-power` -- Power management capsule. Options: `--lock`, `--suspend`, `--logout`, `--reboot`, `--poweroff`. Calls Caelestia lock IPC with clean session handlers.
- `shayar-network` -- Starts NetworkManager if needed, opens nmtui.
- `shayar-notification-handler` -- Wrapper around `notify-send` with standardized options.
- `shayar-cliphist` -- Clipboard manager leveraging `caelestia clipboard`. Modes: list, delete, wipe.

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
5. Dynamic HiDPI scale detection and environment propagation (`GDK_SCALE`, `QT_SCALE_FACTOR`)
6. Start all listeners
7. Start polkit agent
8. Run `shayar-autostart` (wallpaper + nm-applet, sets `waybar-disabled`)
9. Run `gtk.sh` (GTK settings)
10. Start hypridle
11. Start Caelestia Shell (`caelestia shell -d`)
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
Lock screen (fully tokenized via `design-tokens-hyprlock.conf`):
- Background: blurred wallpaper from cache
- Input field: primary color, rounded, password dots, tokenized dimensions
- Clock: bottom-right, tokenized font size
- User label: above clock
- Image: Square wallpaper preview with rounded borders
- All colors pulled from `colors.conf` and tokens from `design-tokens-hyprlock.conf`

### `hypridle.conf`
Idle management:
- 8 min: Dim to minimum brightness
- 10 min: Lock screen
- 11 min: Turn off display
- 30 min: Suspend

### `hyprpaper.conf`
Preloads `blank.png` as placeholder. Splash disabled. awww-daemon handles the actual wallpaper.

### `monitors.lua`
Default monitor: preferred mode, auto position, scale 1. Dynamic scaling is calculated on startup in `autostart.lua`.

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
| `SUPER+SHIFT+B` | Toggle statusbar |
| `SUPER+E` | File manager |
| `SUPER+CTRL+E` | Emoji picker |
| `SUPER+CTRL+C` | Calculator |
| `SUPER+1-0` | Focus workspace 1-10 |
| `SUPER+SHIFT+1-0` | Move window to workspace 1-10 |
| `SUPER+Q` | Kill active window |
| `SUPER+F` | Toggle fullscreen |
| `SUPER+T` | Toggle floating |
| `SUPER+J` | Toggle split |
| `SUPER+arrows` | Move focus |
| `SUPER+PRINT` | Screenshot (`shayar-screenshot`) |
| `PRINT` | Interactive screenshot with Swappy |
| `ALT+SPACE` | Unified settings menu (`shayar-menu`) |
| `SUPER+CTRL+Return` | App launcher |
| `SUPER+CTRL+K` | Show keybindings |
| `SUPER+V` | Clipboard manager (`shayar-cliphist`) |
| `SUPER+CTRL+L` | Power menu |
| `SUPER+CTRL+H` | Welcome screen |
| `SUPER+CTRL+W` | Wallpaper picker |
| `SUPER+CTRL+N` | Network applet |
| `SUPER+CTRL+B` | Bluetooth applet |
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
Ships `default.lua`. Monitor geometry and HiDPI scaling are dynamically discovered at runtime in `autostart.lua`.

### Helper scripts (`scripts/`)
4 scripts: gtk, keybindings, launcher, power.

---


## Caelestia Shell (`config/caelestia/`)

Caelestia is a full-featured, Qt6/Quickshell-based desktop shell that unifies status bar, application launcher, grouped notification center, quick utilities drawer, audio/brightness OSD, Bento dashboard, and lockscreen.

### `shell.json`
Main configuration file symlinked to `~/.config/caelestia/shell.json`:
- **Logo**: Custom vector mark (`~/.config/shayar/assets/shayar.svg`) driving the top bar, dashboard user card, and lock screen fetch.
- **Idle**: Configured with `"timeouts": []` to disable rogue Caelestia DPMS/suspend routines, delegating power management entirely to Shayar's safe `hypridle` daemon.
- **Apps**: Configures preferred default applications (`terminal: ["kitty"]`).
- **Bar**: Configures persistent status bar with dynamic workspace pill, active window title, system tray, and drawer launchers.
- **Session**: Configures session drawer actions mapped to Shayar's `shayar-power` utility (`logout`, `shutdown`, `reboot`, `hibernate`).
- **Paths**: Points wallpaper directory to `~/.config/shayar/wallpapers`.
- **Services**: Configures smart scheme and PipeWire audio backend integrations.

### Color & Wallpaper Synchronization
- **Color Scheme**: Matugen compiles `config/matugen/templates/caelestia-scheme.json` into `~/.local/state/caelestia/scheme.json` on wallpaper change. Caelestia shell watches this file via `FileView` and hot-reloads all colors in real time.
- **Wallpaper Path**: `shayar-wallpaper` writes current image path to `~/.local/state/caelestia/wallpaper/path.txt`, driving Caelestia's background and previews.
- **CLI Bridge (`caelestia`)**: CLI shim at `config/shayar/bin/caelestia` intercepts wallpaper picking events from the Caelestia UI and delegates them to `shayar-wallpaper`.

### Drawers & Keybindings
| Drawer / Component | Hyprland Bind | IPC Command | Description |
|-------------------|---------------|-------------|-------------|
| **Launcher** | `SUPER` (release) / `SUPER+CTRL+Return` | `qs -c caelestia ipc call drawers toggle launcher` | Searchable app launcher, calculator, scheme selector |
| **Session** | `SUPER+CTRL+L` | `qs -c caelestia ipc call drawers toggle session` | Animated logout, shutdown, reboot, lock controls |
| **Utilities** | `SUPER+CTRL+N` / `SUPER+CTRL+B` | `qs -c caelestia ipc call drawers toggle utilities` | WiFi & Bluetooth controls, screen recording, idle inhibit |
| **Dashboard** | `SUPER+CTRL+D` | `qs -c caelestia ipc call drawers toggle dashboard` | Bento grid: calendar, weather, media, hardware metrics |
| **Sidebar** | — | `qs -c caelestia ipc call drawers toggle sidebar` | Grouped notification history & DND controls |
| **OSD** | — | `qs -c caelestia ipc call drawers toggle osd` | Floating volume & brightness pill |
| **Lock Screen** | `SUPER+SHIFT+L` | Hyprland global `caelestia:lock` | Native Wayland lockscreen with pam auth & media |

---

---

## Terminal (`config/kitty/`)

### `kitty.conf`
- Single source of truth: includes `design-tokens-kitty.conf` (font, font size, window size, padding, scrollback, dynamic background opacity)
- Audio bell: disabled
- Selection: transparent foreground/background
- Includes: `colors-matugen.conf`, `custom.conf`

### `colors-matugen.conf`
Matugen-generated terminal colors. Foreground: `#e4e1ee`, Background: `#12131b`. Full 16-color palette from Material Design 3.

---

## Material You Color Generation (`config/matugen/`)

### `config.toml`
10 template definitions. Each one maps an input template to an output path with optional post-hooks:

| Template | Output | Post-hook |
|---|---|---|
| `kitty` | `kitty/colors-matugen.conf` | `pkill -SIGUSR1 kitty` |
| `hyprland` | `hypr/colors.conf` | -- |
| `hyprland-lua` | `hypr/colors.lua` | `hyprctl reload` |
| `gtk3` | `gtk-3.0/colors.css` | -- |
| `gtk4` | `gtk-4.0/colors.css` | -- |
| `primary` | `shayar/colors/primary` | -- |
| `secondary` | `shayar/colors/secondary` | -- |
| `on_surface` | `shayar/colors/onsurface` | -- |
| `on_primary` | `shayar/colors/onprimary` | -- |
| `caelestia` | `~/.local/state/caelestia/scheme.json` | -- |

### Templates (`templates/`)
9 template files that matugen processes.

---

## Shell Configs (`config/bashrc/`, `config/zshrc/`, `config/shared-shell/`)

Both shells share the same modular structure, aliases, and environment definitions via `config/shared-shell/`.

### Init (`00-init`):
- `EDITOR=nvim`
- PATH: `/usr/lib/ccache/bin/`, `~/.cargo/bin/`, `~/.local/bin/`

### Aliases (`shared-shell/aliases`):

| Alias | Command |
|-------|---------|
| `nf` | `fastfetch --config ~/.config/shayar/themes/fastfetch.jsonc` (fallback `neofetch`) |
| `ls` | `eza -a --icons=always` |
| `ll` | `eza -al --icons=always` |
| `lt` | `eza -a --tree --level=1 --icons=always` |
| `v/vim` | `$EDITOR` (nvim) |
| `wifi` | `nmtui` |
| `apps` | `shayar-apps` |
| `screenshot` | `shayar-screenshot` |
| `updates` | `shayar-install-system-updates` |
| `lock` | `hyprlock` |
| `system` | `systemmonitor` |
| `quick` | `shayar-quicklinks` |
| `wallpaper` | `shayar-wallpaper` |
| `gs/ga/gc/gp/gpl` | git commands |

### Customization (`20-customization`):
ZSH uses oh-my-zsh with plugins (git, sudo, web-search, archlinux, zsh-autosuggestions, zsh-syntax-highlighting, fast-syntax-highlighting, copyfile, copybuffer, dirhistory) and FZF keybindings.

### Autostart (`shared-shell/autostart`):
- `finder()` function wrapping `shayar-finder` (cd into dirs, edit files)

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

## Static Assets

All branding and wallpaper assets live directly inside `config/shayar/assets/` and `config/shayar/wallpapers/`.

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
    -> generates: kitty, gtk, hypr, caelestia scheme.json
    -> updates ~/.local/state/caelestia/wallpaper/path.txt
  -> Caelestia Shell (hot-reloads via FileView)

shayar-autostart
  -> nm-applet
  -> shayar-wallpaper
  -> listeners.sh --startall
  -> hypridle
  -> caelestia shell -d
  -> cliphist

Keybinds -> scripts -> bin/ tools -> fzf/gum/grim/slurp/fuzzel
```

---

## Credits & Acknowledgments

- **[ML4W Dotfiles](https://github.com/mylinuxforwork/dotfiles)** by Stephan Raabe — The modular Hyprland configuration structure, window rules, and environment foundation.
- **[Caelestia Shell](https://github.com/caelestia-dots/caelestia-shell)** by Caelestia Dots — The desktop shell engine delivering the dynamic status bar, Bento dashboard, notification sidebar, quick utilities drawer, audio/brightness OSD, and session management.
- **[Matugen](https://github.com/InioX/matugen)** by InioX — Material You (Material 3) palette generation from wallpapers.
- **[Quickshell](https://quickshell.outfoxxed.me/)** by Outfoxxed — The high-performance reactive QML desktop shell engine.
- **[Hyprland](https://hyprland.org/)** by Vaxry — The fluid, dynamic Wayland compositor.
