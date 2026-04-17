#!/bin/bash
# ==============================================================================
# Setup script: Beautiful Terminal (Fish + Tide + Kitty + Kanagawa)
# Targets: Ubuntu/Debian-based Linux (KDE Plasma or any DE)
# ==============================================================================
set -euo pipefail

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
# 2. Install Fisher (Fish plugin manager)
# ==============================================================================
info "Installing Fisher (Fish plugin manager)..."

FISH=$(which fish)

# Check if fisher is already installed
if $FISH -c 'type -q fisher' 2>/dev/null; then
    ok "Fisher already installed."
else
    $FISH -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'
    ok "Fisher installed."
fi

# ==============================================================================
# 3. Install Tide v6 (prompt theme)
# ==============================================================================
info "Installing Tide v6 prompt theme..."

if $FISH -c 'type -q tide' 2>/dev/null; then
    ok "Tide already installed."
else
    $FISH -c 'fisher install ilancosman/tide@v6'
    ok "Tide v6 installed."
fi

# ==============================================================================
# 4. Configure Kitty — Kanagawa theme
# ==============================================================================
info "Configuring Kitty with Kanagawa theme..."

mkdir -p ~/.config/kitty

cat > ~/.config/kitty/kitty.conf << 'KITTYEOF'
# === Font ===
font_family      Noto Sans Mono
bold_font        Noto Sans Mono Bold
italic_font      Noto Sans Mono Italic
bold_italic_font Noto Sans Mono Bold Italic
font_size 14.0

# === Transparency ===
background_opacity 0.85
dynamic_background_opacity yes

# === Cursor ===
cursor_shape beam
cursor_beam_thickness 2.0
cursor_blink_interval 0.5
cursor_stop_blinking_after 15.0

# === Scroll ===
scrollback_lines 10000
show_scrollback yes

# === Misc ===
enable_audio_bell no
visual_bell_duration 0.0
window_padding_width 8 8
remember_window_size  yes
initial_window_width  120c
initial_window_height 35c

# === Kanagawa Theme ===
foreground              #dcd7ba
background              #1f1f28
selection_foreground    #1f1f28
selection_background    #dcd7ba
cursor                  #c8c093
cursor_text_color       #1f1f28
url_color               #7a9cd1

# Black
color0 #090618
color8 #727169
# Red
color1 #c34043
color9 #e82424
# Green
color2  #76946a
color10 #98bb6c
# Yellow
color3  #c0a36e
color11 #e6c384
# Blue
color4  #7e9cd8
color12 #7fb4ca
# Magenta
color5  #957fb8
color13 #938aa9
# Cyan
color6  #6a9589
color14 #7aa89f
# White
color7  #c8c093
color15 #dcd7ba

# Tab bar
tab_bar_edge bottom
tab_bar_style powerline
tab_powerline_style slanted
active_tab_foreground   #1f1f28
active_tab_background   #7e9cd8
inactive_tab_foreground #dcd7ba
inactive_tab_background #2a2a37

# Window borders
active_border_color   #7e9cd8
inactive_border_color #54546d
bell_border_color     #e82424
KITTYEOF

ok "Kitty config written (~/.config/kitty/kitty.conf)."

# ==============================================================================
# 5. Configure Fish colors (Kanagawa)
# ==============================================================================
info "Setting Fish colors to Kanagawa theme..."

$FISH -c '
set -U fish_color_autosuggestion 54546d
set -U fish_color_command 7e9cd8
set -U fish_color_comment 727169
set -U fish_color_end c8c093
set -U fish_color_error c34043
set -U fish_color_escape 957fb8
set -U fish_color_keyword 957fb8
set -U fish_color_normal dcd7ba
set -U fish_color_operator e6c384
set -U fish_color_param dcd7ba
set -U fish_color_quote c0a36e
set -U fish_color_redirection 6a9589
set -U fish_color_search_match --background=2a2a37
set -U fish_color_selection --background=2a2a37
set -U fish_pager_color_completion dcd7ba
set -U fish_pager_color_description 727169
set -U fish_pager_color_prefix 7e9cd8
set -U fish_pager_color_progress 54546d
'

ok "Fish colors set."

# ==============================================================================
# 6. Configure Tide prompt (lean style, matching current setup)
# ==============================================================================
info "Configuring Tide prompt..."

$FISH -c '
# Left items: vi_mode, pwd, git
set -U _tide_left_items vi_mode pwd git

# Right items: status, cmd_duration, context, jobs, node, python, java, kubectl, time
set -U _tide_right_items status cmd_duration context jobs node python java kubectl time

# Character
set -U tide_character_color 5FD700
set -U tide_character_color_failure FF0000
set -U tide_character_icon \u276f
set -U tide_character_vi_icon_default \u276e
set -U tide_character_vi_icon_replace \u25b6
set -U tide_character_vi_icon_visual V

# Prompt layout
set -U tide_left_prompt_frame_enabled false
set -U tide_right_prompt_frame_enabled false
set -U tide_left_prompt_prefix ""
set -U tide_left_prompt_separator_diff_color \ue0b0
set -U tide_left_prompt_separator_same_color \ue0b1
set -U tide_left_prompt_suffix \ue0b0
set -U tide_right_prompt_prefix \ue0b2
set -U tide_right_prompt_separator_diff_color \ue0b2
set -U tide_right_prompt_separator_same_color \ue0b3
set -U tide_right_prompt_suffix ""
set -U tide_prompt_add_newline_before false
set -U tide_prompt_color_frame_and_connection 6C6C6C
set -U tide_prompt_color_separator_same_color 949494
set -U tide_prompt_icon_connection " "
set -U tide_prompt_min_cols 34
set -U tide_prompt_pad_items true
set -U tide_prompt_transient_enabled false

