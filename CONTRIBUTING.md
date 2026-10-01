# Contributing to Shayar

Thank you for your interest in contributing to Shayar! To maintain the high architectural standards of this configuration suite, please follow these guidelines when adding features or fixing bugs.

## 📐 Architecture & Conventions

1. **Single Source of Truth for Visuals:**
   * All visual tokens (colors, margins, borders, radii, fonts, opacities) live in `config/shayar/themes/design-tokens.json`.
   * **Never hardcode visual values** in Hyprland configs, Caelestia Shell styles, Kitty, or SDDM themes.
   * If you edit `design-tokens.json`, regenerate the token files by running:
     ```bash
     shayar-design-tokens generate --with-colors
     ```

2. **Shell Script Hygiene:**
   * All new shell scripts must live in `config/shayar/bin/` or `config/shayar/scripts/`.
   * Scripts should start with `set -euo pipefail` for safety.
   * Quote all shell variable expansions (e.g., `"$VARIABLE"`) to prevent word splitting.
   * Avoid using `eval` to execute commands; use isolated subshells like `bash -c "$cmd"` instead.
   * Standardize temporary directories using `${XDG_RUNTIME_DIR:-/tmp}` instead of raw `/tmp/` paths.
   * Use structured `case` statements instead of sequential `if` blocks for control flows.

3. **Hyprland Modular Config:**
   * Hyprland configurations are modular Lua files under `config/hypr/conf/` and are loaded sequentially in `hyprland.lua`.
   * Do not write massive overrides in `hyprland.lua` directly. Add features to the relevant sub-modules.
   * Wrap any custom config inclusions in a protective `pcall()` block to prevent crashing the window manager on startup.

---

## 🧪 Testing Your Changes

Before submitting your changes, run the local smoke test suite to verify syntax, JSON validity, and token generator integrity:

```bash
bash scripts/test.sh
```

Ensure all tests pass. This suite will run automatically in the GitHub Actions CI on every Pull Request.
