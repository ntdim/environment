#!/bin/bash
# ==============================================================================
# Setup script: Beautiful Terminal (Fish + Tide + Kitty + Kanagawa)
# Target: Ubuntu/Debian-based Linux (KDE Plasma or any DE)
# Для macOS используйте setup-terminal-mac.sh
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Colors for output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*"; }

# ==============================================================================
# 1. Install packages
# ==============================================================================
info "Installing packages: fish, kitty, fastfetch, fonts-noto..."

sudo apt-get update
sudo apt-get install -y fish kitty fastfetch fonts-noto fonts-noto-cjk

ok "Packages installed."

# ==============================================================================
# 2. Symbols Nerd Font Mono (иконки Tide / powerline-разделители)
#    В Noto Sans Mono нет Nerd Font глифов — kitty.conf подключает их через
#    symbol_map на этот шрифт.
# ==============================================================================
info "Installing Symbols Nerd Font Mono..."

if fc-list 2>/dev/null | grep -q 'SymbolsNerdFontMono'; then
    ok "Symbols Nerd Font Mono already installed."
elif sudo apt-get install -y fonts-nerd-fonts 2>/dev/null && fc-list 2>/dev/null | grep -q 'SymbolsNerdFontMono'; then
    ok "Symbols Nerd Font Mono installed from apt (fonts-nerd-fonts)."
else
    # Fallback: достаём один ttf из git-репозитория nerd-fonts (partial clone,
    # без выкачивания всего репо). Работает везде, где доступен github.com.
    warn "apt package fonts-nerd-fonts unavailable — fetching ttf from git."
    TMPNF="$(mktemp -d)"
    if git clone --quiet --filter=blob:none --no-checkout --depth 1 \
            https://github.com/ryanoasis/nerd-fonts.git "$TMPNF/nf" 2>/dev/null; then
        (cd "$TMPNF/nf" && git checkout --quiet HEAD -- \
            "patched-fonts/NerdFontsSymbolsOnly/SymbolsNerdFontMono-Regular.ttf")
        if [ -f "$TMPNF/nf/patched-fonts/NerdFontsSymbolsOnly/SymbolsNerdFontMono-Regular.ttf" ]; then
            mkdir -p "$HOME/.local/share/fonts"
            cp "$TMPNF/nf/patched-fonts/NerdFontsSymbolsOnly/SymbolsNerdFontMono-Regular.ttf" \
               "$HOME/.local/share/fonts/"
            fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true
            ok "Symbols Nerd Font Mono installed to ~/.local/share/fonts."
        else
            warn "Could not fetch Symbols Nerd Font — иконки промпта будут квадратами."
        fi
        rm -rf "$TMPNF"
    else
        warn "github.com недоступен — иконки промпта будут квадратами (см. ../network-notes.md)."
    fi
fi

# ==============================================================================
# 3. Install Fisher (Fish plugin manager)
# ==============================================================================
info "Installing Fisher (Fish plugin manager)..."

FISH=$(which fish)

if $FISH -c 'type -q fisher' 2>/dev/null; then
    ok "Fisher already installed."
else
    $FISH -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'
    ok "Fisher installed."
fi

# ==============================================================================
# 4. Install Tide v6 (prompt theme)
# ==============================================================================
info "Installing Tide v6 prompt theme..."

if $FISH -c 'type -q tide' 2>/dev/null; then
    ok "Tide already installed."
else
    $FISH -c 'fisher install ilancosman/tide@v6'
    ok "Tide v6 installed."
fi

