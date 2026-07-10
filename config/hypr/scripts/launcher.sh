#!/usr/bin/env bash
set -euo pipefail

pkill rofi || rofi -show drun -replace -i
