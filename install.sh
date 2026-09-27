#!/usr/bin/env bash
# tui-ide bootstrap: install the toolchain and stow the dotfiles.
# Works on macOS (Homebrew) and Linux (Homebrew/Linuxbrew; apt fallback).
set -euo pipefail

# Physical path: the backup guard below compares against realpath output.
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
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
  sudo apt-get install -y git curl mosh neovim ripgrep stow jq
  if ! have herdr && [ ! -x "$HOME/.local/bin/herdr" ]; then
    echo "==> Installing herdr (not in apt) from herdr.dev"
    curl -fsSL https://herdr.dev/install.sh | sh
  fi
  # lazygit has no Debian/Ubuntu package (not in 24.04 "noble", which the
  # always-on host runs), so apt-get would abort the whole script. Take the
  # release tarball instead, the same shape as the herdr fallback above.
  if ! have lazygit && [ ! -x "$HOME/.local/bin/lazygit" ]; then
    echo "==> Installing lazygit (not in apt) from GitHub releases"
    case "$(uname -m)" in
      x86_64) asset_arch=x86_64 ;;
      aarch64 | arm64) asset_arch=arm64 ;;
      *) echo "Unsupported architecture for lazygit: $(uname -m)" >&2; exit 1 ;;
    esac
    # Resolve latest via the /releases/latest redirect: no API call, so no rate limit.
    tag="$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
      https://github.com/jesseduffield/lazygit/releases/latest | sed 's|.*/tag/||')"
    mkdir -p "$HOME/.local/bin"
    tmp="$(mktemp -d)"
    curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/${tag}/lazygit_${tag#v}_linux_${asset_arch}.tar.gz" \
      | tar -xz -C "$tmp" lazygit
    install -m 0755 "$tmp/lazygit" "$HOME/.local/bin/lazygit"
    rm -rf "$tmp"
  fi
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
    # Already a stow link, or nothing to replace.
    if [ ! -e "$target" ] || [ -L "$target" ]; then
      continue
    fi
    # Skip anything already resolving into the repo. A folded directory symlink
    # (e.g. ~/.config/nvim -> dotfiles/nvim/.config/nvim) makes $target the
    # tracked file itself, and moving it would delete the source of truth.
    case "$(realpath "$target" 2>/dev/null || true)" in
      "$REPO_DIR"/*) continue ;;
    esac
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    mv "$target" "$BACKUP_DIR/$rel"
    echo "    backed up ~/$rel"
  done < <(cd "$REPO_DIR/dotfiles/$pkg" && find . -type f | sed 's|^\./||')
  stow --dir="$REPO_DIR/dotfiles" --target="$HOME" --no-folding "$pkg"
done

if [ "$os" = "Darwin" ]; then
  # Register terminal-notifier's helper app with Notification Center.
  # macOS authorizes notifications per app identity; opening the bundled app
  # once registers it or permission errors ("Not allowed for this application").
  if have terminal-notifier; then
    open "$(brew --prefix)/opt/terminal-notifier/terminal-notifier.app" 2>/dev/null || true
  fi

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
