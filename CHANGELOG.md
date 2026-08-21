# Changelog

## [0.7.0] - 2026-08-21

### Added
- **Quickshell Bluetooth Overhaul**:
  - Live device scanning with discovery feedback and empty-state guidance.
  - Real-time connection/pairing status banner feedback (`Connecting...`, `Disconnecting...`, `Pairing...`).
  - Connected device battery percentage indicators with dynamic battery level icons.
  - Visual distinction between paired and connected device badges.
- **Quickshell Network Overhaul**:
  - Dynamic Wi-Fi scanning with live status banners.
  - Active IP address display (`root.activeIp`) and frequency band indicators (2.4GHz / 5GHz).
  - Signal strength indicators and lock icons for secured networks.
  - Robust wireless interface auto-discovery for clean disconnection.
- **SwayNC Backlight Control**:
  - Added brightness slider widget to SwayNC control center with themed track and slider highlights.
  - Added `shayar-brightness-get` helper for direct sysfs backlight queries.
- **Waybar Modules & Interaction**:
  - Added `shayar-vol-scroll` helper for smooth volume adjustments with safety clamping.
  - Added multi-line tooltips for Network (IP, CIDR, interface, GHz frequency) and Bluetooth (controller alias/address, enumerated connected devices and battery levels).
  - Added Font Awesome 6 Free + Symbols Nerd Font Mono battery glyph styling.
- **Rofi Modular Base**: Introduced `shared-base.rasi` to eliminate duplication across cliphist, compact, and popup pickers.

### Changed
- **Quickshell Calendar Applet**: Modernized header layout into a cohesive pill container with integrated month navigation and "Today" button; removed redundant week-number column and pulse animations.
- **Quickshell Welcome Applet**: Expanded keybindings directory to include modern shortcuts (`SUPER + E`, `SUPER + CTRL + N/B`, `SUPER + SHIFT + L`, workspace navigation).
- **Process Management**: Centralized Quickshell lifecycle management (`ensure_qs` with flock) in `library.sh` across all toggle and app launcher scripts.
- **Theme Uniformity**: Set Quickshell panel and SwayNC notification background alphas to solid (1.0) in accordance with the solid surface design theme.
- **Hyprland Startup**: Migrated SwayNC startup to `systemctl --user start swaync.service` and streamlined portal daemon restart.

### Performance
- **Waybar Token Resolution**: Replaced 200+ individual `sed -i` forks in `launch.sh` with a single-pass `awk` resolution engine, dramatically speeding up status bar startup and hot-reloads.
- **Listener Management**: Replaced static 1s sleeps in `listeners.sh` with a fast 20ms polling loop (max 100ms) for snappy listener process restarts.

### Fixed
- **Multi-Monitor Scaling**: Made monitor scale detection in `autostart.lua` robust and JSON key-order independent with focused-monitor prioritization.
- **Idempotent PATH**: Prevented duplicate PATH prepending on Hyprland configuration reloads in `shayar.lua`.
- **Wallpaper Pipeline**: Hardened boolean checks in `shayar-wallpaper` and added support for `MATUGEN_MODE` and `MATUGEN_SCHEME`.
- **Rofi Cliphist Handling**: Added error guards to avoid script termination when cancelling rofi clipboard menus.
