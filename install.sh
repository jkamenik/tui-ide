#!/usr/bin/env bash
# tui-ide bootstrap: install the toolchain and stow the dotfiles.
# Works on macOS (Homebrew) and Linux (Homebrew/Linuxbrew; apt fallback).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
DOTFILES=(nvim herdr git zsh)

have() { command -v "$1" >/dev/null 2>&1; }

os="$(uname -s)"

if have brew; then
  echo "==> Installing toolchain with Homebrew"
  brew bundle --file="$REPO_DIR/Brewfile"
  if [ "$os" = "Darwin" ]; then
    brew bundle --file="$REPO_DIR/Brewfile.macos"
  fi
elif [ "$os" = "Linux" ] && have apt-get; then
  echo "==> Homebrew not found; falling back to apt"
  sudo apt-get update
  sudo apt-get install -y git curl mosh ripgrep stow jq lazygit
else
  echo "Need Homebrew or apt-get. Install Homebrew first: https://brew.sh" >&2
  exit 1
fi

if ! have stow; then
  echo "stow is required to link dotfiles" >&2
  exit 1
fi

echo "==> Linking dotfiles"
mkdir -p "$BACKUP_DIR"
for pkg in "${DOTFILES[@]}"; do
  # Back up real files that stow would refuse to replace.
  while IFS= read -r rel; do
    target="$HOME/$rel"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
      mv "$target" "$BACKUP_DIR/$rel"
      echo "    backed up ~/$rel"
    fi
  done < <(cd "$REPO_DIR/dotfiles/$pkg" && find . -type f | sed 's|^\./||')
  stow --dir="$REPO_DIR/dotfiles" --target="$HOME" "$pkg"
done

echo "==> Done. Backups (if any) in $BACKUP_DIR"
echo "    Next: create ~/.gitconfig.local from dotfiles/git/.gitconfig.local.example"
