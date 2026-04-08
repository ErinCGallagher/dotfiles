# git-template

This directory contains template git configuration files with placeholder values. **Do not edit these directly.**

When you run `install.sh`, it will:

1. Copy these files to `private/git/` (which is gitignored)
2. Symlink `private/git/.gitconfig` → `~/.gitconfig`
3. Symlink `private/git/.gitignore_global` → `~/.gitignore_global`

**Fill in your details in `private/git/.gitconfig`** — that's the live config on your machine. Your name, email, and signing key stay local and are never committed to this repo.
