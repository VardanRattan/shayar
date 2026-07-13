# Changelog

## [0.2.2] - 2026-07-12

### Glass effect overhaul
- 4-stop gradient (smoother fall-off: 0.0 → 0.4 → 0.7 → 1.0)
- 20 new quickshell tokens (38 → 58): `shadow_blur`, `blur_saturation`, `gradient_lower_alpha`, per-app radii (`net_panel_radius`, `bt_panel_radius`, `vol_panel_radius`), list spacing (`list_inner_margin`, `list_row_margin`, `list_row_spacing`, `list_column_spacing`, `header_spacing`), `toggle_button_size`, `list_icon_size`, alphas (`separator_alpha`, `row_hover_alpha`, `row_selected_alpha`, `row_connected_alpha`, `row_border_alpha`, `icon_circle_alpha`, `badge_alpha`, `badge_paired_alpha`, `badge_border_alpha`)
- Border alpha 0.15 → 0.2 for better visibility
- Calendar "Wk" text opacity 0.5 → 0.7 (readability fix)
- Calendar day cells gain hover state (primary @ 0.08)

### Icon-relative panel positioning
- New `shayar-panel-pos` helper calculates icon centers from Waybar CSS + screen resolution
- All 5 toggle scripts pass icon coordinates via IPC args
- Panels appear directly under their Waybar trigger icons
- Power menu centers on right edge of screen

### Docs
- CHANGELOG stripped to current version only
- MAP.md: removed stale BaseState/GlassPanel references, documented `shayar-panel-pos`
- AGENTS.md: updated token counts and toggle script section
