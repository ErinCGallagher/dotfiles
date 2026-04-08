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

2. *(Optional)* Create `private/work.zsh` for machine-specific config — see [Private Configuration](#private-configuration) below.

3. Run the installation script:

```bash
./install.sh
```

The script will:

- Install all Homebrew dependencies from the Brewfile
- Create symlinks for all configuration files
- Back up any existing files before linking
- Create `~/.gitconfig.user` from the template if it doesn't exist
- Symlink `private/work.zsh` → `~/.private.zsh` if it exists
- Will ask you if you want to install [cmux](#terminal-cmux)

4. Fill in your details in `~/.gitconfig.user`:

```ini
[user]
  name = Your Name
  email = your@email.com
  signingkey = YOUR_SSH_SIGNING_KEY
```

You can Generate an SSH key for git commit signing:

```bash
ssh-keygen -t ed25519 -C "your@email.com"
```

The `signingkey` is the contents of `~/.ssh/id_ed25519.pub`.


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
- **`commands/`** — custom slash commands (session-summary)

The entire `claude/` directory is symlinked to `~/.claude/` by the install script.

### Terminal: cmux

[cmux](https://cmux.com/) is a terminal multiplexer that pairs well with Claude Code. It's great for managing git worktrees, running multiple AI agents in parallel, and general multitasking — keeping each context in its own pane or window without losing state.

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

## VS Code

VS Code configuration lives in `vscode/`.

- **`settings.json`** — editor settings, symlinked to `~/Library/Application Support/Code/User/settings.json`
- **`extensions.txt`** — list of extensions, installed automatically by `install.sh`

To update the tracked extension list after installing new extensions:

```bash
/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code --list-extensions > vscode/extensions.txt
```

To install extensions from the list manually:

```bash
while IFS= read -r ext; do code --install-extension "$ext"; done < vscode/extensions.txt
```

## Ghostty

Ghostty configuration lives in `ghostty/config`.

### Changing the Theme

To see all available built-in themes:

```bash
ghostty +list-themes
```

Update the theme by changing this line in `ghostty/config`:

```
theme = Carbonfox
```

Restart Ghostty for the change to take effect.

## Fonts

This setup uses **JetBrains Mono Nerd Font** (installed via Brewfile) for proper icon rendering in Ghostty and the Starship prompt. After running `brew bundle`, the font will be available — you may need to restart your terminal for it to take effect.

## Troubleshooting

1. Ensure macOS and Homebrew are installed: `brew --version`
2. Re-run `brew bundle` if dependencies are missing
3. Restart your terminal after installation
