# Changelog

## [0.4.0] - 2026-07-13

### Refactored
- Centralized token/color reading into a typed `ThemeManager.qml` singleton, eliminating redundant shell forks and reducing boot time across all 6 Quickshell applets
- Unified design token compiler pipeline into a fast, native Python script (`design_tokens.py`), removing slow sequential subshell pipelines in `shayar-design-tokens`

### Fixed
- Waybar right pill positioning: corrected inverted index offsets in `shayar-panel-pos` (mapping Exit rightmost (0) to pulseaudio leftmost (6))
- Applet tray alignment: center-aligned Volume, WiFi, and Bluetooth panels directly under Waybar status bar icons with viewport edge-clamping bounds
- Power menu layout: restored vertical centering along the right-hand screen edge with a clean 12px margin padding
- Removed `hyprshutdown` wrapper in `shayar-power` to bypass split-second GTK dialog flashes, routing reboot/poweroff directly to native actions

### Installation
- Ensured `python` is bundled in the bootstrap installer packages
- Added automatic creation of the `~/Pictures/Screenshots` directory on install to ensure Swappy works out-of-the-box
- Documented `shayar-sddm-sync --install` in post-install instructions
