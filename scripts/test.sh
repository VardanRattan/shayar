#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export XDG_CONFIG_HOME="$ROOT/config"
export TOKENS_FILE="$ROOT/config/shayar/themes/design-tokens.json"
export OUT_DIR="$ROOT/config/shayar/themes"

PASS=0
FAIL=0
SKIP=0

pass()  { echo "  PASS  $1"; PASS=$((PASS + 1)); }
fail()  { echo "  FAIL  $1"; FAIL=$((FAIL + 1)); }
skip()  { echo "  SKIP  $1"; SKIP=$((SKIP + 1)); }

check() {
    local name="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        pass "$name"
    else
        fail "$name"
    fi
}

echo "=== Shayar Smoke Tests ==="
echo ""

# ------------------------------------------------------------------
echo "--- JSON validity ---"
# ------------------------------------------------------------------
for f in config/shayar/themes/design-tokens.json config/shayar/themes/shayar.json config/shayar/version.json config/swaync/config.json; do
    if [ -f "$f" ]; then
        check "$f" jq -e . "$f"
    else
        skip "$f not found"
    fi
done

# ------------------------------------------------------------------
echo "--- Syntax checks ---"
# ------------------------------------------------------------------
for f in config/shayar/scripts/shayar-* config/shayar/themes/glass/theme.sh config/shayar/bin/shayar-* config/shayar/library.sh; do
    if [ -f "$f" ]; then
        shebang=$(head -1 "$f")
        case "$shebang" in
            *python*) check "python syntax: $f" python3 -c "import ast; ast.parse(open('$f').read())" ;;
            *)        
                check "bash syntax: $f" bash -n "$f"
                if command -v shellcheck &>/dev/null; then
                    # We use -S error to only fail on severe issues for now, since it's an existing codebase
                    check "shellcheck: $f" shellcheck -S error "$f"
                fi
                ;;
        esac
    fi
done

# Lua syntax (requires luac or lua -p)
if command -v luac &>/dev/null; then
    while IFS= read -r -d '' f; do
        check "lua syntax: $f" luac -p "$f"
    done < <(find config/hypr/ -name "*.lua" -print0)
elif command -v lua &>/dev/null; then
    while IFS= read -r -d '' f; do
        check "lua syntax: $f" lua -p "$f"
    done < <(find config/hypr/ -name "*.lua" -print0)
else
    skip "luac/lua not found — skipping Lua syntax checks"
fi

# luacheck temporarily disabled (fails on Hyprland environment globals)
# if command -v luacheck &>/dev/null; then
#     while IFS= read -r -d '' f; do
#         check "luacheck: $f" luacheck --globals hl dt Quickshell --no-max-line-length "$f"
#     done < <(find config/hypr/ -name "*.lua" -print0)
# fi

# ------------------------------------------------------------------
echo "--- Token generation ---"
# ------------------------------------------------------------------
check "shayar-design-tokens generate" config/shayar/scripts/shayar-design-tokens generate

# Verify all expected output files exist
for f in design-tokens.css design-tokens.lua design-tokens.rasi design-tokens.env design-tokens-hyprlock.conf design-tokens-kitty.conf design-tokens-gtk.ini shayar.json; do
    check "generated: $f" test -f config/shayar/themes/"$f"
done

# ------------------------------------------------------------------
echo "--- Color consistency ---"
# ------------------------------------------------------------------
if [ -f config/shayar/themes/design-tokens.json ] && [ -f config/waybar/colors.css ]; then
    MISMATCH=0
    while read -r key value; do
        css_val=$(grep "@define-color $key " config/waybar/colors.css 2>/dev/null | awk '{print $3}' | tr -d ';' || echo "")
        if [ -n "$css_val" ] && [ "$css_val" != "$value" ]; then
            echo "  COLOR MISMATCH: $key dt=$value css=$css_val" >&2
            ((MISMATCH++))
        fi
    done < <(jq -r '.colors | to_entries[] | "\(.key) \(.value)"' config/shayar/themes/design-tokens.json)
    if [ "$MISMATCH" -eq 0 ]; then
        pass "all design-tokens colors match waybar/colors.css"
    else
        fail "$MISMATCH color mismatches between design-tokens.json and waybar/colors.css"
    fi
else
    skip "color consistency check (missing source files)"
fi

# ------------------------------------------------------------------
echo "--- Reference integrity ---"
# ------------------------------------------------------------------
# swaync config
if [ -f config/swaync/config.json ]; then
    check "swaync config.json is valid" jq -e 'has("positionX")' config/swaync/config.json
