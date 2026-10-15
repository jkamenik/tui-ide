#!/usr/bin/env bash
# tui-ide bootstrap: install the toolchain and stow the dotfiles.
# Works on macOS (Homebrew) and Linux (Homebrew/Linuxbrew; apt fallback).
set -euo pipefail

# Physical path: the backup guard below compares against realpath output.
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
DOTFILES=(nvim herdr git zsh opencode-agents)

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
    for formula in anomalyco/tap/opencode-v2 cavanaug/tap-extras/mermaid-ascii hashicorp/tap/terraform; do
      brew trust --formula "$formula"
    done
  fi
  brew bundle --file="$REPO_DIR/Brewfile"
  if [ "$os" = "Darwin" ]; then
    brew bundle --file="$REPO_DIR/Brewfile.macos"
  fi
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

# ~/.zshrc is machine-owned (ADR-0034). Installers and endpoint agents rewrite
# it in place, and while it was a stow link those rewrites landed in the tracked
# file. The tracked config now stows to ~/.config/zsh/tui-ide.zsh and ~/.zshrc
# only sources it, so local patches stay out of the repo. A ~/.zshrc that is
# already there is never overwritten: a link (the stale stow link this change
# leaves behind, or any other) is moved to the backup dir and replaced, and a
# real file gains the source line only if it does not already have it.
zshrc="$HOME/.zshrc"
zshrc_seed='# Owned by this machine, not the repo. The tracked, shared shell
# config is stowed to ~/.config/zsh/tui-ide.zsh; source it here so machine-local
# patches to this file stay untracked. See ADR-0034.
if [ -f "$HOME/.config/zsh/tui-ide.zsh" ]; then
  source "$HOME/.config/zsh/tui-ide.zsh"
fi'
zsh_source_line='[ -f "$HOME/.config/zsh/tui-ide.zsh" ] && source "$HOME/.config/zsh/tui-ide.zsh"'
if [ -L "$zshrc" ]; then
  mkdir -p "$BACKUP_DIR"
  mv "$zshrc" "$BACKUP_DIR/.zshrc"
  printf '%s\n' "$zshrc_seed" >"$zshrc"
  echo "==> Replaced the ~/.zshrc link with a machine-owned file (link in $BACKUP_DIR)"
elif [ ! -e "$zshrc" ]; then
  printf '%s\n' "$zshrc_seed" >"$zshrc"
  echo "==> Seeded ~/.zshrc to source ~/.config/zsh/tui-ide.zsh"
elif grep -qF 'config/zsh/tui-ide.zsh' "$zshrc"; then
  echo "==> ~/.zshrc already sources ~/.config/zsh/tui-ide.zsh"
else
  mkdir -p "$BACKUP_DIR"
  cp "$zshrc" "$BACKUP_DIR/.zshrc"
  printf '\n# Added by tui-ide install.sh: source the tracked shell config (ADR-0034).\n%s\n' \
    "$zsh_source_line" >>"$zshrc"
  echo "==> Appended the tracked shell config source to ~/.zshrc (previous in $BACKUP_DIR)"
fi

# Repo helper scripts live in bin/ and reach $PATH through a machine-specific
# overlay: the absolute repo path differs per machine, so convention 4 forbids
# tracking it in the tracked shell config. That file sources ~/.zshrc.local, and
# this seeds it so the scripts are reachable with no manual step.
# ~/.zshrc.local is a real file the user may also edit, so an existing one is
# only appended to, and only when it does not already reference this repo's bin
# (idempotent, backed up first). ~/bin is left free for machine-local scripts.
# See ADR-0033.
zshrc_local="$HOME/.zshrc.local"
bin_path_line="export PATH=\"$REPO_DIR/bin:\$PATH\""
if [ ! -e "$zshrc_local" ]; then
  cat >"$zshrc_local" <<EOF
# Local shell overrides (machine-specific; not tracked). install.sh keeps this
# repo's bin/ on \$PATH here so the path stays out of the tracked .zshrc.
# See ADR-0033.
$bin_path_line
EOF
  echo "==> Seeded ~/.zshrc.local (adds $REPO_DIR/bin to \$PATH)"
elif grep -qF "$REPO_DIR/bin" "$zshrc_local"; then
  echo "==> ~/.zshrc.local already puts $REPO_DIR/bin on \$PATH"
else
  mkdir -p "$BACKUP_DIR"
  cp "$zshrc_local" "$BACKUP_DIR/.zshrc.local"
  {
    echo
    echo "# Added by tui-ide install.sh: keep this repo's bin/ on \$PATH (ADR-0033)."
    echo "$bin_path_line"
  } >>"$zshrc_local"
  echo "==> Appended $REPO_DIR/bin to ~/.zshrc.local (previous in $BACKUP_DIR)"
fi

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
  # Custom themes are loaded by filename from ~/.config/opencode/themes/, so the
  # tracked Warm Burnout theme is seeded there and then left alone -- same
  # copy-once contract as the client config, because a theme is as editable as
  # the config that references it. Themes are version-independent, unlike the
  # client config above, so this runs on both the v1 and v2 lines.
  opencode_theme_dir="$HOME/.config/opencode/themes"
  if [ ! -f "$opencode_theme_dir/warm-burnout.json" ]; then
    mkdir -p "$opencode_theme_dir"
    cp "$REPO_DIR/dotfiles/opencode/.config/opencode/themes/warm-burnout.json" \
       "$opencode_theme_dir/warm-burnout.json"
    echo "==> Installed the opencode theme warm-burnout from dotfiles/opencode"
    echo "    Select it from /theme in the TUI. iTerm2, herdr, and nvim already"
    echo "    carry the same palette; this is the only piece that needs picking."
  else
    # Copy-once means a tracked edit to the theme never reaches a file that is
    # already there, and nothing else says so: the run still reports green, so a
    # refreshed palette looks applied when it is not. Diff is what makes that
    # staleness visible, because there is no tracked history for a seeded file.
    echo "==> ~/.config/opencode/themes/warm-burnout.json exists; left alone (copy-once)"
    echo "    If the tracked theme changed since it was seeded, merge by hand:"
    echo "      diff -u '$REPO_DIR/dotfiles/opencode/.config/opencode/themes/warm-burnout.json' '$opencode_theme_dir/warm-burnout.json'"
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
  else
    # Copy-once (ADR-0023): a tracked change to the example never reaches a file
    # that already exists, and nothing else flags it -- the run still reports
    # green, so an updated default looks applied when it is not. That is the
    # contract's whole failure mode, and it is silent, so say it and hand over the
    # diff. A seeded file has no tracked history, so diffing it against the
    # example is the only way to see what has moved.
    echo "==> ~/.config/opencode/$opencode_client exists; left alone (copy-once, ADR-0023)"
    echo "    Tracked changes to $opencode_example are NOT applied to it. If the"
    echo "    example has moved since this was seeded, merge by hand:"
    echo "      diff -u '$REPO_DIR/dotfiles/opencode/.config/opencode/$opencode_example' '$opencode_config'"
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
