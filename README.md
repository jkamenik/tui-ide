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
opencode, ripgrep, stow, jq.

macOS casks: Meslo LGS Nerd Font. iTerm2 is installed manually.

Dotfiles via GNU Stow: zsh, git, nvim, herdr.

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

Then finish the iTerm2 setup in `iterm2/README.md`.

## Manual Steps (Not Automated)

- iTerm2 GUI preferences: custom folder, font, warm-burnout, Shift+Enter.
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
```
