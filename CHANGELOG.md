# Changelog

## [1.0.0] - 2026-09-04

### Added
- **Caelestia Shell Architecture Integration**:
  - Full adoption of Caelestia Shell (`caelestia-shell`) desktop shell engine providing dynamic status bar, Bento dashboard (calendar, weather forecast, system metrics, hardware graphs), notification sidebar, quick utilities drawer (Wi-Fi & Bluetooth management), audio/brightness OSD, and session management drawer.
  - Hyprland global shortcuts and IPC triggers for drawer navigation (`qs -c caelestia ipc call drawers toggle <name>`).
  - Added CLI shim `caelestia` wrapping quickshell daemon management.
- **Bespoke Shayar Identity & Vector Branding**:
  - Custom geometric Quill "V" emblem vector asset in SVG and high-resolution PNG.
  - Integrated Shayar logo across the status bar, Bento dashboard, lock screen, and system fetch card.
  - Overhauled Caelestia Nexus "About" page (`AboutPage.qml`) displaying Shayar v1.0.0 identity hero with proper attribution for upstream components (Caelestia Shell, Hyprland, Quickshell).
  - Replaced `caelestiafetch` with customized `shayarfetch.sh` (`Fetch.qml`) displaying OS as `Shayar (EndeavourOS)` and Quill emblem.
- **Systemd User Lingering & Background Page-Cache Preloader**:
  - Introduced `shayar-preload` using kernel `posix_fadvise(POSIX_FADV_WILLNEED)` to warm over 700 desktop binaries, Qt6 libraries, fonts, and QML modules into RAM page cache during boot while SDDM displays the greeter.
  - Created `shayar-preload.service` user systemd unit running with idle I/O priority at machine boot.
  - Enabled user session lingering (`loginctl enable-linger`) so `systemd --user`, PipeWire audio daemons, and user D-Bus sockets initialize in parallel with SDDM before login.
- **Dynamic HiDPI Scale Synchronization**:
  - Added `shayar-scale-sync` to detect active monitor scaling from Hyprland and propagate `GDK_SCALE` and `QT_SCALE_FACTOR` asynchronously.
- **Auto-Login & SDDM Management**:
  - Added `shayar-autologin` utility to manage SDDM auto-login configurations (`--status`, `--enable`, `--disable`).
  - Added `shayar-sddm-sync` tool to sync wallpapers, colors, and design tokens to the SDDM lock-like greeter theme.

### Changed
- **Color Generation Pipeline**:
  - Upgraded Matugen pipeline with `caelestia-scheme.json` template writing directly to `~/.local/state/caelestia/scheme.json` for instant reactive desktop theme updates.
- **Hyprland Architecture & Window Rules**:
  - Reorganized `autostart.lua` into non-blocking parallel execution waves for instant compositor responsiveness.
  - Modernized window and layer rules in `shayar.lua` for Caelestia drawers and background surfaces.
  - Migrated keybindings in `keybindings/default.lua` to Caelestia drawers and modern Wayland tools.
- **GTK Theming**:
  - Automated compilation of `design-tokens-gtk.ini` from tokens and symlinked GTK 3.0 / GTK 4.0 configurations.

### Performance
- **Wallpaper & Matugen Caching**:
  - Implemented hash-based scheme and blur caching in `shayar-autostart`, reducing serial desktop startup time from **809 ms down to 21 ms** (97% speedup).
- **Asynchronous Startup Pipeline**:
  - Parallelized desktop daemons and replaced synchronous blocking Lua subshell calls (`io.popen`) in `autostart.lua` with asynchronous execution, reducing total serial startup wait from ~1,000 ms to ~280 ms.
- **Instant Login Handoff**:
  - Combined systemd user session lingering and RAM page-cache preloading so login handoff from SDDM to Hyprland is immediate.

### Fixed
- **Critical Battery Hibernate Freeze (NVIDIA Crash)**:
  - Resolved unrecoverable black screen and kernel panic (`drm:__nv_drm_semsurf_wait_fence_work_cb`) caused by Caelestia attempting to hibernate on critical battery without an active swap resume partition.
  - Added safe shutdown routing in `BatteryMonitor.qml` and set `"criticalLevel": 0` in `shell.json`.
- **GTK Configuration Symlink Error**:
  - Resolved missing ini file error in `gtk.sh` by generating valid GTK settings ini directly via `design_tokens.py`.
- **Git Ignore Overrides Trap**:
  - Fixed wildcard `overrides/` rule in `.gitignore` that was inadvertently ignoring Caelestia QML overlay files.

### Removed
- **Legacy Status Bar & Notification Center**:
  - Removed obsolete Waybar configurations, launch scripts, and styles in favor of Caelestia Shell.
  - Removed SwayNC configuration, CSS themes, and control center templates.
- **Legacy Standalone Quickshell Applets**:
  - Removed custom Qt Quick applet modules (`BtApp`, `CalendarApp`, `NetApp`, `PowerApp`, `VolApp`, `WelcomeApp`, `ThemeManager`) superseded by Caelestia drawers.
- **Legacy Rofi Pickers**:
  - Removed obsolete rofi configuration files and styles in favor of Caelestia launcher and Fuzzel.
