<p align="center">
  <img src="config/shayar/assets/shayar.svg" alt="Shayar Logo" width="100"/>
</p>

<h1 align="center">Shayar</h1>

<p align="center">
  <em>Shayar (Urdu: شاعر, Punjabi: ਸ਼ਾਇਰ — meaning <strong>poet</strong>)</em>
</p>

A unified Hyprland desktop shell built on one idea: pick a wallpaper, and the entire desktop adapts. Colors, borders, shadows, animations — everything pulls from a single Material You palette generated on the fly. No hardcoded values. No manual theming. Just wallpaper-driven cohesion.

Built on the modular foundation of [ML4W Dotfiles](https://github.com/mylinuxforwork/dotfiles) by Stephan Raabe and powered by the desktop shell architecture of [Caelestia Shell](https://github.com/caelestia-dots/caelestia-shell). GPL-3.0.

---

## What you get

- **Wallpaper-driven theming** — one wallpaper change recolors terminal, bar, launcher, lock screen, notifications, and desktop drawers
- **Single source of truth** — `design-tokens.json` drives every visual value across 7 design sections
- **Caelestia Shell** — integrated Qt6 desktop shell providing dynamic status bar, Bento dashboard (calendar, weather, system metrics), notification center, quick utilities drawer, audio/brightness OSD, and session drawers
- **Bespoke Vector Identity** — custom geometric Quill "V" logo seamlessly integrated into status bar, dashboard, and lock screen
- **Safe Idle Management** — intelligent backlight-based display dimming preventing GPU modeset failures
- **Zero `~/.config` pollution** — everything symlinks directly from this repo

---

## Screenshots

<p align="center">
  <img src="screenshots/desktop.png" alt="Shayar Desktop" width="800"/>
</p>

---

## Install

### Option A: Automated Bootstrap (Recommended)

The automated installer detects your package manager (`paru`, `yay`, `pacman`, `dnf`), installs all system packages and dependencies, installs Geist fonts, configures Oh My Zsh with plugins, links all configs to `~/.config`, and compiles your initial design tokens.

**One-line installation:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/VardanRattan/shayar/main/scripts/install.sh)
```

**Or from a cloned repository:**
```bash
git clone https://github.com/VardanRattan/shayar.git ~/shayar
cd ~/shayar
./scripts/install.sh
```

### Option B: Symlink Only (Dotfiles Sync)

If you have already installed all required system dependencies and only want to link the configurations and CLI utilities to `~/.config` and `~/.local/bin`:

```bash
git clone https://github.com/VardanRattan/shayar.git ~/shayar
cd ~/shayar
./scripts/link.sh
~/.config/shayar/scripts/shayar-design-tokens generate --with-colors
```

> [!IMPORTANT]
> **`link.sh` only creates symlinks** — it does not install packages or dependencies. If you are setting up a new system, run `./scripts/install.sh` instead.

### Post-Install Steps (All Optional)

The desktop works out of the box immediately after running the installer. All post-install steps below are purely optional:

| Action | Command | Details & If Skipped |
|:--|:--|:--|
| **1. Shell (Bash / Zsh)** | `chsh -s /usr/bin/zsh` *(optional)* | **Bash and Zsh are both fully supported out of the box.** If you use Bash, you don't need to change anything — Shayar loads all aliases and paths through `~/.config/bashrc/`. Only run this command if you prefer Zsh with Oh My Zsh. |
| **2. Custom Wallpaper** | `shayar-wallpaper ~/path/to/wallpaper.jpg` | **What you see:** On first login, `shayar-autostart` automatically applies the bundled default wallpaper (`default.png`) and generates matching Material You colors.<br>**What you don't see:** You simply won't see your personal wallpaper until you pick one. |
| **3. SDDM Theme Sync** | `shayar-sddm-sync --install` *(optional)* | **What you see:** If skipped, your boot login screen stays on your system's stock SDDM theme (or upstream Caelestia's astronaut theme).<br>**What you get if run:** Replaces the default astronaut with Shayar's quill emblem and synchronizes your SDDM login screen colors and background with your active desktop wallpaper. *(If you don't use SDDM or use auto-login, ignore this entirely).* |

### Rollback / Uninstall

To remove the symlinks and restore your backed-up configurations:

```bash
./scripts/unlink.sh
```

### Requirements

| Dependency | Role |
|:--|:--|
| Hyprland | Window manager |
| Caelestia Shell (`caelestia-shell`) | Desktop shell (bar, dashboard, drawers, OSD, lock) |
| awww-daemon | Wallpaper setter |
| matugen | Material You color generator |
| quickshell | Qt6 applet & shell runtime |
| fzf, jq, gum | CLI tools & fuzzy navigation |
| fuzzel | Lightweight dynamic application runner |
| grim, slurp, wl-copy | Screenshots & clipboard capture |

### Distro support

| Distro | Status |
|:--|:--|
| Arch (EndeavourOS, Garuda) | Native — automated install (`./scripts/install.sh`) |
| Fedora | Community — manual matugen/quickshell build |
| Ubuntu/Debian | Unsupported (packages too old) |

---

## Architecture

```
wallpaper
  → awww-daemon (sets image)
  → matugen (extracts palette)
  → design-tokens.json (single source of truth)
  → per-component colors.* files + ~/.local/state/caelestia/scheme.json
  → all desktop components pick up new colors
  → Caelestia Shell reloads instantly via FileView
