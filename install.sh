#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

log() {
    echo "🔧 $1"
}

error() {
    echo "❌ $1" >&2
    exit 1
}

# Moves any existing file or symlink at the target path into a timestamped
# backup directory before it gets overwritten by a new symlink.
backup_existing() {
    local target="$1"
    if [[ -e "$target" || -L "$target" ]]; then
        log "Backing up existing $target to $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
        mv "$target" "$BACKUP_DIR/"
    fi
}

# Creates a symlink from source to target, backing up anything already at target.
# Parent directories are created if they don't exist.
create_symlink() {
    local source="$1"
    local target="$2"

    log "Linking $source -> $target"
    backup_existing "$target"
    mkdir -p "$(dirname "$target")"
    ln -sf "$source" "$target"
}

main() {
    log "Starting dotfiles installation from $DOTFILES_DIR"

    # Install all packages listed in the Brewfile (editors, CLI tools, fonts, etc.).
    # Failures are non-fatal so a single missing cask doesn't abort the whole install.
    if command -v brew &> /dev/null; then
        log "Installing Homebrew dependencies..."
        brew bundle --file="$DOTFILES_DIR/Brewfile" || echo "⚠️  Some Homebrew packages failed to install — continuing anyway"
    else
        echo "⚠️  Homebrew not found. Please install Homebrew first:"
        echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        echo "   Then run this script again."
        exit 1
    fi

    # Symlink zsh config so shell settings are managed from the dotfiles repo.
    create_symlink "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"

    # Symlink shared git config. The user-specific config (~/.gitconfig.user) is
    # kept separate and gitignored so name/email/signing key stay off-repo.
    create_symlink "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
    create_symlink "$DOTFILES_DIR/git/.gitignore_global" "$HOME/.gitignore_global"

    if [[ ! -f "$HOME/.gitconfig.user" ]]; then
        log "Creating ~/.gitconfig.user from template..."
        cp "$DOTFILES_DIR/git/user.gitconfig.template" "$HOME/.gitconfig.user"
        echo "⚠️  Fill in your details in ~/.gitconfig.user (name, email, signingkey)"
    fi

    # Symlink Starship prompt config (custom Dracula theme).
    create_symlink "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

    # Symlink Ghostty terminal config (theme, keybindings).
    create_symlink "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"

    # Symlink mise config so tool versions (Go, Node, Python, etc.) stay in sync.
    create_symlink "$DOTFILES_DIR/mise/config.toml" "$HOME/.config/mise/config.toml"

    # Install Claude Code CLI if not already present. Prompts before installing
    # since it runs a remote install script.
    if ! command -v claude &> /dev/null; then
        read -p "🤖 Install Claude Code CLI? [y/N] " -n 1 -r || true
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log "Installing Claude Code CLI..."
            curl -fsSL https://claude.ai/install.sh | bash
        else
            log "Skipping Claude Code CLI installation"
        fi
    else
        log "Claude Code CLI already installed"
    fi

    # Install cmux if not already present. Optional — prompts before installing.
    if [[ ! -d "/Applications/cmux.app" ]] && ! brew list --cask cmux &> /dev/null; then
        read -p "🖥️  Install cmux? It's a Ghostty-built terminal great for multi-tasking AI agents and managing git worktrees. [y/N] " -n 1 -r || true
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log "Installing cmux..."
            brew install --cask cmux
        else
            log "Skipping cmux installation"
        fi
    else
        log "cmux already installed"
    fi

    # Symlink Zed editor settings.
    create_symlink "$DOTFILES_DIR/zed/settings.json" "$HOME/.config/zed/settings.json"

    # VS Code: if both VS Code and dotfiles config are present, ask whether to apply
    # the dotfiles config to VS Code or pull the current VS Code config back into the
    # dotfiles. This lets the script double as a way to update tracked config from a
    # machine that has diverged.
    VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
    VSCODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
    if [[ -d "/Applications/Visual Studio Code.app" ]]; then
        if [[ -f "$DOTFILES_DIR/vscode/settings.json" ]] || [[ -f "$DOTFILES_DIR/vscode/extensions.txt" ]]; then
            echo "⚙️  VS Code config found in dotfiles. What would you like to do?"
            echo "   1) Use dotfiles config (symlink settings, install extensions from list)"
            echo "   2) Overwrite dotfiles config with current VS Code config"
            read -p "   Choice [1/2]: " -n 1 -r vscode_choice || true
            echo
            if [[ $vscode_choice == "2" ]]; then
                log "Copying current VS Code settings to dotfiles..."
                cp "$VSCODE_USER_DIR/settings.json" "$DOTFILES_DIR/vscode/settings.json"
                log "Saving current VS Code extensions to dotfiles..."
                "$VSCODE_BIN" --list-extensions > "$DOTFILES_DIR/vscode/extensions.txt"
                log "VS Code dotfiles updated — commit the changes to save them"
            else
                create_symlink "$DOTFILES_DIR/vscode/settings.json" "$VSCODE_USER_DIR/settings.json"
                log "Installing VS Code extensions..."
                while IFS= read -r ext; do
                    [[ -z "$ext" ]] && continue
                    "$VSCODE_BIN" --install-extension "$ext" --force 2>/dev/null || echo "⚠️  Failed to install extension: $ext"
                done < "$DOTFILES_DIR/vscode/extensions.txt"
            fi
        else
            create_symlink "$DOTFILES_DIR/vscode/settings.json" "$VSCODE_USER_DIR/settings.json"
        fi
    else
        log "VS Code not found, skipping"
    fi

    # Symlink the entire claude/ directory to ~/.claude so Claude Code picks up
    # CLAUDE.md, the status line script, and custom slash commands.
    if [[ -f "$DOTFILES_DIR/claude/CLAUDE.md" ]]; then
        create_symlink "$DOTFILES_DIR/claude" "$HOME/.claude"
    fi

    # Symlink private work config if it exists. This file is gitignored and holds
    # machine-specific env vars, tokens, and PATH additions.
    if [[ -f "$DOTFILES_DIR/private/work.zsh" ]]; then
        create_symlink "$DOTFILES_DIR/private/work.zsh" "$HOME/.private.zsh"
    fi

    log "Installation complete! 🎉"
    log ""
    log "Next steps:"
    log "1. Restart your terminal or run: source ~/.zshrc"
    log "2. Install mise-managed tools: mise install"
    log "3. Open Ghostty to check out your new config!"
    log ""
    if [[ -d "$BACKUP_DIR" ]]; then
        log "Your original files were backed up to: $BACKUP_DIR"
    fi
}

main "$@"
