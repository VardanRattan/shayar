# Changelog

## [0.6.0] - 2026-07-24

### Changed
- **Typography Engine**: Replaced Fira Sans, JetBrains Mono, and Rubik with the Geist font family for UI and monospace elements.
- **Rofi Aesthetic**: Streamlined Rofi menus by removing window mode, tightening element spacing, updating search icons, and modernizing layout.
- **Waybar Style**: Applied pixel-perfect adjustments to Waybar pills (margins, padding, box-shadows, transitions) for a more refined glassmorphism effect.
- **Quickshell Token Binding**: QML panels (Bluetooth, Network, Volume, Welcome) now dynamically read ui_family and mono_family directly from design tokens rather than hardcoded fonts.

### Fixed
- **Design Tokens Pipeline**: Prevented partial token replacement bugs in Python compiler by sorting color tokens by length.
- **SDDM Reload Hook**: Moved SDDM background reloading to run asynchronously during wallpaper switches, preventing blocking delays.
- **SDDM Login Focus**: Added logic via `focusTimer` to autofocus the password field on login screen if username is prefilled.
