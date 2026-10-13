#!/usr/bin/env bash
# One-shot cleanup of the nono agent sandbox and the Supacode integration
# retired by ADR-0031. Run it once on a machine provisioned before that
# retirement, after `git pull`, then `./install.sh` to link the zsh config that
# no longer wraps the agents:
#
#   ./uninstall-nono-supacode.sh && ./install.sh
#
# Idempotent: a re-run finds nothing and changes nothing. Real state is moved
# to `~/.dotfiles-backup/<timestamp>-remove-nono-supacode/` before deletion
# (convention 3). Links resolving into this repo are dropped without a backup,
# the same guard install.sh applies (ADR-0016). Nothing here removes opencode
# or its own config; it only drops the sandbox and Supacode layers.
set -euo pipefail

have() { command -v "$1" >/dev/null 2>&1; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
BK="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)-remove-nono-supacode"

# Move one real file or directory into the backup. Absent paths are skipped.
move_to_backup() {
  if [ -e "$1" ] && [ ! -L "$1" ]; then
    mkdir -p "$BK"
    mv "$1" "$BK/$(basename "$1")"
    echo "    backed up $1 to $BK"
  fi
}

echo "==> Uninstalling nono"
if have brew; then
  if brew list --formula 2>/dev/null | grep -qx nono; then
    brew uninstall nono
  elif brew list --cask 2>/dev/null | grep -qx nono; then
    brew uninstall --cask nono
  fi
elif [ "$(uname -s)" = "Linux" ] && have apt-get && dpkg -s nono >/dev/null 2>&1; then
  sudo apt-get purge -y nono
fi
if have nono; then
  echo "    WARNING: a nono is still on PATH ($(command -v nono));" >&2
  echo "    it came from a channel this script does not manage; remove it by hand." >&2
fi

echo "==> Removing nono state"
# ~/.config/nono mixes stow links into the repo (profiles), real files nono
# rewrote in place (the active profile), and its own package state. Copy the
# regular files out first -- find without -L reports symlinks as type l, so
# links into the repo are deliberately not copied -- then drop the tree.
if [ -d "$HOME/.config/nono" ]; then
  mkdir -p "$BK/nono-config"
  (cd "$HOME/.config/nono" && find . -type f | while IFS= read -r f; do
    mkdir -p "$BK/nono-config/$(dirname "$f")"
    cp -p "$f" "$BK/nono-config/$f"
  done)
  rm -rf "$HOME/.config/nono"
  echo "    backed up the regular files under ~/.config/nono, removed the tree"
fi
for p in "$HOME/.local/state/nono" "$HOME/.local/share/nono" "$HOME/.cache/nono" \
         "$HOME/.config/opencode/plugins/nono-sandbox.ts" \
         "$HOME/.config/opencode/skills/nono-sandbox"; do
  move_to_backup "$p"
done

echo "==> Uninstalling Supacode"
# The cask is macOS-only; its zap stanza trashes the app-support trees.
if [ "$(uname -s)" = "Darwin" ] && have brew &&
   brew list --cask 2>/dev/null | grep -qx supacode; then
  brew uninstall --cask supacode --zap
fi
if [ -L /usr/local/bin/supacode ]; then
  # CLI symlink the app installs for itself, root-owned. Needs sudo; try
  # non-interactively first so an unattended run does not stall.
  if sudo -n rm -f /usr/local/bin/supacode 2>/dev/null; then
    echo "    removed /usr/local/bin/supacode"
  else
    echo "    NOTE: run 'sudo rm /usr/local/bin/supacode' to drop the CLI link." >&2
  fi
fi
for p in "$HOME/.supacode" "$HOME/.config/supacode" \
         "$HOME/.config/opencode/plugins/supacode-presence.js" \
         "$HOME/.config/opencode/skills/supacode-cli" \
         "$HOME/.config/opencode/skills/supacode-deeplinks"; do
  move_to_backup "$p"
done

echo "==> Checking the shell"
# On a machine with the stowed zshrc this grep sees the new file and stays
# quiet. A real ~/.zshrc edited by hand is left alone; say what to remove.
if [ -f "$HOME/.zshrc" ] && grep -q nono_agent "$HOME/.zshrc" 2>/dev/null; then
  echo "    WARNING: ~/.zshrc still defines nono_agent; re-run ./install.sh if it" >&2
  echo "    is stowed, or delete the wrapper block by hand." >&2
fi

if [ -d "$BK" ]; then
  echo "==> Done. Backups in $BK"
else
  echo "==> Done. Nothing to remove; this machine is already clean."
fi
