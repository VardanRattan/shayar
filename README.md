# Shayar Dotfiles

> **Shayar** (Urdu: شاعر, meaning *poet*). A desktop shouldn't just be a collection of configs fighting for screen space—it should tell a cohesive story. 

Shayar is built on the philosophy that theming should be completely hands-off. You pick a wallpaper, and the entire system instantly adapts its colors to match. Your terminal, status bar, launcher, lock screen, notifications, and shells all pull from a single, unified palette generated on the fly. 

Nothing lives in your actual `~/.config` folder. Everything is symlinked directly from this repository. This means your configuration is version-controlled, portable, clean, and impossible to break.

Built on the rock-solid modular foundation of the [ML4W Dotfiles](https://github.com/mylinuxforwork/dotfiles) by Stephan Raabe. Shayar inherits the GPL-3.0 license and the core plumbing that makes Hyprland feel like home. If you enjoy this setup, please drop a star on Stephan's repository!

---

## Screenshots
<p align="center">
  <img src="screenshots/desktop.png" alt="Shayar Desktop" width="800"/>
  <br>
  <em>Default wallpaper. A full desktop screenshot (pill bar, rofi, notifications, lockscreen) coming soon.</em>
</p>

---

## Prerequisites & Distro Support

Shayar requires a rolling-release distribution to satisfy Hyprland's bleeding-edge Wayland dependencies. 

| Distribution | Support Level | Notes |
| :--- | :--- | :--- |
| **Arch Linux (EndeavourOS, Garuda)** | 🟢 Tier 1 (Native) | Fully automated install via provided install.sh script. |
| **Fedora** | 🟡 Tier 2 (Community) | Partially automated. Requires manual compilation of `matugen`, `quickshell`, and `awww-daemon`. |
| **Ubuntu / Debian** | 🔴 Unsupported | Packages in `apt` are too old to run modern Hyprland without crashing. |
| **NixOS** | 🔴 Unsupported | Requires flakes (community PRs welcome). |

Before you kick off the installation, make sure you have:
*   **Hyprland** installed and running.
*   The essentials: `git`, `fzf`, `grim`, `slurp`, `wl-copy`, `jq`, and `gum`.
*   **Awww daemon** (for handling wallpaper states).
*   **Matugen** (the engine driving our Material You palette generation).

---

## Getting Started

Clone the repository to your home folder and let the linking script handle the rest:

```bash
git clone https://github.com/VardanRattan/shayar.git ~/shayar
cd ~/shayar
./scripts/link.sh
```

> [!IMPORTANT]
> **Do not copy files manually.** The entire architecture relies on symlinks. When you pull changes or edit a file, the changes are tracked in git and apply to your desktop instantly.

---

## System Architecture

The link script creates symlinks from this repository directly into `~/.config/`. Here is the breakdown:

| Path | Component | Role |
| :--- | :--- | :--- |
| `hypr/` | **Hyprland** | Window manager, custom animations, keybinds, and window rules. |
| `waybar/` | **Waybar** | Minimal status bar with glass theme. |
| `rofi/` | **Rofi** | Fuzzy app launcher, clipboard tracker, and custom selector menus. |
| `swaync/` | **SwayNC** | Clean notification tray with quick-access hardware toggles. |
| `kitty/` | **Kitty** | Truecolor GPU-accelerated terminal emulator. |
| `shayar/` | **Core Scripts** | Back-end scripts, Matugen hooks, and listener processes. |
| `bashrc/`, `zshrc/` | **Shells** | Modular configs sharing aliases, variables, and path optimizations. |
| `quickshell/` | **Quickshell** | Native glass applets: power menu, calendar, WiFi, Bluetooth. |

---

## The Dynamic Theming Pipeline

When you pick a wallpaper:
1. **Apply**: `shayar-wallpaper` sets the image via `awww-daemon`.
2. **Generate**: `Matugen` extracts the dominant colors and builds a comprehensive Material Design 3 palette.
3. **Propagate**: Matugen injects these color values across all components (`kitty`, `waybar`, `rofi`, window borders, GTK themes).
4. **Reload**: Affected UI bars and notification daemons reload instantly in the background without interrupting your workflow.

You can manually trigger a theme refresh by triggering a reload.

---

## Daily Driver Bindings

The `SUPER` key (Windows key) is your main interface modifier. Here are the core bindings to keep in memory:

*   `SUPER + Return` — Open Terminal
*   `SUPER + B` — Launch Web Browser
*   `SUPER + E` — Open File Manager
*   `SUPER + Q` — Close Active Window
*   `SUPER + T` — Toggle Window Floating
*   `SUPER + 1` through `0` — Switch Workspaces
*   `SUPER + SHIFT + 1` through `0` — Send Window to Workspace
*   `SUPER + CTRL + Return` — Open Rofi App Launcher
*   `SUPER + CTRL + W` — Open Wallpaper Picker
*   `SUPER + CTRL + W` — Set a Random Wallpaper
*   `SUPER + V` — Open Clipboard History
*   `SUPER + CTRL + L` — Power Menu
*   `SUPER + CTRL + N` — Network Applet
*   `SUPER + CTRL + B` — Bluetooth Applet
*   `SUPER + PRINT` — Grab Screenshot (area/window selection)

*For the complete list, check [default.lua](config/hypr/conf/keybindings/default.lua).*

---

## Shell Shortcuts

We share a common pool of productivity aliases:

*   `apps` — Launches the fuzzy app drawer.
*   `wallpaper` — Opens the terminal wallpaper selector.
*   `screenshot` — Triggers the interactive snapshot tool.
*   `quick` — Displays custom command bookmarks (`~/.quicklinks`).
*   `wifi` — Runs a terminal NetworkManager wizard (`nmtui`).
*   `updates` — Fetches and installs system updates (flatpaks, system packages, AUR).

---

## Modifying & Updating

To pull down the latest features and keep your workspace synced:

```bash
cd ~/shayar
git pull
./scripts/link.sh
```

Because everything uses active symlinks, your local changes are never overwritten unless there's a git conflict, and system updates register the moment they are pulled down.
