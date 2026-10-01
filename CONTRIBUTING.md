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

## 🌿 Branching Strategy & Pull Requests

Shayar uses a two-tier branch workflow to ensure stability for users pulling live configurations:

- **`master` (Stable Releases):** The primary branch is strictly reserved for production-ready, tagged releases (`vX.Y.Z`). End users clone and pull from `master`.
- **`dev` (Active Development):** All active development, bug fixes, experiments, and community contributions happen on `dev`.

### How to submit a Pull Request:
1. Fork the repository and create your feature or bugfix branch off of **`dev`**:
   ```bash
   git checkout -b my-feature-name origin/dev
   ```
2. Implement your changes following the architectural conventions above.
3. Verify that all smoke tests pass locally:
   ```bash
   bash scripts/test.sh
   ```
4. Open your Pull Request targeting the **`dev`** branch (not `master`).

> [!NOTE]
> **Release Milestones:** When a collection of features and fixes on `dev` is verified and ready for release, `dev` is squashed into `master` as a single milestone release commit with a version bump tag (e.g. `release: v1.2.0`). External contributors are preserved and credited on release commits via `Co-authored-by` git attribution.

---

## 🧪 Testing Your Changes

Before submitting your changes, run the local smoke test suite to verify syntax, JSON validity, and token generator integrity:

```bash
bash scripts/test.sh
```

Ensure all tests pass. This suite will run automatically in the GitHub Actions CI on every Pull Request.
