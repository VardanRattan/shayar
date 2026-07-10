#!/usr/bin/env bash
set -euo pipefail

# Shayar Bootstrap — one-command machine initialization
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/VardanRattan/shayar/main/scripts/install.sh)

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# ---- helpers ----
info()  { echo -e "\033[0;32m[INFO]\033[0m $1"; }
warn()  { echo -e "\033[1;33m[WARN]\033[0m $1"; }
error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }

has_cmd() { command -v "$1" &>/dev/null; }

detect_pm() {
    if has_cmd pacman; then
        if has_cmd paru; then
            echo "paru"
        elif has_cmd yay; then
            echo "yay"
        else
            echo "pacman"
        fi
    elif has_cmd dnf; then
        echo "dnf"
    else
        echo ""
    fi
}

install_pkg() {
    local pm="$1"
    shift
    case "$pm" in
        paru)  paru -S --needed --noconfirm "$@" ;;
        yay)   yay -S --needed --noconfirm "$@" ;;
        pacman) sudo pacman -S --needed --noconfirm "$@" ;;
        dnf)   sudo dnf install -y "$@" ;;
    esac
}

# ---- phase 1: system packages ----
phase1_packages() {
    local pm="$1"
    info "Installing system packages via $pm..."

    local official=(
        brightnessctl eza fastfetch fzf grim hypridle hyprland hyprlock imagemagick jq
        kitty lua playerctl rofi slurp swaync waybar zsh
        wl-clipboard yad flatpak
    )

    case "$pm" in
        paru|yay|pacman)
            local arch_pkgs=(
                "${official[@]}"
                network-manager-applet ttf-jetbrains-mono-nerd ttf-fira-sans otf-font-awesome
            )
            install_pkg "$pm" "${arch_pkgs[@]}"
            # AUR / arch-specific
            install_pkg "$pm" tty-clock ttf-rubik bibata-cursor-theme awww matugen swayosd-git quickshell-git kora-icon-theme tela-circle-dracula-icon-theme bluetuith-bin 2>/dev/null || \
                warn "Some AUR packages failed. Install manually."
            ;;
        dnf)
            local dnf_pkgs=(
                "${official[@]}"
                network-manager-applet jetbrains-mono-fonts fira-code-fonts fontawesome-fonts
            )
            install_pkg "$pm" "${dnf_pkgs[@]}"
            warn "Some deps (awww, matugen, swayosd, quickshell) may not be in dnf. Install manually."
            ;;
    esac

    # matugen fallback via cargo
    if ! has_cmd matugen; then
        if has_cmd cargo; then
            info "Installing matugen via cargo..."
            cargo install matugen
        else
            warn "cargo not found. Install Rust first: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        fi
    fi
}

# ---- phase 2: oh-my-zsh & plugins ----
phase2_shell() {
    info "Setting up shell..."

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        info "Oh My Zsh already installed"
    fi

    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    local plugins_dir="$ZSH_CUSTOM/plugins"

    mkdir -p "$plugins_dir"

    if [ ! -d "$plugins_dir/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$plugins_dir/zsh-autosuggestions"
    fi
    if [ ! -d "$plugins_dir/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$plugins_dir/zsh-syntax-highlighting"
    fi
    if [ ! -d "$plugins_dir/fast-syntax-highlighting" ]; then
        git clone https://github.com/zdharma-continuum/fast-syntax-highlighting "$plugins_dir/fast-syntax-highlighting"
    fi

    info "Shell plugins installed"
}

# ---- phase 3: link config ----
phase3_link() {
    info "Linking config files..."
    bash "$REPO_DIR/scripts/link.sh"
}

# ---- phase 4: generate tokens ----
phase4_generate() {
    info "Generating design tokens..."
    bash "$CONFIG_HOME/shayar/scripts/shayar-design-tokens" generate --with-colors
}

# ---- phase 5: zshrc ----
phase5_zshrc() {
    info "Writing .zshrc..."
    if [ -f "$HOME/.zshrc" ] && ! grep -q "Load modular Shayar config" "$HOME/.zshrc"; then
        local backup="$HOME/.zshrc.bak.$(date +%Y%m%d_%H%M%S)"
        info "Backing up existing .zshrc to $backup"
        cp "$HOME/.zshrc" "$backup"
    fi
    cat > "$HOME/.zshrc" << 'ZSHEOF'
# Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Load modular Shayar config from repo
for f in ~/.config/zshrc/*; do
    if [ ! -d "$f" ]; then
        c="${f/.config\/zshrc\//.config\/zshrc\/custom/}"
        [ -f "$c" ] && source "$c" || source "$f"
    fi
done

# Load single customization file (if exists)
[ -f ~/.zshrc_custom ] && source ~/.zshrc_custom
ZSHEOF
    info ".zshrc written"
}

# ---- summary ----
print_summary() {
    echo ""
    info "=== Bootstrap complete ==="
    echo ""
    echo "  What was done:"
    echo "  - System packages installed"
    echo "  - Oh My Zsh + plugins installed"
    echo "  - Config files linked to ~/.config/"
    echo "  - Design tokens generated"
    echo "  - ~/.zshrc written"
    echo ""
    echo "  Next steps:"
    echo "  1. Log out and back in, or run: chsh -s /usr/bin/zsh"
    echo "  2. Set your wallpaper: shayar-wallpaper ~/path/to/image.jpg"
    echo "  3. (Optional) review config/shayar/settings/shayar.conf"
    echo ""
}

# ---- main ----
main() {
    echo "=== Shayar Bootstrap ==="
    echo ""

    local pm
    pm="$(detect_pm)"
    if [ -z "$pm" ]; then
        error "No supported package manager found (pacman, dnf). Ubuntu/Debian are unsupported due to outdated Wayland packages."
        exit 1
    fi
    info "Detected package manager: $pm"

    phase1_packages "$pm"
    phase2_shell
    phase3_link
    phase4_generate
    phase5_zshrc
    print_summary
}

main "$@"
