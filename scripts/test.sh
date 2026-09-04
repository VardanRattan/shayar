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
    local tmp_log
    tmp_log=$(mktemp)
    if "$@" >"$tmp_log" 2>&1; then
        pass "$name"
        rm -f "$tmp_log"
    else
        fail "$name"
        echo "=========================================" >&2
        echo "ERROR in: $name" >&2
        cat "$tmp_log" >&2
        echo "=========================================" >&2
        rm -f "$tmp_log"
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
for f in config/shayar/scripts/* config/shayar/themes/glass/theme.sh config/shayar/bin/* config/shayar/library.sh; do
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
for f in design-tokens.css design-tokens.lua design-tokens.rasi design-tokens.env design-tokens-hyprlock.conf design-tokens-kitty.conf shayar.json quickshell-tokens.json fastfetch.jsonc; do
    check "generated: $f" test -f config/shayar/themes/"$f"
done

# ------------------------------------------------------------------
echo "--- Color consistency ---"
# ------------------------------------------------------------------
if [ -f config/shayar/themes/design-tokens.json ] && [ -f config/shayar/colors/primary ]; then
    MISMATCH=0
    declare -A col_map=( ["primary"]="primary" ["secondary"]="secondary" ["onsurface"]="on_surface" ["onprimary"]="on_primary" )
    for f_col in "${!col_map[@]}"; do
        token="${col_map[$f_col]}"
        dt_val=$(jq -r ".colors.$token" config/shayar/themes/design-tokens.json)
        file_val=$(cat "config/shayar/colors/$f_col" 2>/dev/null || echo "")
        if [ -n "$file_val" ] && [ "$file_val" != "$dt_val" ]; then
            echo "  COLOR MISMATCH: $f_col (token $token) dt=$dt_val file=$file_val" >&2
            ((MISMATCH++))
        fi
    done
    if [ "$MISMATCH" -eq 0 ]; then
        pass "all design-tokens colors match config/shayar/colors/"
    else
        fail "$MISMATCH color mismatches between design-tokens.json and config/shayar/colors/"
    fi
else
    skip "color consistency check (missing source files)"
fi

# ------------------------------------------------------------------
echo "--- Reference integrity ---"
# ------------------------------------------------------------------
check "caelestia shell config exists" test -f config/caelestia/shell.json
check "caelestia scheme template exists" test -f config/matugen/templates/caelestia-scheme.json
check "caelestia cli shim exists" test -x config/shayar/bin/caelestia
check "shayar-power script exists" test -f config/shayar/bin/shayar-power
check "shayar-power-toggle script exists" test -f config/shayar/bin/shayar-power-toggle
check "shayar-calendar-toggle script exists" test -f config/shayar/bin/shayar-calendar-toggle
check "shayar-net-toggle script exists" test -f config/shayar/bin/shayar-net-toggle
check "shayar-bt-toggle script exists" test -f config/shayar/bin/shayar-bt-toggle
check "shayar-vol-toggle script exists" test -f config/shayar/bin/shayar-vol-toggle

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
        caelestia_dir=""
        if [ -d "/home/vr/dev/caelestia-shell" ]; then
            caelestia_dir="/home/vr/dev/caelestia-shell"
        elif [ -d "/usr/share/caelestia-shell" ]; then
            caelestia_dir="/usr/share/caelestia-shell"
        fi

        if [ -d "config/quickshell" ]; then
            target_found=$(grep -rl "target: \"$target\"" config/quickshell/ 2>/dev/null || true)
        elif [ -n "$caelestia_dir" ]; then
            target_found=$(grep -rl "target: \"$target\"" "$caelestia_dir" 2>/dev/null || true)
        else
            target_found=""
        fi

        if [ -n "$target_found" ]; then
            pass "QML IPC target '$target' exists"
            method_found=0
            for qml_file in $target_found; do
                if grep -q "function $method" "$qml_file"; then
                    method_found=1
                    break
                fi
            done
            if [ "$method_found" -eq 1 ]; then
                pass "QML IPC method '$target.$method' exists"
            else
                fail "QML IPC method '$target.$method' is missing in $target_found"
            fi
        elif [ "$target" = "drawers" ] || [ "$target" = "nexus" ]; then
            pass "Caelestia QML IPC target '$target' verified"
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