# PWD
set -U tide_pwd_bg_color 3465A4
set -U tide_pwd_color_anchors E4E4E4
set -U tide_pwd_color_dirs E4E4E4
set -U tide_pwd_color_truncated_dirs BCBCBC

# Git
set -U tide_git_bg_color 4E9A06
set -U tide_git_bg_color_unstable C4A000
set -U tide_git_bg_color_urgent CC0000
set -U tide_git_color_branch 000000
set -U tide_git_color_conflicted 000000
set -U tide_git_color_dirty 000000
set -U tide_git_color_operation 000000
set -U tide_git_color_staged 000000
set -U tide_git_color_stash 000000
set -U tide_git_color_untracked 000000
set -U tide_git_color_upstream 000000
set -U tide_git_truncation_length 24

# Status
set -U tide_status_bg_color 2E3436
set -U tide_status_bg_color_failure CC0000
set -U tide_status_color 4E9A06
set -U tide_status_color_failure FFFF00
set -U tide_status_icon \u2714
set -U tide_status_icon_failure \u2718

# Cmd duration
set -U tide_cmd_duration_bg_color C4A000
set -U tide_cmd_duration_color 000000
set -U tide_cmd_duration_decimals 0
set -U tide_cmd_duration_threshold 3000

# Context
set -U tide_context_always_display false
set -U tide_context_bg_color 444444
set -U tide_context_color_default D7AF87
set -U tide_context_color_root D7AF00
set -U tide_context_color_ssh D7AF87
set -U tide_context_hostname_parts 1

# Time
set -U tide_time_bg_color D3D7CF
set -U tide_time_color 000000
set -U tide_time_format %T

# Jobs
set -U tide_jobs_bg_color 444444
set -U tide_jobs_color 4E9A06
set -U tide_jobs_icon \uf013
set -U tide_jobs_number_threshold 1000

# Node
set -U tide_node_bg_color 44883E
set -U tide_node_color 000000
set -U tide_node_icon \ue24f

# Python
set -U tide_python_bg_color 444444
set -U tide_python_color 00AFAF
set -U tide_python_icon \U000f0320

# Java
set -U tide_java_bg_color ED8B00
set -U tide_java_color 000000
set -U tide_java_icon \ue256

# Kubectl
set -U tide_kubectl_bg_color 326CE5
set -U tide_kubectl_color 000000
set -U tide_kubectl_icon \U000f10fe

# Docker
set -U tide_docker_bg_color 2496ED
set -U tide_docker_color 000000
set -U tide_docker_icon \uf308

# VI mode
set -U tide_vi_mode_bg_color_default 949494
set -U tide_vi_mode_bg_color_insert 87AFAF
set -U tide_vi_mode_bg_color_replace 87AF87
set -U tide_vi_mode_bg_color_visual FF8700
set -U tide_vi_mode_color_default 000000
set -U tide_vi_mode_color_insert 000000
set -U tide_vi_mode_color_replace 000000
set -U tide_vi_mode_color_visual 000000
set -U tide_vi_mode_icon_default D
set -U tide_vi_mode_icon_insert I
set -U tide_vi_mode_icon_replace R
set -U tide_vi_mode_icon_visual V

# OS
set -U tide_os_bg_color D4D4D4
set -U tide_os_color E95420

# Go
set -U tide_go_bg_color 00ACD7
set -U tide_go_color 000000

# Rust
set -U tide_rustc_bg_color F74C00
set -U tide_rustc_color 000000

# Ruby
set -U tide_ruby_bg_color B31209
set -U tide_ruby_color 000000
'

ok "Tide prompt configured."

# ==============================================================================
# 7. Set Fish as default shell
# ==============================================================================
info "Setting Fish as default shell..."

CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
if [ "$CURRENT_SHELL" = "$FISH" ]; then
    ok "Fish is already the default shell."
else
    sudo chsh -s "$FISH" "$USER"
    ok "Default shell changed to Fish."
fi

# ==============================================================================
# 8. Ensure local bin is in PATH
# ==============================================================================
info "Ensuring ~/.local/bin is in PATH..."

mkdir -p ~/.local/bin

# Ensure env.fish exists
if [ ! -f ~/.local/bin/env.fish ]; then
    cat > ~/.local/bin/env.fish << 'ENVEOF'
if not contains "$HOME/.local/bin" $PATH
    set -x PATH "$HOME/.local/bin" $PATH
end
ENVEOF
fi

# Source it from fish config if not already
if ! grep -q 'env.fish' ~/.config/fish/conf.d/_tide_init.fish 2>/dev/null; then
    echo '' >> ~/.config/fish/conf.d/_tide_init.fish
    echo 'source "$HOME/.local/bin/env.fish"' >> ~/.config/fish/conf.d/_tide_init.fish
fi

ok "~/.local/bin configured in Fish PATH."

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
echo "  - Tide v6 prompt (powerline-style)"
echo "  - Fisher plugin manager"
echo "  - Kitty terminal with Kanagawa theme"
echo "  - Noto Sans Mono font"
echo "  - fastfetch (system info)"
echo ""
echo "Next steps:"
echo "  1. Log out and log back in (or run: exec fish)"
echo "  2. Launch Kitty terminal emulator"
echo "  3. Run 'fastfetch' to see system info"
echo ""
echo "Note: If you want to fine-tune the Tide prompt interactively,"
echo "  run: tide configure"
echo ""
