# Changelog

## [0.2.0] - 2026-07-11

### Bug fixes

- Waybar no longer fails to start on boot (`waybar-disabled` flag cleaned on startup)
- Waybar CSS crash: `@DT_*@` tokens in imported CSS files now resolved
- Color token underscore bug fixed (`@tertiary_container` no longer dangles)
- Mutual exclusion: all 5 Quickshell panels close the other 4 on open
- Net/Bt applets capped at 75% screen height
- SwayNC DND toggle activated, dead `buttons-grid` CSS removed
- QML IPC tests fixed (`ipcTarget:` search, shared BaseState methods)

### Features

- QML boilerplate extracted: `BaseState.qml` + `GlassPanel.qml` shared across 5 applets (-341 lines)
- Waybar CSS token pipeline: 28 `@DT_*@` placeholders resolved at launch
- Keyboard navigation for Net, BT, and Vol applets
- Vol scroll wheel (5% steps), Waybar volume scroll via `wpctl`
- Calendar smooth month transitions, toned today pulse
- Power button hover scale, SwayNC notification hover elevation

### Docs

- CHANGELOG, MAP.md, AGENTS.md accuracy fixes
- README keybinds deduplicated, 13 missing entries added
