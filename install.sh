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

backup_existing() {
    local target="$1"
    if [[ -e "$target" || -L "$target" ]]; then
        log "Backing up existing $target to $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
        mv "$target" "$BACKUP_DIR/"
    fi
}

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
    
    # Install Homebrew dependencies
    if command -v brew &> /dev/null; then
        log "Installing Homebrew dependencies..."
        brew bundle --file="$DOTFILES_DIR/Brewfile" || echo "⚠️  Some Homebrew packages failed to install — continuing anyway"
    else
        echo "⚠️  Homebrew not found. Please install Homebrew first:"
        echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        echo "   Then run this script again."
        exit 1
    fi
    
    # Zsh configuration
    create_symlink "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
    
    # Git configuration
    create_symlink "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
    create_symlink "$DOTFILES_DIR/git/.gitignore_global" "$HOME/.gitignore_global"

    if [[ ! -f "$HOME/.gitconfig.user" ]]; then
        log "Creating ~/.gitconfig.user from template..."
        cp "$DOTFILES_DIR/git/user.gitconfig.template" "$HOME/.gitconfig.user"
        echo "⚠️  Fill in your details in ~/.gitconfig.user (name, email, signingkey)"
    fi

    # Starship prompt
    create_symlink "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

    # Ghostty terminal
    create_symlink "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"

    # Mise version manager
    create_symlink "$DOTFILES_DIR/mise/config.toml" "$HOME/.config/mise/config.toml"

    # Claude Code CLI
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

    # cmux
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

    # Zed editor
    create_symlink "$DOTFILES_DIR/zed/settings.json" "$HOME/.config/zed/settings.json"

    # Claude Code configuration (if it exists)
    if [[ -f "$DOTFILES_DIR/claude/CLAUDE.md" ]]; then
        create_symlink "$DOTFILES_DIR/claude" "$HOME/.claude"
    fi
    
    # Private work configuration
    if [[ -f "$DOTFILES_DIR/private/work.zsh" ]]; then
        create_symlink "$DOTFILES_DIR/private/work.zsh" "$HOME/.private.zsh"
    fi
    
    log "Installation complete! 🎉"
    log ""
    log "Next steps:"
    log "1. Restart your terminal or run: source ~/.zshrc"
    log "2. Install mise-managed tools: mise install"
    log ""
    if [[ -d "$BACKUP_DIR" ]]; then
        log "Your original files were backed up to: $BACKUP_DIR"
    fi
}

main "$@"