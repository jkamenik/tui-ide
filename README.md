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
mosh, herdr, opencode, devcontainer, claude-code, ripgrep, stow, jq,
lazygit, terraform, go-task.

macOS casks: Meslo LGS Nerd Font, Google Cloud CLI (gcloud). iTerm2 is
installed manually.

Dotfiles via GNU Stow: zsh, git, nvim, herdr. The opencode client config is
machine-local, so `install.sh` seeds the file the installed opencode version
reads from a tracked example on a fresh machine instead of linking it (see
[ADR-0026](docs/adr/0026-seed-the-client-config-the-installed-version-reads.md)).
Claude Code user settings are merged from a tracked template rather than stowed,
because the hooks iTerm2 and herdr install there are machine-specific and Claude
Code has no user-level overlay file (see
[ADR-0019](docs/adr/0019-merge-claude-user-settings.md)).

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
apt for the core packages plus Neovim, and installs Herdr, LazyGit, and Claude
Code from their official installers (none are in apt). Homebrew 7 will
not load a formula from a third-party tap until it is trusted, so `install.sh`
trusts the tap formulae the Brewfiles use (`cavanaug/tap-extras/mermaid-ascii`
and `hashicorp/tap/terraform`, recorded in `~/.homebrew/trust.json`) before
running `brew bundle`.

## Agents

`opencode` and `claude` are the plain binaries the toolchain installs; zsh does
not wrap them. The nono sandbox they ran under, its registry packs, the tracked
`tui-ide-agent` profile, and the `-yolo` variants are retired
([ADR-0031](docs/adr/0031-retire-the-nono-sandbox.md)). Because the agent is the
pane's foreground process, herdr identifies it in the agents view without a
wrapper hint. Nothing bounds the agent from the rest of your account: the
credential stores nono denied (`~/.ssh`, `~/.aws`, `~/.config/gcloud`,
`~/.config/gh`, shell configs) are reachable from a session, so treat agent
launches as running as you.

Machines provisioned before this change still carry nono, its packs, and the
Supacode integration (self-installed by the Supacode app, never provisioned
here). Remove them with:

```bash
./uninstall-nono-supacode.sh && ./install.sh
```

The cleanup script is idempotent, moves any real state to
`~/.dotfiles-backup/<timestamp>-remove-nono-supacode/` before deleting it, and
is transitional: once every machine has run it, it can be dropped from the
repo.

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

The opencode client config needs no step: `install.sh` copies the example that
matches the installed opencode version, `tui.jsonc` on 1.x and `cli.json` on
2.x, when the file is missing, so the theme follows the terminal palette
(`"theme": "system"`, `theme = { "name": "system", "mode": "system" }`). It is
machine-local rather than linked, so edit it directly to add the herdr session
plugin.

Each version reads only its own file: opencode 2 ignores `tui.json(c)`, and 1.x
ignores `cli.json`. v2 also migrates `tui.json` on first start but not
`tui.jsonc`, so on a machine that upgraded from v1 with the old seeded file,
move anything you want to keep by hand; `install.sh` prints a note naming
whichever stale file it finds. The herdr opencode integration writes its plugin
entry into the file the installed version reads (`tui.jsonc` on 1.x, `cli.json`
on 2.x) and re-creates the 1.x file if it is removed, so a `tui.jsonc` left on a
2.x machine is expected and inert; leave it for herdr rather than deleting it.

opencode tracks the 2.x line ([ADR-0032](docs/adr/0032-track-the-opencode-2.x-line.md)).
The `Brewfile` takes it from `anomalyco/tap/opencode-v2` rather than
homebrew-core, which also ships 2.x but lags the tap. A machine still holding
the 1.x formula must uninstall it first: `brew uninstall opencode`, then run
`install.sh`. To go back to 1.x, edit the `Brewfile` back to
`anomalyco/tap/opencode`, restore the `brew pin anomalyco/tap/opencode` line in
`install.sh`, and `brew uninstall opencode-v2 && ./install.sh`.

The agent config itself, `~/.config/opencode/opencode.json(c)`, stays
machine-local and untracked. A custom provider must name its runtime package on
2.x, where 1.x defaulted to the OpenAI-compatible SDK: without it the first
request fails with `Unsupported package for <provider>/<model>`. The one-line
addition to an existing v1-shaped provider entry is
`"npm": "@ai-sdk/openai-compatible"`. The v2 spelling of the same provider is:

```jsonc
{
  "providers": {
    "acme": {
      "package": "aisdk:@ai-sdk/openai-compatible",
      "settings": {
        "baseURL": "https://llm.example.com/v1",
        "apiKey": "{env:ACME_API_KEY}"
      }
    }
  }
}
```

Keep the `aisdk:` prefix, and keep each provider entry in one format: opencode
does not mix the v1 and v2 spellings field by field. `opencode debug config`
prints what the service actually loaded, scoped to the current directory.

Then finish the iTerm2 setup:

### iTerm2 (macOS)

`install.sh` points iTerm2's custom preferences folder at the repo directory
(it skips this while iTerm2 is running, so quit iTerm2 and re-run if it says
so). Restart iTerm2 afterward; the "Warm Burnout Dark" preset appears under
Settings > Profiles > Colors > Color Presets, and herdr (`theme = "terminal"`)
and opencode (`theme = "system"`) follow the same palette.

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

## Repo Scripts

Helper scripts live in `bin/` at the repo root. They are tracked but are **not**
a stow package and do not populate `~/bin` (which stays free for machine-local
scripts). Instead, `install.sh` puts the directory on `$PATH` by seeding
`~/.zshrc.local` with `export PATH="<repo>/bin:$PATH"`; the stowed `~/.zshrc`
sources that file. The overlay is machine-specific, so the repo path never lands
in a tracked file ([ADR-0033](docs/adr/0033-repo-scripts-in-bin-on-path.md)).

On a machine that already has a `~/.zshrc.local`, `install.sh` appends the line
only when it is missing (backing the file up first). To do it by hand, add
`export PATH="/path/to/tui-ide/bin:$PATH"` to `~/.zshrc.local` (or `~/.zshrc`).

- `git-cleanup [branch]` — fetch with prune, switch to `branch` (default: the
  remote's default branch), fast-forward it, then delete local branches whose
  upstream is gone (merged or squash-merged on the remote). It refuses to run on
  a dirty tree and uses `-D` because a squash merge leaves a branch "unmerged"
  to git. On `$PATH` it is also available as the Git subcommand
  `git cleanup [branch]`. Based on the "Cleanup to a given branch" tip at
  <https://kameniksolutions.com/resources/git-tips-and-tricks/#cleanup-to-a-given-branch>.

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
task --version
git lfs version
devcontainer --version
claude --version
test -x bin/git-cleanup          # repo helper script (ADR-0033)
! command -v nono                # retired by ADR-0031
! command -v supacode             # removed; the CLI link may need 'sudo rm /usr/local/bin/supacode'
```
