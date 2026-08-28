#!/bin/bash
# ==============================================================================
# Setup script: Beautiful Terminal (Fish + Tide + Kitty + Kanagawa) — macOS
# Требования: macOS (Apple Silicon или Intel), права admin (sudo для chsh).
# Скрипт идемпотентен — можно запускать повторно.
# Для Linux используйте setup-terminal.sh
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

# jsDelivr-зеркало файлов github-репозиториев (обход блокировки raw.githubusercontent)
JSDELIVR="https://cdn.jsdelivr.net/gh"

# ==============================================================================
# 1. Homebrew (стандартный префикс обязателен: /opt/homebrew или /usr/local —
#    иначе часть bottle считается неперемещаемой и brew собирает её из исходников)
# ==============================================================================
info "Checking Homebrew..."

if ! command -v brew >/dev/null 2>&1; then
    warn "Homebrew not found — installing (спросит пароль sudo)."
    TMPINST="$(mktemp -d)"
    # официальный скрипт лежит на raw.githubusercontent (часто заблокирован в РФ),
    # поэтому ставим клоном с github.com
    git clone --depth=1 https://github.com/Homebrew/install.git "$TMPINST/install"
    NONINTERACTIVE=1 /bin/bash "$TMPINST/install/install.sh"
    rm -rf "$TMPINST"
    # подхватываем свежеустановленный brew
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

BREW_PREFIX="$(brew --prefix)"
if [ "$BREW_PREFIX" != "/opt/homebrew" ] && [ "$BREW_PREFIX" != "/usr/local" ]; then
    err "Homebrew установлен в нестандартный префикс: $BREW_PREFIX"
    err "Часть пакетов будет собираться из исходников (часы). Переустановите brew"
    err "в стандартный префикс и повторите запуск."
    exit 1
fi
ok "Homebrew found at $BREW_PREFIX."

# ==============================================================================
# 2. Install packages: fish, fastfetch
# ==============================================================================
info "Installing packages: fish, fastfetch..."

brew install fish fastfetch

FISH="$(brew --prefix)/bin/fish"

ok "Packages installed."

# ==============================================================================
# 3. Kitty terminal (cask). Если релизы github недоступны из сети — собираем
#    из исходников (codeload.github.com обычно доступен).
# ==============================================================================
install_kitty_from_source() {
    info "Building kitty from source (~10 минут)..."
    brew install pkg-config python@3.14 xxhash simde harfbuzz imagemagick go sphinx-doc
    KITTY_VER="0.48.2"
    TMPK="$(mktemp -d)"
    curl -sL --max-time 120 -o "$TMPK/kitty.tar.gz" \
        "https://codeload.github.com/kovidgoyal/kitty/tar.gz/refs/tags/v$KITTY_VER"
    tar -xzf "$TMPK/kitty.tar.gz" -C "$TMPK"
    cd "$TMPK/kitty-$KITTY_VER"
    # докам нужен sphinx <9 и расширения — ставим в отдельный venv
    PY="$(brew --prefix)/bin/python3"
    "$PY" -m venv "$TMPK/spx" \
        && "$TMPK/spx/bin/pip" install -q "sphinx<9" sphinx-copybutton \
               sphinx-inline-tabs sphinxext-opengraph furo
    export PATH="$TMPK/spx/bin:$(brew --prefix)/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    make && make docs && "$PY" setup.py kitty.app
    rm -rf "/Applications/kitty.app"
    cp -R kitty.app /Applications/
    cd - >/dev/null
    rm -rf "$TMPK"
}

info "Installing Kitty terminal..."

if [ -d /Applications/kitty.app ] && /Applications/kitty.app/Contents/MacOS/kitty --version >/dev/null 2>&1; then
    ok "Kitty already installed: $(/Applications/kitty.app/Contents/MacOS/kitty --version 2>/dev/null | head -1)"
else
    if brew install --cask kitty 2>/dev/null; then
        ok "Kitty installed from cask."
    else
        warn "Kitty cask failed (вероятно, недоступны релизы github) — building from source."
        install_kitty_from_source
        ok "Kitty built from source and installed to /Applications."
    fi
