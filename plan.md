# Plan: Open Work

> Archived items from 2026-07-11 have been removed.

---

## Planned Enhancements

### ⚡ Speed & Performance
| # | Item | Status |
|---|------|--------|
| 1a | **Token Engine Rewrite**: `shayar-design-tokens` currently calls `jq` 12+ times sequentially. Rewriting this in Go/Python (or a single `jq` pass) will drop generation time from ~500ms to <10ms for instant live-reloads. | Done |
| 1b | **Image Processing**: `shayar-wallpaper` uses `magick -blur` which is CPU-heavy on 4K images. Refactoring to scale down *before* blurring (or using `vipsthumbnail`) will drastically speed up wallpaper changes. | Done |

### 💅 Visual Orgasm & UX
| # | Item | Status |
|---|------|--------|
| 2a | **Flicker-Free Waybar**: Refactor `launch.sh` so `killall waybar` is removed. Route all spacing token updates through `pkill -SIGUSR2 waybar` so the CSS hot-reloads seamlessly without the bar blinking out of existence. | Done |
| 2b | **Quickshell Reactive State**: Applets currently fork a `cat` process (`Process {}`) to read JSON tokens on reload. Migrating to a QML Singleton (`ThemeManager.qml`) will make colors reactive instantly without spawning bash subshells. | Done |
| 2c | **Bespoke Animations**: Add a custom `bezier` curve in Hyprland specifically for the `special:magic` workspace so the scratchpad "pops" and fades elegantly rather than a raw slide. | Done |

### 🛠 Maintainability & Open Source Polish
| # | Item | Status |
|---|------|--------|
| 3a | **Safe Rollbacks**: `link.sh` backs up old configs, but there is no `unlink.sh`. Create a rollback script that restores `~/.config` to its exact pre-Shayar state for perfect open-source hygiene. | Done |
| 3b | **Dynamic HiDPI Scaling**: Inject a hook in `autostart.lua` that queries `hyprctl monitors -j`. If scale > 1, auto-export `QT_SCALE_FACTOR` and `GDK_SCALE` to keep Quickshell razor-sharp on 4K monitors. | Done |
| 3c | **SVG Templating**: Add `.template.svg` parsing to the token engine so asset colors aren't hardcoded, achieving 100% single-source-of-truth status. | Pending |