```

> **Note**: For a complete deep-dive into every module and script, see [The Shayar Codex (MAP.md)](MAP.md).

| Path | Component |
|:--|:--|
| `hypr/` | Hyprland — Lua modular config, animations, keybinds, rules |
| `caelestia/` | Caelestia Shell — status bar, Bento dashboard, notification sidebar, utilities drawer |
| `kitty/` | Terminal — matugen colors, truecolor |
| `shayar/` | Core — scripts, CLI tools, design tokens, settings |
| `bashrc/`, `zshrc/` | Shell configs — shared aliases & environment |

---

## Keybinds

| Key | Action | Key | Action |
|:--|:--|:--|:--|
| `SUPER+Return` | Terminal | `SUPER` / `SUPER+CTRL+Return` | App launcher |
| `SUPER+B` | Browser | `SUPER+CTRL+W` | Wallpaper picker |
| `SUPER+E` | File manager | `SUPER+V` | Clipboard history |
| `SUPER+Q` | Kill window | `SUPER+PRINT` | Screenshot |
| `SUPER+F` | Fullscreen | `ALT+SPACE` | Settings menu |
| `SUPER+T` | Float toggle | `SUPER+SHIFT+L` | Lock screen (Caelestia) |
| `SUPER+J` | Split toggle | `SUPER+CTRL+L` | Session / Power drawer |
| `SUPER+1-0` | Workspace | `SUPER+CTRL+N` | Utilities (Network) |
| `SUPER+SHIFT+1-0` | Move to workspace | `SUPER+CTRL+B` | Utilities (Bluetooth) |
| `SUPER+S` | Special workspace | `SUPER+CTRL+D` | Bento Dashboard drawer |
| `SUPER+SHIFT+B` | Toggle status bar | | |

Full list: [default.lua](config/hypr/conf/keybindings/default.lua)

---

## Shell aliases

| Alias | Command |
|:--|:--|
| `apps` | Fuzzy app drawer |
| `wallpaper` | Terminal wallpaper picker |
| `screenshot` | Interactive screenshot tool |
| `quick` | Custom command bookmarks |
| `wifi` | NetworkManager TUI |
| `updates` | System update (pacman + flatpak) |
| `lock` | Lock screen |

---

## Updating

```bash
cd ~/shayar && git pull && ./scripts/link.sh
```

Symlinks mean local edits survive pulls. Git conflicts are the only thing that overwrites your changes.

---

## Credits & Acknowledgments

- **[ML4W Dotfiles](https://github.com/mylinuxforwork/dotfiles)** by Stephan Raabe — The modular Hyprland configuration structure, window rules, and environment foundation.
- **[Caelestia Shell](https://github.com/caelestia-dots/caelestia-shell)** by Caelestia Dots — The desktop shell engine delivering the dynamic status bar, Bento dashboard, notification sidebar, quick utilities drawer, audio/brightness OSD, and session management.
- **[Matugen](https://github.com/InioX/matugen)** by InioX — Material You (Material 3) palette generation from wallpapers.
- **[Quickshell](https://quickshell.outfoxxed.me/)** by Outfoxxed — The high-performance reactive QML desktop shell engine.
- **[Hyprland](https://hyprland.org/)** by Vaxry — The fluid, dynamic Wayland compositor.

---

## License

GPL-3.0 — inherited from [ML4W Dotfiles](https://github.com/mylinuxforwork/dotfiles).
