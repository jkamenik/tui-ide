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

if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
  echo "==> Installing oh-my-zsh"
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
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
  stow --dir="$REPO_DIR/dotfiles" --target="$HOME" --no-folding "$pkg"
done

if [ "$os" = "Darwin" ]; then
  if [ "$(defaults read com.googlecode.iterm2 LoadPrefsFromCustomFolder 2>/dev/null || echo 0)" = "1" ]; then
    :
  elif pgrep -x iTerm2 >/dev/null 2>&1; then
    echo "==> iTerm2 is running: quit it and re-run ./install.sh to enable the tracked preferences folder"
  else
    echo "==> Pointing iTerm2 at the tracked preferences folder"
    defaults write com.googlecode.iterm2 PrefsCustomFolder \
      -string "$REPO_DIR/dotfiles/iterm2/.config/iterm2/AppSupport"
    defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
  fi

  # Run the herdr server under launchd so it is not part of any terminal app's
  # LaunchServices coalition (macOS force-quits coalition members when the app
  # quits, killing the herdr server and its panes).
  stow --dir="$REPO_DIR/dotfiles" --target="$HOME" --no-folding herdr-launchd
  local_plist_dir="$HOME/.config/herdr-launchd"
  mkdir -p "$local_plist_dir"
  sed -e "s|__HERDR_BIN__|$(command -v herdr)|" \
      -e "s|__HOME__|$HOME|" \
      "$REPO_DIR/dotfiles/herdr-launchd/Library/LaunchAgents/dev.herdr.server.plist.example" \
      > "$local_plist_dir/dev.herdr.server.plist"
  if launchctl print "gui/$(id -u)/dev.herdr.server" >/dev/null 2>&1; then
    :
  elif pgrep -f "$(command -v herdr) server" >/dev/null 2>&1 || [ -S "$HOME/.config/herdr/herdr.sock" ]; then
    echo "==> herdr server is running; adopt launchd ownership at the next server stop:"
    echo "    launchctl bootstrap gui/$(id -u) $local_plist_dir/dev.herdr.server.plist"
  else
    launchctl bootstrap "gui/$(id -u)" "$local_plist_dir/dev.herdr.server.plist"
    echo "==> Registered herdr server as a launchd user agent (survives iTerm2 quit)"
  fi
fi

echo "==> Done. Backups (if any) in $BACKUP_DIR"
echo "    Next: create ~/.gitconfig.local from dotfiles/git/.gitconfig.local.example"
