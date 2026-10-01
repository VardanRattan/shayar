#!/usr/bin/env bash
set -euo pipefail
# release.sh — Automated release pipeline: squashes dev into master with auto co-author attribution

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$REPO_ROOT"

# Resolve version: use argument or read from existing version file
DEFAULT_VER="$(cat "$REPO_ROOT/version" 2>/dev/null || true)"
NEW_VERSION="${1:-$DEFAULT_VER}"
NEW_VERSION="${NEW_VERSION#v}" # Strip leading 'v' if present

if [ -z "$NEW_VERSION" ]; then
    echo "Usage: $0 [version] [summary]"
    echo "Example: $0 1.2.0 \"Touchpad tap-to-click, pavucontrol regex fix, and stability updates\""
    exit 1
fi

SUMMARY="${2:-Release v$NEW_VERSION}"

# 1. Verify working directory is clean
if [ -n "$(git status --porcelain)" ]; then
    echo ":: Error: Working tree has uncommitted changes. Please commit or stash them first." >&2
    exit 1
fi

# 2. Verify we are on dev branch
CURRENT_BRANCH="$(git branch --show-current)"
if [ "$CURRENT_BRANCH" != "dev" ]; then
    echo ":: Switching to dev branch..."
    git checkout dev
fi

# 3. Run test suite before releasing
echo ":: Running test suite..."
bash "$REPO_ROOT/scripts/test.sh"

# 4. Extract all external co-authors between master and dev
USER_EMAIL="$(git config user.email 2>/dev/null || true)"
CO_AUTHORS="$(git log master..dev --format="Co-authored-by: %an <%ae>" | grep -v "$USER_EMAIL" | sort -u || true)"

# 5. Extract commit summaries from dev
COMMIT_LOGS="$(git log master..dev --no-merges --format="- %s (%h)" || true)"

# 6. Switch to master and squash-merge dev
echo ":: Switching to master..."
git checkout master
git pull origin master

echo ":: Squash-merging dev into master..."
git merge --squash dev

# 7. Build the release commit message
RELEASE_MSG="release: v$NEW_VERSION — $SUMMARY"

if [ -n "$COMMIT_LOGS" ]; then
    RELEASE_MSG="$RELEASE_MSG

Changes:
$COMMIT_LOGS"
fi

if [ -n "$CO_AUTHORS" ]; then
    RELEASE_MSG="$RELEASE_MSG

$CO_AUTHORS"
fi

# 8. Commit the squashed release on master
git commit -m "$RELEASE_MSG"

# 9. Create version tag
git tag "v$NEW_VERSION"

# 10. Switch back to dev and sync with master
git checkout dev
git merge master -m "chore: sync dev with master release v$NEW_VERSION"

echo ""
echo "=== Release v$NEW_VERSION ready! ==="
echo "Single release commit created on master with co-author attribution."
echo ""
echo "To publish the release, run:"
echo "  git push origin master dev --tags"
