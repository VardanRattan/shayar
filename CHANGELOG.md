# Changelog

## [1.1.0] - 2026-10-01

### Added
- **SDDM Caelestia Theme Branding Patch**:
  - Introduced `shayar-sddm-patch-branding.sh` to install Shayar Quill emblem and QML branding overrides (`CaelestiaFetch.qml`, `Logo.qml`, `shayar.svg`) into `/usr/share/sddm/themes/caelestia`.
  - Added native dual SDDM theme detection supporting both `shayar` and `caelestia` greeters in `shayar-wallpaper`.
- **Runtime Quickshell & Qt ABI Safety Guard**:
  - Added automated sanity validation to `caelestia` CLI shim to detect broken Quickshell binaries following system Qt ABI updates, triggering critical GUI desktop notifications with immediate recovery instructions (`yay -S --rebuild quickshell-git`).
- **RAM Disk Preloading for QML**:
  - Expanded `shayar-preload` to pre-warm `~/.cache/qmlcache/**/*` into physical Linux page cache for faster QML interface initialization.
  - Configured `QML_DISK_CACHE_PATH` in `shayar.lua` to centralize QML bytecode caching.

### Performance
- **In-RAM Single-Pass Python/PIL Wallpaper Engine**:
  - Implemented fast in-memory Python PIL blur generation in `shayar-wallpaper`, cutting blur and square thumbnail generation times from ~3.5s down to ~1.2s with automatic ImageMagick fallback.
- **Optimized Shell Spawn Latency**:
  - Cached `fzf --zsh` shell integration in `~/.cache/shayar/fzf.zsh` in `config/zshrc/20-customization`, removing subshell invocation on every new terminal instance.
  - Eliminated redundant `fast-syntax-highlighting` plugin from zsh configuration.
- **D-Bus & Sysfs Optimization**:
  - Streamlined `gtk.sh` with a single while-read loop and `set_gsetting` condition to avoid redundant D-Bus gsettings roundtrips when configuration is unchanged.
  - Modernized `shayar-scale-sync` to compute monitor scale factor and HiDPI boolean in a single `jq` expression, eliminating external runtime dependency on `bc`.
  - Refactored `shayar-vol-scroll` to use direct `wpctl` relative volume syntax (`0.05+` / `0.05-`), removing awk subprocess pipes.
  - Battery listener (`low-bat-notification.sh`) now exits early when Caelestia Shell's native UPower monitor is running.

### Fixed
- **CLI Search & Finder Robustness**:
  - Fixed handling of special characters and spaces in `shayar-apps` via null-delimited finding (`find -print0 | xargs -0 -r`).
  - Added folder pruning (`.git`, `node_modules`, `.cache`) in `shayar-finder` for instantaneous directory navigation.
- **Wallpaper Fallback Resolution**:
  - Ensured `shayar-autostart` and `shayar-wallpaper` always resolve valid absolute realpaths for `CACHE_FILE` and Caelestia's `wallpaper/path.txt`, preventing broken paths on fallback triggers.
- **Extension Hook Isolation**:
  - Wrapped extension execution in subshells in `library.sh` to prevent extension failure from interrupting dotfiles scripts.
- **Test Suite Modernization**:
  - Updated `scripts/test.sh` smoke test suite to validate `caelestia/shell.json` and resolved bash arithmetic evaluation warning.

### Changed
- Refreshed default wallpaper assets (`default.png`, `default-1376x768.png`), updated preview screenshot (`desktop.png`), and regenerated Material You palette tokens across all desktop components.
- Updated documentation in `AGENTS.md`, `MAP.md`, and `overrides.md` to reflect new startup sequence, Nexus keybind (`SUPER+I`), and utility tools.