fi

# CLI-симлинки (как делает cask)
mkdir -p "$BREW_PREFIX/bin"
ln -sf /Applications/kitty.app/Contents/MacOS/kitty  "$BREW_PREFIX/bin/kitty"
ln -sf /Applications/kitty.app/Contents/MacOS/kitten "$BREW_PREFIX/bin/kitten"

# ==============================================================================
# 4. Fonts: Noto Sans Mono + Symbols Nerd Font Mono (иконки Tide/powerline)
# ==============================================================================
info "Installing fonts..."

FONT_DIR="$HOME/Library/Fonts"
mkdir -p "$FONT_DIR"

if system_profiler SPFontsDataType 2>/dev/null | grep -q 'Noto Sans Mono'; then
    ok "Noto Sans Mono already installed."
elif brew install --cask font-noto-sans-mono 2>/dev/null; then
    ok "Noto Sans Mono installed from cask."
else
    # fallback: jsDelivr-зеркало репозитория notofonts (без github releases)
    warn "font cask failed — fetching Noto Sans Mono from jsDelivr."
    for w in Regular Bold; do
        curl -sL --max-time 60 -o "$FONT_DIR/NotoSansMono-$w.ttf" \
            "$JSDELIVR/notofonts/notofonts.github.io@main/fonts/NotoSansMono/hinted/ttf/NotoSansMono-$w.ttf"
    done
    # у Noto Sans Mono нет италиков — kitty возьмёт их из системного шрифта
    ok "Noto Sans Mono installed to ~/Library/Fonts."
fi

if ls "$FONT_DIR" 2>/dev/null | grep -q 'SymbolsNerdFontMono'; then
    ok "Symbols Nerd Font Mono already installed."
elif brew install --cask font-symbols-only-nerd-font 2>/dev/null; then
    ok "Symbols Nerd Font Mono installed from cask."
else
    # fallback: один ttf из git-репозитория nerd-fonts (partial clone)
    warn "font cask failed — fetching Symbols Nerd Font Mono from git."
    TMPNF="$(mktemp -d)"
    if git clone --quiet --filter=blob:none --no-checkout --depth 1 \
            https://github.com/ryanoasis/nerd-fonts.git "$TMPNF/nf" 2>/dev/null; then
        (cd "$TMPNF/nf" && git checkout --quiet HEAD -- \
            "patched-fonts/NerdFontsSymbolsOnly/SymbolsNerdFontMono-Regular.ttf")
        cp "$TMPNF/nf/patched-fonts/NerdFontsSymbolsOnly/SymbolsNerdFontMono-Regular.ttf" "$FONT_DIR/"
        ok "Symbols Nerd Font Mono installed to ~/Library/Fonts."
    else
        warn "Не удалось поставить Symbols Nerd Font — иконки промпта будут квадратами."
    fi
    rm -rf "$TMPNF"
fi

# ==============================================================================
# 5. Install Fisher (Fish plugin manager)
# ==============================================================================
info "Installing Fisher (Fish plugin manager)..."

if $FISH -c 'type -q fisher' 2>/dev/null; then
    ok "Fisher already installed."
else
    # официальная команда качает с raw.githubusercontent — если он недоступен,
    # берём ту же функцию с jsDelivr
    if ! $FISH -c 'curl -sL --max-time 20 https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher' 2>/dev/null; then
        warn "raw.githubusercontent.com unavailable — using jsDelivr mirror."
        curl -sL --max-time 60 -o /tmp/fisher-bootstrap.fish \
            "$JSDELIVR/jorgebucaran/fisher@main/functions/fisher.fish"
        $FISH -c 'source /tmp/fisher-bootstrap.fish; fisher install jorgebucaran/fisher'
        rm -f /tmp/fisher-bootstrap.fish
    fi
    ok "Fisher installed."
fi

# ==============================================================================
# 6. Install Tide v6 (prompt theme) + защита от частичной установки fisher-ом
# ==============================================================================
info "Installing Tide v6 prompt theme..."

if ! $FISH -c 'type -q tide' 2>/dev/null; then
    $FISH -c 'fisher install ilancosman/tide@v6'
fi

