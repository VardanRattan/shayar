# Changelog

## [0.5.0] - 2026-07-17

### Added
- **CI Workflow**: Added `python` to the GitHub Actions test runner environment dependencies.
- **Python Syntax Verification**: Added automated Python syntax testing to the local test suite.

### Changed
- **SDDM Layout Redesign**: Completely removed the circular avatar image/container to keep the login fields centered on the screen.
- **Clock Positioning**: Moved the clock and date area to the top-left (previously bottom-right) and left-aligned the texts.
- **Design Tokens Scale**: Enlarged the SDDM layout dimensions:
  - Clock text size increased from `48` to `72`.
  - Input fields scaled from `250x40` to `300x48`.
  - Corner radius rounded from `8` to `14`.
  - Layout and inner spacing increased to `24` and `12` respectively.
- **Test Suite Logs**: Refactored `test.sh` to output full failure logs rather than suppressing output on errors.
- **Syntax Check Scope**: Broadened syntax checking in `test.sh` to cover all executable files in `bin/` and `scripts/` instead of just those prefixed with `shayar-*`.

### Fixed
- **SDDM QML Errors**: Resolved `ScrollIndicator is not a type` by prefixing the type and attached property with the `Controls` namespace.
- **SDDM Imports**: Fixed library loading errors by using Qt 6-compatible versionless imports for standard libraries while retaining `SddmComponents 2.0` versioning.
- **Power Buttons Visibility**: Set Sleep, Restart, and Shut Down buttons to `visible: true` to prevent them from being hidden by logind/D-Bus initialization delays or when testing via `--test-mode`.

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
