# Layered config (overrides)

Shayar supports user customization **without editing tracked repo files**, so a
`git pull` never produces a merge conflict on the things you actually tweak.

## How it works

The code reads a user override from `~/.config/overrides/<path>` *before* the
shipped file. If the override exists it wins; otherwise the shipped file is
used. This is implemented in code (not via filesystem symlinks) because
`scripts/link.sh` symlinks whole top-level config dirs into `~/.config`, so a
naive symlink-override would write *into the repo*.

### Files that support overrides

| File | Where the override is read |
|---|---|
| `hypr/conf/keybindings/default.lua` | `config/hypr/functions.lua` `load_variant` (covers all `conf/*/default.lua` variant subfiles: windows, layouts, monitors, decorations, animations, workspaces) |
| `waybar/themes/shayar/config` | `config/waybar/launch.sh` via `config_path` |

Any file under `~/.config/overrides/hypr/conf/<name>/<file>.lua` is picked up
automatically on the next Hyprland reload.

### Scaffolding

```bash
shayar-init-overrides   # copies current shipped files into ~/.config/overrides/
```

Then edit the copies under `~/.config/overrides/`. They take effect on the next
reload (Hyprland: `hyprctl reload`; Waybar: toggle or restart).

## Out of scope (fixed-path tools)

`swaync` (reads a fixed `~/.config/swaync/config.json`) and `kitty`
(`include`s a fixed `custom.conf`) cannot be redirected through `config_path`
without restructuring `link.sh`. For those, edit the shipped files directly, or
add a boot-time copy step later if desired. The single settings file
`shayar.conf` is intentionally the direct edit point (it is the one file
designed to be user-owned).
