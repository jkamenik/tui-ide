# TUI IDE

Cross-platform TUI-IDE toolchain and dotfiles for macOS and Linux.

This is a complete stack:

- iTerm2 for terminal on Mac (Moshi recommended for iOS)
- [Zsh](https://www.zsh.org) & [Ohmyzsh](https://ohmyz.sh) for shell
- [Herdr](https://herdr.dev) for terminal multiplexing
- [NeoVim](https://neovim.io) as the editor
- Dotfiles (with local sensitive information overlays, if needed)
- Various developer tools like `mosh`, `gh`

## What It Installs

Toolchain via Homebrew (macOS and Linuxbrew): git, gh, neovim, mosh, herdr,
opencode, ripgrep, stow, jq, lazygit.

macOS casks: Meslo LGS Nerd Font. iTerm2 is installed manually.

Dotfiles via GNU Stow: zsh, git, nvim, herdr.

iTerm2 preferences are managed directly in the repo at
`dotfiles/iterm2/.config/iterm2/AppSupport/`; iTerm2's custom preferences folder
points at that directory.

## Install

```bash
git clone git@github.com:jkamenik/tui-ide.git ~/github.com/jkamenik/tui-ide
cd ~/github.com/jkamenik/tui-ide
./install.sh
```

`install.sh` detects the OS, runs `brew bundle`, and stows the dotfiles. Any
file that would be overwritten is backed up to
`~/.dotfiles-backup/<timestamp>/` first. Linux without Homebrew falls back to
apt for the core packages.

## After Install

Create the machine-local git identity:

```bash
cp dotfiles/git/.gitconfig.local.example ~/.gitconfig.local
# edit email, signing key, and the 1Password agent path
```

For the Obsidian vault workspace, copy the nvim overlay:

```bash
cp dotfiles/nvim/.config/nvim/lua/obsidian-local.example.lua \
  ~/.config/nvim/lua/obsidian-local.lua
# edit the vault path (e.g. ~/github.com/jkamenik/second-brain)
```

Then finish the iTerm2 setup:

### iTerm2 (one-time, macOS)

Point iTerm2's custom preferences folder straight at the repo directory. Use the
GUI (iTerm2 > Settings > General > Preferences > check "Load preferences from a
custom folder or URL") or run:

```bash
defaults write com.googlecode.iterm2 PrefsCustomFolder \
  -string "$HOME/github.com/jkamenik/tui-ide/dotfiles/iterm2/.config/iterm2/AppSupport"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
```

Then restart iTerm2BST. Set "Save changes to folder when iTerm2 quits" to
**Automatically** so every GUI change lands in the repo.

Because iTerm2 writes its plist atomically, a stow symlink would break; here the
custom folder points directly at a tracked repo directory, so there is no
symlink and no copy to keep in sync. After changing settings in the GUI, review
and commit the resulting working-tree change — `git add
dotfiles/iterm2/.config/iterm2/AppSupport/com.googlecode.iterm2.plist`.

## Manual Steps (Not Automated)

- Tailscale: install and join the tailnet (cask on macOS, apt repo on Linux).
- 1Password CLI (`op`) sign-in.

## Documentation

- `AGENTS.md` - guidance for AI agents working in this repo.
- `docs/architecture.md` - system architecture.
- `docs/adr/` - architecture decision records.

## Verification

```bash
nvim --headless "+lua print('ok')" +q
herdr --version
mosh --version
stow --version
lazygit --version
```
