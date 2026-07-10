# Changelog

## [0.1.0] - 2026-07-08

### P0 — Bug fixes & hardening

- **Dual color sources reconciled**: `shayar.json` is now generated from `design-tokens.json` via `shayar-design-tokens generate`. All 50 colors match across all `colors.*` files.
- **Battery polling reduced**: waybar battery module interval 1s → 60s.
- **Dead files removed**: `config-ocr-lang.rasi` (215 lines), `shayar-wallpaper-app`, `shayar-reload-statusbar`, `power.qml` (dead duplicate of PowerWindow.qml).
- **PATH double-set bug fixed**: merged duplicate `hl.env()` calls in `shayar.lua`. Removed duplicate `XDG_SESSION_TYPE`.
- **Hardcoded log path removed**: `~/.config/shayar/` redirect dropped from `shayar-autostart`.
- **Duplicate mouse bindings removed**: lines 47-48 of `keybindings/default.lua`.
- **Hardcoded waybar colors replaced**: `#e4e1ee` → `@on-surface`, `#43474f` → `@outline`, `#ff6c6c` → `@error`.
- **Hardcoded rofi colors replaced**: `rgba()` → `@color / alpha` syntax.
- **Wlogout stale colors fixed**: added `[templates.wlogout]` to matugen config, removed stale `colors.css`.
- **Waybar boot fix**: CSS import path corrected (`../../colors.css` → `../../../colors.css`).
- **link.sh safety**: existing configs backed up before symlink creation (no more silent data loss).
- **Shell hardening**: all 26 scripts now have `set -euo pipefail` or `set -uo pipefail`. All variable expansions quoted. `eval` eliminated from all scripts except one justified case (date expansion in shayar-screenshot).

### P1 — Structural improvements

- **AGENTS.md**: comprehensive AI-assistance guide at repo root.
- **Extension hooks**: `run_extensions()` in `library.sh` with 5 hook points across core scripts + shipped `hypridle-inhibitor` extension.
- **Themed overlay system**: `shayar-apply-theme` reads `themed.lst` manifest and creates symlinks. Theme files moved to `themes/glass/files/`.
- **Layered config**: `config_path()` in both `library.sh` (bash) and `functions.lua` (Hyprland Lua) for user overrides via `~/.config/overrides/`.
- **Unified settings menu**: `shayar-menu` rofi launcher bound to `ALT+SPACE`. Supports extension menu items.
- **Shell alias dedup**: shared `config/shared-shell/` directory saves 72 lines of duplication.
- **CI**: GitHub Actions runs `scripts/test.sh` on push/PR (96 tests).
- **Contributing guide**: `CONTRIBUTING.md` with setup, conventions, and PR process.

### Polish

- Repo: 189 files, ~16K lines. Removed duplicate wallpapers.