if ! $FISH -c 'type -q _tide_cache_variables' 2>/dev/null; then
    warn "Tide files incomplete (fisher bug) — completing manually."
    TMPTIDE="$(mktemp -d)"
    curl -sL --max-time 60 -o "$TMPTIDE/tide.tar.gz" \
        "https://codeload.github.com/ilancosman/tide/tar.gz/refs/tags/v6"
    tar -xzf "$TMPTIDE/tide.tar.gz" -C "$TMPTIDE"
    SRC="$(find "$TMPTIDE" -maxdepth 1 -type d -name 'tide-*' | head -1)"
    if [ -d "$SRC" ]; then
        mkdir -p "$HOME/.config/fish/functions" "$HOME/.config/fish/conf.d" "$HOME/.config/fish/completions"
        cp -R "$SRC/functions/_tide_*.fish" "$SRC/functions/tide.fish" \
              "$SRC/functions/fish_prompt.fish" "$SRC/functions/fish_mode_prompt.fish" \
              "$HOME/.config/fish/functions/"
        cp -R "$SRC/functions/tide" "$HOME/.config/fish/functions/"
        cp "$SRC/conf.d/_tide_init.fish" "$HOME/.config/fish/conf.d/"
        cp "$SRC/completions/tide.fish" "$HOME/.config/fish/completions/"
        ok "Tide files completed."
    fi
    rm -rf "$TMPTIDE"
fi

ok "Tide v6 installed."

# ==============================================================================
# 7. Configure Kitty (Kanagawa + symbol_map из репозитория)
# ==============================================================================
info "Configuring Kitty with Kanagawa theme..."

mkdir -p "$HOME/.config/kitty"
cp "$SCRIPT_DIR/kitty.conf" "$HOME/.config/kitty/kitty.conf"

ok "Kitty config written (~/.config/kitty/kitty.conf)."

# ==============================================================================
# 8. Deploy fastfetch config (Kanagawa)
# ==============================================================================
info "Deploying fastfetch config..."

mkdir -p "$HOME/.config/fastfetch"
cp "$SCRIPT_DIR/fastfetch-config.jsonc" "$HOME/.config/fastfetch/config.jsonc"

ok "fastfetch config written (~/.config/fastfetch/config.jsonc)."

# ==============================================================================
# 9. Apply Fish colors (Kanagawa) + Tide theme (theme.fish — единый источник)
# ==============================================================================
info "Applying Fish colors and Tide theme (Kanagawa)..."

$FISH "$SCRIPT_DIR/theme.fish"

ok "Fish colors and Tide theme set."

# ==============================================================================
# 10. Deploy fish config.fish (PATH: brew, ~/.local/bin, opencode)
# ==============================================================================
info "Deploying fish config..."

if [ -f "$HOME/.config/fish/config.fish" ]; then
    warn "~/.config/fish/config.fish already exists — skipping (не перезаписываю)."
else
    mkdir -p "$HOME/.config/fish"
    cp "$SCRIPT_DIR/config.fish" "$HOME/.config/fish/config.fish"
    ok "Fish config written (~/.config/fish/config.fish)."
fi

mkdir -p "$HOME/.local/bin"

# ==============================================================================
# 11. Set Fish as default shell (macOS: сначала /etc/shells, затем chsh)
# ==============================================================================
info "Setting Fish as default shell (спросит пароль)..."

if ! grep -q "^$FISH$" /etc/shells; then
    echo "$FISH" | sudo tee -a /etc/shells >/dev/null
    ok "Added $FISH to /etc/shells."
fi

CURRENT_SHELL="$(dscl . -read "$HOME" UserShell 2>/dev/null | awk '{print $2}')"
if [ "$CURRENT_SHELL" = "$FISH" ]; then
    ok "Fish is already the default shell."
else
    chsh -s "$FISH"
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
echo "  1. Run: exec fish   (или перезапустить терминал)"
echo "  2. Launch Kitty: open -a kitty"
echo "  3. Run 'fastfetch' to see system info"
echo ""
echo "Note: If you want to fine-tune the Tide prompt interactively,"
echo "  run: tide configure"
echo ""
