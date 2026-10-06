#!/usr/bin/env bash
# tui-ide bootstrap: install the toolchain and stow the dotfiles.
# Works on macOS (Homebrew) and Linux (Homebrew/Linuxbrew; apt fallback).
set -euo pipefail

# Physical path: the backup guard below compares against realpath output.
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
DOTFILES=(nvim herdr git zsh nono)

have() { command -v "$1" >/dev/null 2>&1; }

os="$(uname -s)"

if have brew; then
  echo "==> Installing toolchain with Homebrew"
  # Homebrew 7 refuses to load formulae from third-party taps until they are
  # trusted, so trust the exact tap formulae the Brewfiles use. Trusting the
  # whole tap would also cover formulae this repo does not install (the
  # cavanaug/tap-extras tap also ships copilot-api). Additive and idempotent.
  # Homebrew 6 and older have no `brew trust`, hence the guard. homebrew-core
  # formulae need no entry and must not be listed: `brew trust` rejects their
  # unqualified names, which would abort the script under `set -e`.
  # Ensure third-party taps are tapped (Homebrew 7 requires explicit tapping for trusted taps)
  brew tap anomalyco/tap || true
  brew tap cavanaug/tap-extras || true
  brew tap hashicorp/tap || true
  if brew trust --help >/dev/null 2>&1; then
    for formula in anomalyco/tap/opencode cavanaug/tap-extras/mermaid-ascii hashicorp/tap/terraform; do
      brew trust --formula "$formula"
    done
  fi
  brew bundle --file="$REPO_DIR/Brewfile"
  if [ "$os" = "Darwin" ]; then
    brew bundle --file="$REPO_DIR/Brewfile.macos"
  fi
  # Hold opencode on the 1.x line (ADR-0025). `brew bundle` leaves pinned
  # formulae out of its upgrades, so the pin is what stops the next run from
  # moving the toolchain onto 2.x. Must follow bundle: `brew pin` fails on a
  # formula that is not installed yet. Idempotent - re-pinning only warns.
  brew pin anomalyco/tap/opencode
elif [ "$os" = "Linux" ] && have apt-get; then
  echo "==> Homebrew not found; falling back to apt"
  sudo apt-get update
  # zsh is here and not in the Brewfile because macOS already ships the system
  # /bin/zsh that consumers hardcode; Ubuntu does not package it by default, and
  # the stack needs it for oh-my-zsh, the stowed zsh dotfiles, and alwayson's login
  # shell. Without it the host ends up with a login shell pointing at a binary
  # that was never installed.
  sudo apt-get install -y git git-lfs curl mosh neovim ripgrep stow jq zsh
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
  # Claude Code ships a native binary with no Debian/Ubuntu package, so take the
  # official installer, the same shape as the herdr fallback above.
  if ! have claude && [ ! -x "$HOME/.local/bin/claude" ]; then
    echo "==> Installing claude-code (not in apt) from claude.ai"
    # bash, not sh: the upstream installer is #!/bin/bash and its argument check uses
    # [[ ... =~ ... ]], which dash (Ubuntu's /bin/sh) cannot parse -- it aborts with
    # 'Syntax error: "(" unexpected' before installing anything.
    # CLAUDE_INSTALL_ALLOW_SUDO: the installer refuses to run under sudo, because
    # sudo normally rewrites HOME to /root and leaves 'claude' off the user's PATH.
    # That is not the case here -- this script is invoked with HOME already pointed
    # at the target user, so the binary lands in the right home. The guard is
    # acknowledged deliberately rather than bypassed by accident.
    curl -fsSL https://claude.ai/install.sh | CLAUDE_INSTALL_ALLOW_SUDO=1 bash
  fi
  # nono is the sandbox the agent CLIs run under (ADR-0020). It is not in apt
  # either, but upstream ships a release .deb per architecture whose only
  # dependency is a libc6 floor, so apt can install it as any other package.
  if ! have nono; then
    echo "==> Installing nono (not in apt) from GitHub releases"
    # Resolve latest via the /releases/latest redirect: no API call, so no rate limit.
    tag="$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
      https://github.com/nolabs-ai/nono/releases/latest | sed 's|.*/tag/||')"
    # Debian architecture names, not the uname ones the lazygit tarball uses.
    case "$(uname -m)" in
      x86_64) deb_arch=amd64 ;;
      aarch64 | arm64) deb_arch=arm64 ;;
      *) echo "Unsupported architecture for nono: $(uname -m)" >&2; exit 1 ;;
    esac
    tmp="$(mktemp -d)"
    curl -fsSL "https://github.com/nolabs-ai/nono/releases/download/${tag}/nono-cli_${tag#v}_${deb_arch}.deb" \
      -o "$tmp/nono.deb"
    # A local path rather than dpkg -i, so apt resolves the libc6 dependency
    # instead of leaving a half-configured package behind.
    (cd "$tmp" && sudo apt-get install -y ./nono.deb)
    rm -rf "$tmp"
  fi
