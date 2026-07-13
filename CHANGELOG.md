# Changelog

## [0.2.3] - 2026-07-13

### Solid backgrounds
- Converted all 5 Quickshell applets from glass (blur + gradient) to solid background
- Removed `MultiEffect` blur layer and 4-stop gradient overlay from Power, Calendar, Net, BT, Vol
- `panel_bg_alpha` 0.7 → 0.95 (near-opaque solid)
- Border and shadow retained
- Shadow now fades out on panel close (200ms animation) instead of lingering
- Power menu pill background and border also fade on close

### SDDM sync
- New `shayar-sddm-sync` script — syncs wallpaper and matugen colors to SDDM login screen
- `--install` flag installs the Shayar SDDM theme
- Generates `theme.conf.user` with full MD3 palette from `shayar.json`

### Welcome screen
- New `WelcomeApp/WelcomeWindow.qml` — first-boot welcome screen with keybindings + quick launch
- Solid background, centered on screen, matugen colors
- Centered Shayar logo (80x80) at top
- Auto-shows on first boot (flag file `~/.config/shayar/.welcomed`)
- Reopen anytime via `shayar-welcome` command or `SUPER+CTRL+H`
- IPC target: `welcome`
- 2 new tokens: `welcome_panel_width` (420), `welcome_panel_radius` (24)

### Docs
- CHANGELOG stripped to current version only
- MAP.md updated: glass → solid, new applets (welcome), new scripts (sddm-sync, welcome-toggle)
- AGENTS.md updated: token counts, bin/ list, toggle scripts, keybinds
