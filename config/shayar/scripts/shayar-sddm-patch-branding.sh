#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERRIDES_DIR="$(cd "$SCRIPT_DIR/../../caelestia/overrides/sddm" && pwd)"
SDDM_CAELESTIA_DIR="/usr/share/sddm/themes/caelestia"

if [ ! -d "$SDDM_CAELESTIA_DIR" ]; then
    echo ":: SDDM theme not found at $SDDM_CAELESTIA_DIR" >&2
    exit 1
fi

echo ":: Installing Shayar logo and branding to SDDM Caelestia theme..."
sudo cp -b "$OVERRIDES_DIR/Logo.qml" "$SDDM_CAELESTIA_DIR/components/Logo.qml"
sudo cp -b "$OVERRIDES_DIR/CaelestiaFetch.qml" "$SDDM_CAELESTIA_DIR/widgets/CaelestiaFetch.qml"
sudo cp "$OVERRIDES_DIR/shayar.svg" "$SDDM_CAELESTIA_DIR/assets/shayar.svg"
echo ":: Done! Shayar emblem is now active on the SDDM login screen."