else
  echo "Need Homebrew or apt-get. Install Homebrew first: https://brew.sh" >&2
  exit 1
fi

# Pre-pull the nono packs for the two agents sandboxed in the zsh dotfiles.
# `nono run --profile ...` offers to install a missing pack on a TTY and exits
# with a hint when there is none, so pull them here, where the output is
# visible, rather than surprising the user on the first agent launch. A registry
# failure must not abort a bootstrap that has already installed everything else.
if have nono; then
  echo "==> Installing nono sandbox profiles"
  for pack in nolabs-ai/claude nolabs-ai/opencode; do
    nono pull "$pack" ||
      echo "    nono pull $pack failed; re-run it before the first sandboxed session" >&2
  done
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
  # Move non-regular files out of the package before stowing. The pre-ADR-0014
  # folded layout let herdr write its sockets straight into the repo, and they
  # outlived the un-fold. `find -type f` below cannot see them, so stow treats
  # them as content, then aborts the whole run because $HOME already holds the
  # live socket. Back them up rather than delete (convention 3): the socket
  # herdr is actually using lives in $HOME, not in the package.
  while IFS= read -r rel; do
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    mv "$REPO_DIR/dotfiles/$pkg/$rel" "$BACKUP_DIR/$rel"
    echo "    moved non-regular dotfiles/$pkg/$rel out of the package"
  done < <(cd "$REPO_DIR/dotfiles/$pkg" && find . ! -type d ! -type f ! -type l | sed 's|^\./||')

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

# Claude Code user settings are merged, not stowed. `~/.claude/settings.json` is
# the only user-level settings file and has no local-overlay sibling, so the
# hooks iTerm2 and herdr install into it (absolute paths, machine-specific)
# cannot be separated from the portable preferences. Linking the tracked file
# would put those paths in the repo; replacing it would drop the hooks. So the
# tracked file is a defaults template and the real file stays a real file:
# copied on a fresh machine, deep-merged on an existing one with tracked keys
# winning, which is the same precedence stow gives a link. jq `*` merges
# objects key by key, so keys only the local file has (the hooks) survive.
claude_defaults="$REPO_DIR/dotfiles/claude/.claude/settings.defaults.json"
claude_settings="$HOME/.claude/settings.json"
# -L is tested before -f: -f follows symlinks, so a link to a file that is
# missing would read as "no file" and get overwritten.
if [ -L "$claude_settings" ]; then
  echo "==> ~/.claude/settings.json is a link; leaving it alone (see ADR-0019)"
elif [ ! -f "$claude_settings" ]; then
  mkdir -p "$HOME/.claude"
  cp "$claude_defaults" "$claude_settings"
  echo "==> Installed Claude Code settings from dotfiles/claude"
