# AGENTS.md

Guidance for AI agents working in the `tui-ide` repo.

## Purpose

Cross-platform (macOS and Linux) TUI-IDE toolchain and dotfiles. This repo owns
the **interactive environment**: terminal clients, shell, multiplexer, editor,
and the developer tools they need. It does not own scheduled execution
(`automations`) or knowledge (`second-brain`).

## Layout

| Path | Responsibility |
|------|----------------|
| `Brewfile` | Shared toolchain (macOS and Linuxbrew) |
| `Brewfile.macos` | macOS-only casks |
| `install.sh` | Bootstrap: OS detect, `brew bundle`, backup, `stow` |
| `dotfiles/<pkg>/...` | GNU Stow packages mapped onto `$HOME` |
| `dotfiles/iterm2/...` | iTerm2 plist; tracked but not stowed, iTerm2 is pointed at the directory directly (macOS) |
| `dotfiles/claude/...` | Claude Code settings template; tracked but not stowed, `install.sh` merges it into `~/.claude/settings.json` ([ADR-0019](docs/adr/0019-merge-claude-user-settings.md)) |
| `docs/architecture.md` | System architecture |
| `docs/adr/` | Architecture decision records and index |

## Conventions

1. **One decision per ADR.** Files are `docs/adr/NNNN-slug.md`. Add a row to the
   index in `docs/adr/README.md`. Never rewrite the decision in an accepted ADR;
   supersede it. Typos, grammar, and broken cross-reference links may be fixed
   in place, in any file.
2. **Plain GitHub Markdown.** No Obsidian frontmatter and no wikilinks in repo
   docs. Use relative Markdown links.
3. **Keep `install.sh` idempotent and safe.** Back up any file before replacing
   it. Never delete without a backup.
4. **Never commit machine-specific values.** Use overlay files (`*.local`,
   git-ignored) and provide a `.example`.
5. **Casks are macOS-only unless they also build on Linuxbrew.** Gate
   macOS-only casks behind `Brewfile.macos`; a cross-platform cask (`claude-code`)
   belongs in the shared `Brewfile`.
6. **Cross-platform first.** Assume macOS and Linux. Note any macOS-only path.
7. **No `git worktrees`.** The stow symlinks under `$HOME` resolve to the main
   checkout's absolute path, so only main is "live". A worktree cannot serve
   live config; use branches and merge into main instead.

## Making Changes

1. Edit files under `dotfiles/`.
2. Apply with `./install.sh`, or `stow -d dotfiles -t ~ --no-folding <pkg>`.
   Always pass `--no-folding`: a folded directory makes `$HOME/.config/<pkg>`
   a symlink to the repo, which lets `install.sh` move tracked files out of the
   tree ([ADR-0016](docs/adr/0016-never-back-up-files-that-resolve-into-the-repo.md)).
3. Verify with the commands in `README.md`.
4. When behavior changes, update `docs/architecture.md` and add or supersede an
   ADR.

## Out Of Scope

- Always-on host provisioning and runtime. See `automations`
  (`tf/always-on-host`, Plan B runtime).
- Vault content and research. See `second-brain`.

## Verification

```bash
nvim --headless "+lua print('ok')" +q
herdr --version
mosh --version
stow --version
git lfs version
nono --version
claude --version
```
