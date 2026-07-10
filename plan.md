# Plan: Quickshell WiFi & Bluetooth Applets

> Goal: Replace the kitty+TUI wifi/BT popups (`shayar-wifi-popup`, `shayar-bt-popup`)
> with native, glass-themed Quickshell applets that fully manage connections —
> mirroring the existing `PowerApp` / `CalendarApp` pattern.
>
> Status: refined against actual repo code (`PowerWindow.qml`, `CalendarWindow.qml`,
> `default.lua`, `waybar/config`, `shayar-power-toggle`, `shayar-design-tokens`).

---

## 1. Architecture

Two independent applets, each a `PanelWindow` loaded by `shell.qml`, toggled via
`qs -p … ipc call <target> toggle` (same mechanism as the power menu).

| Applet | File | IPC target | Anchor |
|---|---|---|---|
| WiFi | `config/quickshell/NetApp/NetWindow.qml` | `net` | top-right (clear of power's centered panel) |
| Bluetooth | `config/quickshell/BtApp/BtWindow.qml` | `bt` | top-right (mutually exclusive with net) |

**Data source:** Quickshell has no native NM/Bluetooth bindings, so each applet shells out
to `nmcli` / `bluetoothctl` via `Process` + `StdioCollector`, parses in JS into a
`ListModel`, and runs actions through `Quickshell.execDetached(...)`. Both CLI tools are
already intended deps (NetworkManager + bluez). This keeps the whole stack in-repo and themed.

**Mutual exclusion:** all four toggle scripts (power, calendar, net, bt) close the other
three on open, so popups never overlap.

---

## 2. Files to create / modify

### Create
- `config/quickshell/NetApp/NetWindow.qml`
- `config/quickshell/BtApp/BtWindow.qml`
- `config/shayar/bin/shayar-net-toggle`   (derived from `shayar-power-toggle`)
- `config/shayar/bin/shayar-bt-toggle`    (derived from `shayar-power-toggle`)

### Modify
- `config/quickshell/shell.qml` — add 2 `Loader` lines
- `config/hypr/conf/keybindings/default.lua` — insert after line 40 (power menu bind)
- `config/waybar/themes/shayar/config` — `network.on-click` (line 87), `bluetooth.on-click` (line 79)
- `config/shayar/bin/shayar-power-toggle` — also close net/bt
- `config/shayar/bin/shayar-calendar-toggle` — also close net/bt
- `config/shayar/themes/design-tokens.json` — **add a `quickshell` section** (see §6; currently absent, so `quickshell-tokens.json` is `{}` and QML sizing uses hardcoded defaults)
- `MAP.md` / `README.md` — document new keybinds + applets

### Keep (fallback, no longer wired to waybar)
- `config/shayar/bin/shayar-wifi-popup`, `config/shayar/bin/shayar-bt-popup` — TUI popups;
  used as the secure-network password-entry fallback (see §5.4).

---

## 3. Phase 0 — Scaffolding

**3.1 `shell.qml`** — add after the existing two loaders:
```qml
Loader { source: "NetApp/NetWindow.qml" }
Loader { source: "BtApp/BtWindow.qml" }
```

**3.2 Toggle scripts** — create `shayar-net-toggle` / `shayar-bt-toggle` from
`shayar-power-toggle`, swapping the IPC target and closing siblings:
```bash
#!/usr/bin/env bash
set -euo pipefail
QS_SHELL="${HOME}/.config/quickshell/shell.qml"
pgrep -x qs >/dev/null || { qs -p "$QS_SHELL" & sleep 0.5; }
qs -p "$QS_SHELL" ipc call power close
qs -p "$QS_SHELL" ipc call calendar close
qs -p "$QS_SHELL" ipc call net close      # bt-toggle uses "bt close"
qs -p "$QS_SHELL" ipc call net toggle     # bt-toggle uses "bt toggle"
```
Then extend `shayar-power-toggle` and `shayar-calendar-toggle` with the same three
`ipc call … close` lines so opening any popup closes the rest.

**3.3 Keybinds** (`default.lua`, insert after line 40):
```lua
hl.bind(mainMod .. " + CTRL + N", hl.dsp.exec_cmd(HOME .. "/.config/shayar/bin/shayar-net-toggle"),  { description = "Network applet" })
hl.bind(mainMod .. " + CTRL + B", hl.dsp.exec_cmd(HOME .. "/.config/shayar/bin/shayar-bt-toggle"),   { description = "Bluetooth applet" })
```
Verified free: `SUPER+CTRL+N` and `SUPER+CTRL+B` are not bound (only `SUPER+B` browser,
`SUPER+CTRL+E` emoji, `SUPER+CTRL+L` lock/power exist).

**3.4 Waybar** (`config/waybar/themes/shayar/config`):
- line 79: `"on-click": "~/.config/shayar/bin/shayar-bt-toggle"`
- line 87: `"on-click": "~/.config/shayar/bin/shayar-net-toggle"`
(Keep `network.on-click-right` → nm-applet toggle as-is.)

---

## 4. Phase 1 — WiFi applet (`NetWindow.qml`)

### 4.1 Skeleton (copy `PowerWindow.qml`, adjust)
- `PanelWindow` + `WlrLayershell.layer: Overlay` + `exclusionMode: Ignore`
- **Anchor top-right** (distinct from power's vertically-centered panel):
  `anchors.right: true; anchors.top: true; margins { top: 42; right: slideOffset }`
- `HyprlandFocusGrab` (close on outside click) + `Shortcut` Esc to close
- Paste the **entire** `colors` + `tokens` `QtObject` blocks and the two `Process` readers
  (`colorReader`, `tokenReader`) verbatim from `PowerWindow.qml` — guarantees visual parity
  and free recolor on wallpaper change.
- `visible: isOpen || slideAnim.running`; slide from right (same as power).
- `IpcHandler { target: "net"; function toggle/open/close }`.

### 4.2 Data model
```qml
ListModel { id: wifiModel }   // roles: inUse(bool), ssid, signal(int 0-100), secured(bool), bssid
```

### 4.3 Scan command + parsing (the risky part)
```bash
nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY,BSSID device wifi list
```
Sample lines:
```
*:MyHomeNet:72:WPA2:ab:cd:ef:01:02:03
::45::de:ad:be:ef:00:11
```
Note **BSSID contains colons**, so split from the left and rejoin the tail:
```js
function parseWifi(text) {
    wifiModel.clear()
    text.trim().split("\n").forEach(function (line) {
        if (!line) return
        var p = line.split(":")
        var inUse    = p[0] === "*"
        var ssid     = p[1]
        var signal   = parseInt(p[2]) || 0
        var security = p[3]
        var bssid    = p.slice(4).join(":")   // rejoin MAC (has colons)
        wifiModel.append({
            inUse: inUse,
            ssid: ssid || "(hidden)",
            signal: signal,
            secured: security !== "" && security !== "--",
            bssid: bssid
        })
    })
}
```
Wire it: `Process { id: wifiScan; command: ["bash","-c","nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY,BSSID device wifi list"]; stdout: StdioCollector { onStreamFinished: parseWifi(this.text) } }`.

### 4.4 Refresh strategy
- On `isOpenChanged` (open): run `wifiScan` **without** rescan (fast).
- **Rescan** button: `nmcli device wifi rescan` then re-run `wifiScan` (which calls
  `device wifi list --rescan yes` for a fresh sweep).
- `Timer { interval: 3000; running: root.isOpen; onTriggered: wifiScan.running = true }`
  keeps signal/active state live while open.

### 4.5 Actions (all via `Quickshell.execDetached`)
- Connect:    `nmcli device wifi connect "<bssid>"` (use BSSID to disambiguate duplicate SSIDs).
- Disconnect: `nmcli connection down "$(nmcli -t -f GENERAL.CONNECTION device show <iface>)"` (only if `inUse`).
- Radio off/on: `nmcli radio wifi off` / `on`.
- After every action → re-run `wifiScan`.

### 4.6 UI
- Header row: WiFi glyph (see §6 icon note) + "Wi-Fi" + enable/disable toggle + **Rescan** button
  (reuse the `PowerButton` component style for these controls).
- `ListView` of `wifiModel`: each row = circle (signal-tinted) + SSID text + lock glyph if
  `secured` + "Connected" pill if `inUse`. Click row → connect (or disconnect if `inUse`).

---

## 5. Phase 2 — Bluetooth applet (`BtWindow.qml`)

### 5.1 Skeleton — same as §4.1 (target `"bt"`, anchor top-right).

### 5.2 Data model
```qml
ListModel { id: btModel }   // roles: mac, name, paired(bool), connected(bool), trusted(bool)
```

### 5.3 Commands + parsing
- Powered?: `bluetoothctl show | grep -q "Powered: yes"` → boolean.
- List devices: `bluetoothctl devices` → `Device <MAC> <Name>`:
  ```js
  var p = line.split(" "); var mac = p[1]; var name = p.slice(2).join(" ")
  ```
- Per-device state: `bluetoothctl info <MAC>` → parse `Paired: yes` / `Connected: yes`
  / `Trusted: yes`. Run once per device found (lists are small; acceptable cost).
  Build `btModel` from the combined parse.
- Wire: `Process { id: btScan; command: ["bash","-c","bluetoothctl devices; for d in $(bluetoothctl devices | awk '{print $2}'); do bluetoothctl info $d; done"]; … }`
  and parse the interleaved `Device …` / `Paired:` / `Connected:` blocks.

### 5.4 Actions (all via `Quickshell.execDetached`)
- Power: `bluetoothctl power on` / `off`.
- Connect known:    `bluetoothctl connect <MAC>`.
- Pair+trust+connect new:
  `bluetoothctl pair <MAC> && bluetoothctl trust <MAC> && bluetoothctl connect <MAC>`.
- Disconnect: `bluetoothctl disconnect <MAC>`.
- **Scan (bounded!):** `timeout 12 bluetoothctl scan on` triggered only by a **Scan** button;
  re-list on finish. Never leave scan running (battery/CPU).
- After every action → re-run `btScan`.

### 5.5 Secure-network caveat (WiFi)
New secured WiFi needing a password can't be entered through this headless UI
(`nmcli` would block on a prompt). Mitigation: if connect fails,
`notify-send "Shayar" "Could not connect to <ssid> — open Wi-Fi applet (nmtui) from the menu"`
and fall back to the existing `shayar-wifi-popup` (nmtui) which handles password entry.
Document this in the applet tooltip / README.

### 5.6 UI
- Header: BT glyph + "Bluetooth" + power toggle + **Scan** button.
- `ListView` of `btModel`: row = circle (tinted if `connected`) + device name + MAC (muted)
  + state badge (Paired / Connected). Click → connect or disconnect.

---

## 6. Phase 3 — Polish & consistency

- **Icons without new assets:** the `icons/` dir has no wifi/bt SVGs. Reuse the existing
  `MultiEffect` colorization but render the glyph with a `Text` element using the same
  nerd-font codepoints waybar already uses: `` (wifi), `` (bluetooth), lock `󰀢`,
  signal bars as text. Avoids creating SVG files while staying consistent with the bar.
- **Tokenize sizing (closes the `{}` gap):** add a `quickshell` block to
  `design-tokens.json`, e.g.
  ```json
  "quickshell": {
    "panel_width": 320, "panel_radius": 24, "panel_bg_alpha": 0.7,
    "blur_strength": 0.7, "border_alpha": 0.15, "border_width": 1,
    "shadow_alpha": 0.4, "button_spacing": 12, "row_height": 48,
    "label_height": 30, "label_radius": 15, "label_alpha": 0.88,
    "icon_size": 18, "icon_circle_size": 44, "primary_alpha": 0.9,
    "hover_border_alpha": 0.5, "font_size_label": 13, "font_size_small": 11
  }
  ```
  then `shayar-design-tokens generate` regenerates `quickshell-tokens.json` (the existing
  `generate_quickshell_tokens` already reads `.quickshell`). Net/Bt QML should read these
  instead of hardcoded literals where possible, so the whole shell stays token-driven.
- **Theme reload:** inherited `theme-manager` `IpcHandler` already re-reads colors on
  wallpaper change — both new applets reuse the same readers, so they recolor for free.
- **Close-others:** ensure all four toggle scripts emit the three `ipc call … close` lines
  (Phase 0.2) so opening one never stacks another.

---

## 7. Phase 4 — Verification

1. `pkill qs; qs -p ~/.config/quickshell/shell.qml`.
2. `SUPER+CTRL+N` → applet slides in top-right; lists nearby SSIDs w/ signal + lock state.
3. Click a network → connects (verify `nmcli connection show --active`); list refreshes.
4. Rescan button repopulates; radio toggle disables/enables Wi-Fi.
5. `SUPER+CTRL+B` → BT applet; Scan finds devices; pair+connect; verify `connected`.
6. Opening one applet closes the others (no overlap); outside-click / Esc closes.
7. Wallpaper change recolors both.
8. `bash scripts/test.sh` still green (no Lua touched by the applets; CI unaffected).
9. Update `MAP.md` applet section + `README.md` keybind table + note secure-WiFi fallback.

---

## 8. Risks & mitigations

| Risk | Mitigation |
|---|---|
| `nmcli -t` BSSID has colons | Parse 4 left fields, rejoin tail as MAC (§4.3) |
| Duplicate SSIDs | Connect by BSSID, not SSID |
| New secured WiFi needs password | Headless can't prompt → `notify-send` + nmtui fallback (§5.5) |
| Bluetooth scan left running | Always `timeout 12 …` via button only (§5.4) |
| `bluetoothctl info` per device is slow | Lists are small; acceptable; can cache |
| `quickshell-tokens.json` is `{}` | Add `quickshell` block to `design-tokens.json` (§6) |
| Applets overlap power (centered) | Anchor top-right (§4.1) + mutual-exclusion toggles |

---

## 9. Build order

1. Phase 0 scaffolding + wiring → verify toggles open empty top-right panels.
2. Phase 1 WiFi end-to-end → test connect/disconnect/rescan/radio.
3. Phase 2 Bluetooth → test scan/pair/connect/power.
4. Phase 3 polish (icons, tokenize, close-others).
5. Phase 4 verify + docs.

---

## 10. Fix plan: Critical + High issues

**Waybar status:** Battery (`:40`) and clock (`:13`) are already present and tokenized. No changes needed.

### C1 — Dual matugen color sources (Critical)

**Problem:** `shayar-design-tokens generate --with-colors` runs `matugen json shayar.json` (static blue palette), reverting the live dynamic theme. Called by `install.sh:125` and documented in `CONTRIBUTING.md:12`, `AGENTS.md:63`.

**Fix:** Change `run_matugen()` in `shayar-design-tokens:197-208` to use the cached wallpaper instead of the static palette:

```bash
run_matugen() {
    local bin="matugen"
    [ -f "$HOME/.cargo/bin/matugen" ] && bin="$HOME/.cargo/bin/matugen"
    [ -f "$HOME/.local/bin/matugen" ] && bin="$HOME/.local/bin/matugen"
    if ! command -v "$bin" >/dev/null 2>&1; then
        echo "Warning: matugen not found. Skipping color generation."
        return 0
    fi
    local cache_file="$HOME/.cache/shayar/hyprland-dotfiles/current_wallpaper"
    if [ -f "$cache_file" ] && [ -f "$(cat "$cache_file")" ]; then
        echo "Running matugen from cached wallpaper..."
        "$bin" image "$(cat "$cache_file")"
    else
        echo "Running matugen from static palette (no cached wallpaper)..."
        "$bin" json "$HOME/.config/shayar/themes/shayar.json"
    fi
    echo "Matugen complete"
}
```

**Files:** `config/shayar/scripts/shayar-design-tokens:197-208`

### C2 — Dangling matugen template (Critical)

**Problem:** `config/matugen/config.toml:42-44` defines `[templates.sequences]` → `~/.config/matugen/templates/sequences` but the input file doesn't exist. Matugen errors on every wallpaper change.

**Fix:** Remove the `[templates.sequences]` block (lines 42-44). Also remove `[templates.pywalfox]` (lines 33-36) — its `post_hook` sed is a dead no-op (`/home/USER` never appears in output).

**Files:** `config/matugen/config.toml:33-44`

### H1 — BtWindow wrong icon (High)

**Problem:** `BtWindow.qml:258,282,368` uses `\uF1EB` (WiFi symbol) for Bluetooth.

**Fix:** Replace `\uF1EB` with `\uF1AD` (Bluetooth nerd font symbol) in all 3 locations.

**Files:** `config/quickshell/BtApp/BtWindow.qml:258,282,368`

### H2 — README wrong keybind (High)

**Problem:** `README.md:98` claims `SUPER+SHIFT+W` = random wallpaper. Only `SUPER+CTRL+W` exists.

**Fix:** Change `SUPER + SHIFT + W` to `SUPER + CTRL + W` on line 98.

**Files:** `README.md:98`

### H3 — Stale wlogout references (High)

**Problem:** 3 files reference removed `wlogout` component.

**Fix:**
1. `scripts/install.sh:52` — remove `wlogout` from package list
2. `scripts/test.sh:116` — remove the `test -f config/wlogout/layout` check
3. `AGENTS.md:35` — remove `config/wlogout/` from key paths table

**Files:** `scripts/install.sh:52`, `scripts/test.sh:116`, `AGENTS.md:35`

### Execution order

1. C2 (matugen config) — removes errors on every wallpaper change
1. C1 (design-tokens run_matugen) — fixes the color revert bug
2. H1 (BtWindow icon) — visual correctness
3. H2 (README keybind) — doc accuracy
4. H3 (wlogout refs) — 3 files, trivial cleanup
5. Run `bash scripts/test.sh` to verify

### Verification

1. `bash scripts/test.sh` — should pass (wlogout test removed)
2. Grep for `wlogout` — should return 0 hits
3. Grep for `matugen json` in shayar-design-tokens — should show the cached-wallpaper fallback, not the static path as primary
4. Grep for `\uF1EB` in BtWindow.qml — should return 0 hits
5. Grep for `SHIFT + W` in README.md — should return 0 hits

---

## 11. Re-audit (post-implementation)

**Overall score: 7.5/10** — up from 8.5/10 pre-audit (the new applets introduced some issues).

### Pass scores

| Pass | Area | Score | Key finding |
|------|------|-------|-------------|
| 1 | Architecture & tokens | 7/10 | Token pipeline solid; hardcoded values in new QML and rofi-popup |
| 2 | Script quality | 8/10 | TOCTOU in toggle scripts; 7 scripts missing `-e` flag |
| 3 | Dead code | 7/10 | 5 dead files; BT header uses WiFi icon; QML boilerplate duplication |
| 4 | Documentation | 5/10 | 14 inaccuracies; wrong keybind in README; stale wlogout refs |

### Issues found (21 total)

#### P0 — Must fix

| # | File:Line | Issue |
|---|-----------|-------|
| 1 | `BtWindow.qml:258,282,368` | **Wrong icon**: uses `\uF1EB` (WiFi) for Bluetooth header/toggle/rows. Should be `\uF1EB` → `\uF1AD` (Bluetooth symbol) |
| 2 | `README.md:98` | **Wrong keybind**: claims `SUPER+SHIFT+W` = random wallpaper, but only `SUPER+CTRL+W` exists |

#### P1 — Should fix

| # | File:Line | Issue |
|---|-----------|-------|
| 3 | `scripts/install.sh:52` | Stale `wlogout` in package list (directory removed) |
| 4 | `scripts/test.sh:116` | Stale test: `test -f config/wlogout/layout` always fails |
| 5 | `AGENTS.md:35` | Stale doc: lists `config/wlogout/` path (removed) |
| 6 | `MAP.md` / `AGENTS.md` | Stale doc: references `shayar-toggle-allfloat` (removed) |
| 7 | `NetWindow.qml:52`, `BtWindow.qml:52` | Hardcoded `top: 42` margin (should use `tokens.calendar_margin_top`) |
| 8 | 4 toggle scripts | TOCTOU: `pgrep` → `sleep 0.5` → IPC — no retry if qs slow to start |
| 9 | `rofi/config-popup.rasi:50,81,91,127,148,153,159` | Hardcoded `width: 22em`, `padding: 1em`, `border-radius` (not tokenized) |
| 10 | `config/rofi/config-screenshot.rasi` | Orphaned file — no keybind or script loads it |

#### P2 — Nice to fix

| # | File | Issue |
|---|------|-------|
| 11 | `bin/shayar-command-exists` | Dead script — never referenced anywhere |
| 12 | `hypr/scripts/toggle-animations.sh` | Dead script — no keybind or reference |
| 13 | `bin/shayar-apply-theme` | Duplicate of `scripts/shayar-apply-theme` (only scripts/ copy is used) |
| 14 | 7 scripts (`shayar-autostart`, `shayar-cliphist`, etc.) | Missing `-e` in strict mode (use `set -uo pipefail` instead of `set -euo pipefail`) |
| 15 | All 4 QML applets | ~320 lines of duplicated color/token/Process/IPC boilerplate — could be a shared component |
| 16 | `NetWindow.qml` / `BtWindow.qml` | Missing keyboard navigation (PowerWindow has arrow keys + selectedIndex) |
| 17 | `NetWindow.qml` / `BtWindow.qml` | Hardcoded `32x32` toggle buttons, `font.pixelSize: 14`, `opacity: 0.1` divider |
| 18 | `AGENTS.md` | Wrong counts: "16 scripts" (actual 14), "10 CLI tools" (actual 14), "96 tests" (actual 105) |
| 19 | `CHANGELOG.md` | Missing entries for NetApp/BtApp additions |
| 20 | `README.md` | Missing 8 keybinds (SHIFT+B, CTRL+E, CTRL+C, F, J, ALT+SPACE, CTRL+K) |
| 21 | `test.sh` | No QML syntax checks; no test for shell.qml loading all 4 applets |

### What's working well

- **Token pipeline**: `design-tokens.json` → 11 generated files, drift detection via `verify` command
- **Color pipeline**: `shayar.json` → matugen → all component colors — complete chain
- **IPC toggle consistency**: all 4 scripts identical structure, proper sibling closing
- **QML structural parity**: all 4 applets use identical colorReader/tokenReader/theme-manager pattern
- **Shell hygiene**: 26/26 scripts have `set -u` + `pipefail`; no quoting bugs; no secrets
- **Hyprland config load order**: matches documented 18-step sequence exactly
- **Waybar on-click handlers**: all point to valid scripts
- **No TODO/FIXME markers**: codebase is clean of stale task markers
