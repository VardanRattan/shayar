# Changelog

## [0.3.0] - 2026-07-13

### Removed
- SwayOSD dependency — volume/brightness keybinds now use `wpctl`/`brightnessctl` directly
- Removed `swayosd-server` from autostart, PKGBUILD, install.sh, and doctor check

### SwayNC solid conversion
- Converted notification center from gradient glassmorphism to solid backgrounds
- Notifications: `alpha(@surface_container, 0.8)` with `alpha(@primary, 0.5)` border
- Control center: `alpha(@surface, 0.5)` with `alpha(@primary, 0.5)` border, removed `opacity: 0.9`
- Wired 3 unused opacity tokens (`swaync_background_alpha`, `swaync_notification_bg_alpha`, `swaync_button_hover_alpha`) into CSS templates
- Transition hardcoded `200ms` → token `@DT_ANIMATION_SWAYNC_TRANSITION@`

### SDDM token integration
- Added 11 design tokens for SDDM: font, clock size, button font size, input dimensions, radius, spacing, blur, brightness, saturation
- `shayar-sddm-sync` now sources `design-tokens.env` — QML uses token values with fallback defaults
- `shayar-wallpaper` now calls `reload_sddm` after matugen (auto-syncs if SDDM installed)

### Fastfetch token integration
- Added `fastfetch_color` token to design-tokens.json
- `config.jsonc` uses `@DT_TYPOGRAPHY_FASTFETCH_COLOR@` placeholder
- `shayar-design-tokens generate` now produces `fastfetch.jsonc` from the template

### Docs
- README: token count 292 → 304, glass → solid for waybar/swaync
- AGENTS.md: updated theme description, token count, generated file count, removed swayosd references
- MAP.md: updated swaync theme description, removed swayosd from startup sequence