elif have jq; then
  mkdir -p "$BACKUP_DIR/.claude"
  cp "$claude_settings" "$BACKUP_DIR/.claude/settings.json"
  jq -S -s '.[1] * .[0]' "$claude_defaults" "$claude_settings" >"$claude_settings.tmp"
  mv "$claude_settings.tmp" "$claude_settings"
  echo "==> Merged Claude Code settings from dotfiles/claude (previous in $BACKUP_DIR)"
else
  echo "==> jq is missing; leaving ~/.claude/settings.json untouched" >&2
fi

# The opencode client config is machine-local: it carries the herdr session
# plugin path, so convention 4 forbids tracking it and a stow link would put
# that path in the repo (ADR-0026). The example is tracked and the real file is
# copied out of it on a fresh machine, the same shape as the Claude Code
# template above, and for the same reason it is copied rather than merged: the
# copy happens once and the file is then the user's. A file that is already
# there is never touched, so re-running install.sh cannot drop a local plugin
# or theme.
#
# The filename follows the installed major version: v1 reads tui.json(c) and v2
# reads cli.json and ignores tui.json(c), migrating tui.json on first start but
# never tui.jsonc. Both examples stay tracked, so seeding against the installed
# version is all it takes to be right on either line (ADR-0026). Nothing is
# seeded when opencode is missing - the apt path does not install it - rather
# than guessing which line will land.
if have opencode; then
  opencode_major="$(opencode --version 2>/dev/null | awk -F. 'NR==1{print $1}')" || true
  opencode_major="${opencode_major//[!0-9]/}"
  opencode_major="${opencode_major:-0}"
  if [ "$opencode_major" -ge 2 ]; then
    opencode_client="cli.json"
    opencode_example="cli.json.example"
  else
    opencode_client="tui.jsonc"
    opencode_example="tui.jsonc.example"
  fi
  opencode_config="$HOME/.config/opencode/$opencode_client"
  # -L is tested before -f: -f follows symlinks, so a link to a file that is
  # missing would read as "no file" and get overwritten.
  if [ -L "$opencode_config" ]; then
    echo "==> ~/.config/opencode/$opencode_client is a link; leaving it alone (see ADR-0026)"
  elif [ ! -f "$opencode_config" ]; then
    mkdir -p "$HOME/.config/opencode"
    cp "$REPO_DIR/dotfiles/opencode/.config/opencode/$opencode_example" "$opencode_config"
    echo "==> Installed the opencode client config from dotfiles/opencode"
    echo "    Edit ~/.config/opencode/$opencode_client for machine-local values (the herdr session plugin, for example)"
    # Name whichever config file this version ignores, so a machine that moved
    # lines is told its old file is inert rather than leaving it to look right.
    for stale in tui.json tui.jsonc cli.json; do
      if [ "$stale" != "$opencode_client" ] && [ -f "$HOME/.config/opencode/$stale" ]; then
        echo "    NOTE: this opencode version ignores $stale. Move anything you want"
        echo "    keep from it into the file above, then delete it."
      fi
    done
  fi
else
  echo "==> opencode is not installed; skipping the client config. Re-run install.sh after installing it."
fi

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
# Suggest only the overlays this machine is actually missing. A fixed hint
# stays wrong after the first run and trains the reader to ignore the tail of
# the output. The nvim vault overlay is deliberately absent: the vault lives in
# a repo this one does not own, so it is opt-in and documented in the README.
# The opencode client config is not here either; install.sh seeds it above.
# Guarded on ${#next[@]} rather than expanding an empty array: macOS ships
# bash 3.2, where `"${next[@]}"` trips `set -u`.
next=()
[ -f "$HOME/.gitconfig.local" ] ||
  next+=("cp dotfiles/git/.gitconfig.local.example ~/.gitconfig.local")
if [ ${#next[@]} -gt 0 ]; then
  echo "    Next:"
  printf '      %s\n' "${next[@]}"
fi
