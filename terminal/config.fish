# === Fish config base ===

# ~/.local/bin в PATH
if test -d "$HOME/.local/bin"
    fish_add_path "$HOME/.local/bin"
end

# opencode
if test -d "$HOME/.opencode/bin"
    fish_add_path "$HOME/.opencode/bin"
end

# Homebrew (macOS; на Linux эти пути не существуют — блок пропускается)
if test -e /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv)
else if test -e /usr/local/bin/brew
    eval (/usr/local/bin/brew shellenv)
end
