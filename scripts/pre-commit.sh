#!/usr/bin/env bash
# Shayar pre-commit hook: ensure generated token files stay in sync with
# design-tokens.json. Install via `scripts/link.sh` or:
#   ln -s "$(git rev-parse --show-toplevel)/scripts/pre-commit.sh" .git/hooks/pre-commit
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
TOKENS_FILE="$ROOT/config/shayar/themes/design-tokens.json" \
OUT_DIR="$ROOT/config/shayar/themes" \
bash "$ROOT/config/shayar/scripts/shayar-design-tokens" verify || {
    echo "commit blocked: design-tokens drifted — run: shayar-design-tokens generate"
    exit 1
}
