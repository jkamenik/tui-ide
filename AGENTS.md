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
| `docs/architecture.md` | System architecture |
| `docs/adr/` | Architecture decision records and index |
| `iterm2/` | Terminal profile notes |

## Conventions

1. **One decision per ADR.** Files are `docs/adr/NNNN-slug.md`. Add a row to the
   index in `docs/adr/README.md`. Never edit an accepted ADR; supersede it.
2. **Plain GitHub Markdown.** No Obsidian frontmatter and no wikilinks in repo
   docs. Use relative Markdown links.
3. **Keep `install.sh` idempotent and safe.** Back up any file before replacing
   it. Never delete without a backup.
4. **Never commit machine-specific values.** Use overlay files (`*.local`,
   git-ignored) and provide a `.example`.
5. **Casks are macOS-only.** Gate them behind `Brewfile.macos`.
6. **Cross-platform first.** Assume macOS and Linux. Note any macOS-only path.

## Making Changes

1. Edit files under `dotfiles/`.
2. Apply with `./install.sh` or `stow -d dotfiles -t ~ <pkg>`.
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
```