# fisher иногда копирует файлы tide не полностью (проверяем internals промпта);
# в этом случае добираем файлы вручную из tarball.
if ! $FISH -c 'type -q _tide_cache_variables' 2>/dev/null; then
    warn "Tide files incomplete (fisher bug) — completing manually."
    TMPTIDE="$(mktemp -d)"
    if curl -sL --max-time 60 -o "$TMPTIDE/tide.tar.gz" \
            "https://codeload.github.com/ilancosman/tide/tar.gz/refs/tags/v6"; then
        tar -xzf "$TMPTIDE/tide.tar.gz" -C "$TMPTIDE"
        SRC="$(find "$TMPTIDE" -maxdepth 1 -type d -name 'tide-*' | head -1)"
        [ -d "$SRC" ] && {
            mkdir -p "$HOME/.config/fish/functions" "$HOME/.config/fish/conf.d" "$HOME/.config/fish/completions"
            cp -R "$SRC/functions/_tide_*.fish" "$SRC/functions/tide.fish" \
                  "$SRC/functions/fish_prompt.fish" "$SRC/functions/fish_mode_prompt.fish" \
                  "$HOME/.config/fish/functions/"
            cp -R "$SRC/functions/tide" "$HOME/.config/fish/functions/"
            cp "$SRC/conf.d/_tide_init.fish" "$HOME/.config/fish/conf.d/"
            cp "$SRC/completions/tide.fish" "$HOME/.config/fish/completions/"
            ok "Tide files completed."
        }
    fi
    rm -rf "$TMPTIDE"
fi

# ==============================================================================
# 5. Configure Kitty (конфиг с темой Kanagawa и symbol_map из репозитория)
# ==============================================================================
info "Configuring Kitty with Kanagawa theme..."

mkdir -p "$HOME/.config/kitty"
cp "$SCRIPT_DIR/kitty.conf" "$HOME/.config/kitty/kitty.conf"

ok "Kitty config written (~/.config/kitty/kitty.conf)."

# ==============================================================================
# 6. Deploy fastfetch config (Kanagawa)
# ==============================================================================
info "Deploying fastfetch config..."

mkdir -p "$HOME/.config/fastfetch"
cp "$SCRIPT_DIR/fastfetch-config.jsonc" "$HOME/.config/fastfetch/config.jsonc"

ok "fastfetch config written (~/.config/fastfetch/config.jsonc)."

# ==============================================================================
# 7. Apply Fish colors (Kanagawa) + Tide theme
#    Единый источник — theme.fish (public vars tide_left/right_prompt_items!)
# ==============================================================================
info "Applying Fish colors and Tide theme (Kanagawa)..."

$FISH "$SCRIPT_DIR/theme.fish"

ok "Fish colors and Tide theme set."

# ==============================================================================
# 8. Deploy fish config.fish (PATH: ~/.local/bin, opencode)
# ==============================================================================
info "Deploying fish config..."

if [ -f "$HOME/.config/fish/config.fish" ]; then
    warn "~/.config/fish/config.fish already exists — skipping (не перезаписываю)."
else
    mkdir -p "$HOME/.config/fish"
    cp "$SCRIPT_DIR/config.fish" "$HOME/.config/fish/config.fish"
    ok "Fish config written (~/.config/fish/config.fish)."
fi

# ==============================================================================
# 9. Set Fish as default shell
# ==============================================================================
info "Setting Fish as default shell..."

mkdir -p "$HOME/.local/bin"

CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
if [ "$CURRENT_SHELL" = "$FISH" ]; then
    ok "Fish is already the default shell."
else
    sudo chsh -s "$FISH" "$USER"
    ok "Default shell changed to Fish."
fi

# ==============================================================================
# Done!
# ==============================================================================
echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}  Terminal setup complete!${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo "What was installed:"
echo "  - Fish shell (default shell)"
echo "  - Tide v6 prompt (powerline-style) + Kanagawa theme"
echo "  - Fisher plugin manager"
echo "  - Kitty terminal with Kanagawa theme + Nerd Font icons"
echo "  - Noto Sans Mono + Symbols Nerd Font Mono"
echo "  - fastfetch (system info) + Kanagawa config"
echo ""
echo "Next steps:"
echo "  1. Log out and log back in (or run: exec fish)"
echo "  2. Launch Kitty terminal emulator"
echo "  3. Run 'fastfetch' to see system info"
echo ""
echo "Note: If you want to fine-tune the Tide prompt interactively,"
echo "  run: tide configure"
echo ""
