# TUI IDE

Cross-platform TUI-IDE toolchain and dotfiles for macOS and Linux.

This is a complete stack:

- iTerm2 for terminal on Mac (Moshi recommended for iOS)
- [Zsh](https://www.zsh.org) & [Ohmyzsh](https://ohmyz.sh) for shell
- [Herdr](https://herdr.dev) for terminal multiplexing
- [NeoVim](https://neovim.io) as the editor
- Dotfiles (with local sensitive information overlays, if needed)
- Various developer tools like `mosh`, `gh`, `terraform`, `ansible`

## What It Installs

Toolchain via Homebrew (macOS and Linuxbrew): git, git-lfs, gh, ansible, neovim,
mosh, herdr, opencode, nono, claude-code, ripgrep, stow, jq, lazygit, terraform.

macOS casks: Meslo LGS Nerd Font, Google Cloud CLI (gcloud). iTerm2 is
installed manually.

Dotfiles via GNU Stow: zsh, git, nvim, herdr. The opencode TUI config is an
overlay copied from an example. Claude Code user settings are merged from a
tracked template rather than stowed, because the hooks iTerm2 and herdr
install there are machine-specific and Claude Code has no user-level overlay
file (see [ADR-0019](docs/adr/0019-merge-claude-user-settings.md)).

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
`~/.dotfiles-backup/<timestamp>/` first; files that resolve back into the
repository are skipped, so the backup step can never move a tracked file out of
the tree. Linux without Homebrew falls back to
apt for the core packages plus Neovim, and installs Herdr, LazyGit, Claude
Code, and nono from their official installers (none are in apt). Homebrew 7 will
not load a formula from a third-party tap until it is trusted, so `install.sh`
trusts the tap formulae the Brewfiles use (`cavanaug/tap-extras/mermaid-ascii`
and `hashicorp/tap/terraform`, recorded in `~/.homebrew/trust.json`) before
running `brew bundle`.

## Sandboxed Agents

`opencode` and `claude` run inside [nono](https://nono.sh), which enforces a
default-deny filesystem allow-list in the kernel (Landlock on Linux, Seatbelt on
macOS). Credential stores are unreachable from inside — `~/.ssh`, `~/.aws`,
`~/.config/gcloud`, `~/.config/gh`, and your shell configs. `install.sh` pulls
each agent's signed capability profile, so there is nothing to configure:

```bash
opencode        # sandboxed, profile tui-ide-agent (extends the opencode pack)
claude          # sandboxed, profile nolabs-ai/claude
opencode-yolo   # the real binary, no boundary
claude-yolo     # the real binary, no boundary
```

`opencode` layers a tracked profile on top of the signed pack, adding only the
directories this repo's agent sessions actually used — `~/.config/nvim`,
`~/.config/herdr`, `~/.config/iterm2`, and on macOS `~/Library/Fonts` and
`~/Library/LaunchAgents`. Every binary those sessions invoked was already allowed
by the pack, so the profile grants no executables.

Machine-specific paths belong in the git-ignored overlay next to it. Copy the
example, then let `install.sh` or stow link it:

```bash
cp dotfiles/nono/.config/nono/profiles/tui-ide-agent-local.json.example \
   dotfiles/nono/.config/nono/profiles/tui-ide-agent-local.json
```

The wrapper prefers `tui-ide-agent-local` whenever that file exists, so the
overlay needs no repo change. To re-derive the tracked grants from what the
agent has actually done, read the tool calls out of opencode's database and check
each candidate against the pack before granting it:

```bash
sqlite3 ~/.local/share/opencode/opencode.db \
  "SELECT json_extract(data,'\$.state.input.command') FROM part
   WHERE json_extract(data,'\$.type')='tool' AND json_extract(data,'\$.tool')='bash';"
```

Use the `-yolo` variants when a session needs a path its profile denies. To find
out what a denial was and grant it properly instead:

```bash
nono why --path ~/.some/data/dir --op read
nono why -a "$PWD" --profile tui-ide-agent --path ~/.some/data/dir --op read
nono profile show tui-ide-agent
```

The `-a "$PWD"` in the second form matters: it reproduces the `--allow-cwd` the
wrapper passes, and without it `nono why` reports the workdir itself as denied.

See [ADR-0020](docs/adr/0020-sandbox-agent-clis-with-nono.md),
[ADR-0021](docs/adr/0021-derive-nono-profile-from-observed-use.md), and
[ADR-0022](docs/adr/0022-label-sandboxed-agent-for-herdr.md).

## After Install

Create the machine-local git identity:

```bash
cp dotfiles/git/.gitconfig.local.example ~/.gitconfig.local
# edit email, signing key, and the 1Password agent path
```

Optional: for an Obsidian vault, copy the nvim overlay. `obsidian.nvim` is
only loaded when this file exists and its workspace paths are present on disk,
so skip it if you have no vault — nothing else in the config changes.

```bash
cp dotfiles/nvim/.config/nvim/lua/obsidian-local.example.lua \
  ~/.config/nvim/lua/obsidian-local.lua
# edit the vault path (e.g. ~/github.com/jkamenik/second-brain)
```

For the opencode TUI theme, copy the config overlay:

```bash
cp dotfiles/opencode/.config/opencode/tui.jsonc.example \
  ~/.config/opencode/tui.jsonc
# theme "system" follows the terminal palette; add the herdr plugin if used
```

Then finish the iTerm2 setup:

### iTerm2 (macOS)

`install.sh` points iTerm2's custom preferences folder at the repo directory
(it skips this while iTerm2 is running, so quit iTerm2 and re-run if it says
so). Restart iTerm2 afterward; the "Warm Burnout Dark" preset appears under
Settings > Profiles > Colors > Color Presets, and herdr (`theme = "terminal"`)
and opencode (`"theme": "system"`) follow the same palette.

To do it by hand instead:

```bash
defaults write com.googlecode.iterm2 PrefsCustomFolder \
  -string "$HOME/github.com/jkamenik/tui-ide/dotfiles/iterm2/.config/iterm2/AppSupport"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
```

Then restart iTerm2. Set "Save changes to folder when iTerm2 quits" to
**Automatically** so every GUI change lands in the repo.

Because iTerm2 writes its plist atomically, a stow symlink would break; here the
custom folder points directly at a tracked repo directory, so there is no
symlink and no copy to keep in sync. After changing settings in the GUI, review
and commit the resulting working-tree change — `git add
dotfiles/iterm2/.config/iterm2/AppSupport/com.googlecode.iterm2.plist`.

## Manual Steps (Not Automated)

- Tailscale: install and join the tailnet (cask on macOS, apt repo on Linux).
- Google Cloud CLI (`gcloud`): covered by the macOS cask; on Linux, install
  from the Google Cloud apt repo.
- 1Password CLI (`op`) sign-in.

## Troubleshooting

**`stow` reports "existing target is not owned by stow"**, or a config app
ignores your dotfiles: a leftover directory fold from before `--no-folding` is
probably in place, so `$HOME/.config/<pkg>` is one symlink into the repo instead
of a directory of per-file links. Remove the link (never its target) and re-stow:

```bash
for p in nvim herdr; do
  [ -L ~/.config/$p ] && rm ~/.config/$p
done
./install.sh
```

Confirm the result is per-file links before trusting it:

```bash
ls -la ~/.config/nvim/   # init.lua should be a symlink, not a real file
```

**`stow` reports a conflict on `herdr.sock` or `herdr-client.sock`**: a dead
socket is sitting inside the stow package
(`dotfiles/herdr/.config/herdr/`), left over from the folded layout that
predates `--no-folding`. Re-run `./install.sh`: it moves non-regular files out
of a package into `~/.dotfiles-backup/<timestamp>/` before stowing, so the
conflict clears. The socket herdr is actually using lives in `~/.config/herdr/`
and is never touched.

**Neovim plugins appear missing after a reinstall**: the plugin directory
(`~/.local/share/nvim/lazy/`) is not managed by stow and is never touched by
`install.sh`. If plugins vanish, the config is gone, not the plugins — check
`git status` in this repo and look in `~/.dotfiles-backup/<timestamp>/`.

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
git lfs version
nono --version
nono list --installed          # nolabs-ai/claude, nolabs-ai/opencode
nono profile list              # tui-ide-agent, and -local when the overlay exists
claude --version
```