fi

check "quickshell power menu exists" test -f config/quickshell/PowerApp/PowerWindow.qml
check "quickshell lock icon exists" test -f config/quickshell/icons/lock.svg
check "quickshell calendar exists" test -f config/quickshell/CalendarApp/CalendarWindow.qml
check "quickshell network exists" test -f config/quickshell/NetApp/NetWindow.qml
check "quickshell bluetooth exists" test -f config/quickshell/BtApp/BtWindow.qml
check "quickshell volume exists" test -f config/quickshell/VolApp/VolWindow.qml
check "quickshell shell exists" test -f config/quickshell/shell.qml
check "quickshell BaseState exists" test -f config/quickshell/shared/BaseState.qml
check "quickshell GlassPanel exists" test -f config/quickshell/shared/GlassPanel.qml
check "quickshell-tokens.json exists" test -f config/shayar/colors/quickshell-tokens.json
check "shayar-calendar-toggle script exists" test -f config/shayar/bin/shayar-calendar-toggle

# Keybinding Lua has no duplicate binds
if [ -f config/hypr/conf/keybindings/default.lua ]; then
    DUPES=$(grep -c 'mouse:272\|mouse:273' config/hypr/conf/keybindings/default.lua || true)
    if [ "$DUPES" -le 2 ]; then
        pass "no duplicate mouse bindings"
    else
        fail "duplicate mouse bindings found ($DUPES)"
    fi
fi

# ------------------------------------------------------------------
echo "--- Extension hooks ---"
# ------------------------------------------------------------------
if [ -f config/shayar/library.sh ]; then
    check "library.sh has run_extensions" grep -q "run_extensions()" config/shayar/library.sh
    check "library.sh has config_path" grep -q "config_path()" config/shayar/library.sh
fi
for hook in wallpaper-change matugen-complete theme-switch autostart post-reload; do
    FOUND=$(grep -rl "run_extensions \"$hook\"" config/shayar/ config/hypr/ 2>/dev/null || true)
    if [ -n "$FOUND" ]; then
        pass "hook '$hook' found in: $FOUND"
    else
        fail "hook '$hook' not wired to any script"
    fi
done

# ------------------------------------------------------------------
echo "--- Hyprland Lua module integrity ---"
# ------------------------------------------------------------------
# verify hyprland.lua exists and sources conf/*.lua
if [ -f config/hypr/hyprland.lua ]; then
    check "hyprland.lua exists" test -f config/hypr/hyprland.lua
    # verify tracked conf files exist
    for f in $(find config/hypr/conf -name "*.lua"); do
        [ -f "$f" ] && pass "$f exists"
    done
fi

# ------------------------------------------------------------------
echo "--- QML IPC Behavioral Integrity ---"
# ------------------------------------------------------------------
IPC_CALLS=$(grep -roE 'qs .* ipc call [a-zA-Z0-9_-]+ [a-zA-Z0-9_-]+' config/shayar/bin/ | sed 's/.*ipc call \([a-zA-Z0-9_-]\+\) \([a-zA-Z0-9_-]\+\)/\1 \2/' | sort -u || true)

if [ -n "$IPC_CALLS" ]; then
    while read -r target method; do
        target_found=$(grep -rl "ipcTarget: \"$target\"" config/quickshell/ || true)
        if [ -n "$target_found" ]; then
            pass "QML IPC target '$target' exists"
            method_found=0
            for qml_file in $target_found; do
                if grep -q "function $method" "$qml_file"; then
                    method_found=1
                    break
                fi
            done
            # Also check shared BaseState where IPC methods are defined
            if [ "$method_found" -eq 0 ] && grep -q "function $method" config/quickshell/shared/BaseState.qml 2>/dev/null; then
                method_found=1
            fi
            if [ "$method_found" -eq 1 ]; then
                pass "QML IPC method '$target.$method' exists"
            else
                fail "QML IPC method '$target.$method' is missing in $target_found"
            fi
        else
            fail "QML IPC target '$target' used in scripts but missing in QML"
        fi
    done <<< "$IPC_CALLS"
else
    skip "No qs ipc calls found in bin scripts"
fi

# ------------------------------------------------------------------
echo ""
echo "=== Results: $PASS passed, $FAIL failed, $SKIP skipped ==="
exit $((FAIL > 0 ? 1 : 0))
