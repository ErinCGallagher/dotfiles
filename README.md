# .dotfiles

Personal development environment configuration for macOS.

### Terminal Prompt (Starship)
![Terminal prompt showing Starship configuration with Dracula theme](docs/terminal-config.png)

### Claude Code Status Line
![Claude Code status line showing context, 5h, and 7d usage bars](docs/claude-statusline-config.png)

## Setup

**Prerequisites:** macOS + [Homebrew](https://brew.sh/)

### Quick Installation

1. Clone this repository:

```bash
git clone git@github.com:ErinCGallagher/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

2. Create `~/.gitconfig.user` with your git identity:

```ini
[user]
  name = Your Name
  email = your@email.com
  signingkey = YOUR_SSH_SIGNING_KEY
```

To get your SSH signing key:

```bash
ssh-keygen -t ed25519 -C "your@email.com"
cat ~/.ssh/id_ed25519.pub
```

Paste the output as the `signingkey` value above.

3. *(Optional)* Create `private/work.zsh` for machine-specific config — see [Private Configuration](#private-configuration) below.

4. Run the installation script:

```bash
./install.sh
```

The script will:

- Install all Homebrew dependencies from the Brewfile
- Create symlinks for all configuration files
- Back up any existing files before linking
- Symlink `private/work.zsh` → `~/.private.zsh` if it exists

5. Restart your terminal or source the config:

```bash
source ~/.zshrc
```

6. Install version-managed tools:

```bash
mise install
```

## What's Included?

### Core Shell

- 🐚 **zsh** - Shell with plugins (autosuggestions, syntax highlighting)
- ⭐ **starship** - Custom prompt with Dracula theme + emojis 👸
- 🔄 **mise** - Version manager for dev tools
- 👻 **ghostty** - Terminal emulator
- 🌳 **direnv** - Auto-load environment variables
- 🔍 **fzf** - Fuzzy finder

### Development Tools

- 🔀 **git** + **diff-so-fancy** - Version control with readable diffs
- 🐙 **gh** - GitHub CLI
- 📋 **jq** - JSON processor
- 🌲 **tree** - Directory listing
- 🤖 **Claude Code** - agentic coding tool

## Claude Code

The `claude/` directory contains a custom Claude Code setup:

- **`CLAUDE.md`** — personal coding preferences, git practices, and debugging process that Claude follows in every session
- **`statusline.sh`** — custom status line showing current model, context window usage, and 5h/7d token rate limit bars
- **`commands/`** — custom slash commands (brainstorm, plan, session-summary, find-missing-tests)

The entire `claude/` directory is symlinked to `~/.claude/` by the install script.

## Private Configuration

Machine-specific or sensitive config goes in `private/work.zsh` — this file is gitignored and never committed. The install script symlinks it to `~/.private.zsh`, which `.zshrc` sources automatically if it exists.

Typical contents:

```zsh
# PATH additions for locally installed tools
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# Work credentials and tokens
export GITHUB_TOKEN=...
export AWS_PROFILE=my-profile
```

## Fonts

This setup uses **JetBrains Mono Nerd Font** (installed via Brewfile) for proper icon rendering in Ghostty and the Starship prompt. After running `brew bundle`, the font will be available — you may need to restart your terminal for it to take effect.

## Troubleshooting

1. Ensure macOS and Homebrew are installed: `brew --version`
2. Re-run `brew bundle` if dependencies are missing
3. Restart your terminal after installation
