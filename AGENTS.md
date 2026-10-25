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
| `install.sh` | Bootstrap: OS detect, `brew bundle`, backup, `stow`; also seeds `~/.zshrc.local` so `bin/` is on `$PATH` ([ADR-0033](docs/adr/0033-repo-scripts-in-bin-on-path.md)) |
| `bin/` | Repo helper scripts (e.g. `git-cleanup`, `git-workspace`, `mac-vps`); tracked, not stowed, put on `$PATH` via the `~/.zshrc.local` overlay ([ADR-0033](docs/adr/0033-repo-scripts-in-bin-on-path.md), [ADR-0040](docs/adr/0040-create-and-open-worktrees-in-git-workspace.md), [ADR-0042](docs/adr/0042-check-remote-login-in-mac-vps.md)) |
| `uninstall-nono-supacode.sh` | Transitional one-shot cleanup for machines provisioned before [ADR-0031](docs/adr/0031-retire-the-nono-sandbox.md); delete it once every machine has run it |
| `dotfiles/<pkg>/...` | GNU Stow packages mapped onto `$HOME` |
| `dotfiles/iterm2/...` | iTerm2 plist; tracked but not stowed, iTerm2 is pointed at the directory directly (macOS) |
| `dotfiles/claude/...` | Claude Code settings template; tracked but not stowed, `install.sh` merges it into `~/.claude/settings.json` ([ADR-0019](docs/adr/0019-merge-claude-user-settings.md)) |
| `dotfiles/opencode/...` | opencode client config templates (`tui.jsonc.example` for 1.x, `cli.json.example` for 2.x), server config template (`opencode.jsonc.example`), plus the tracked `themes/*.json`; tracked but not stowed, `install.sh` copies them when missing ([ADR-0026](docs/adr/0026-seed-the-client-config-the-installed-version-reads.md)) |
| `dotfiles/opencode-agents/...` | opencode global `AGENTS.md`; portable, so stowed as a link rather than seeded from an example ([ADR-0030](docs/adr/0030-stow-the-global-opencode-agents-md.md)) |
| `docs/architecture.md` | System architecture |
| `docs/adr/` | Architecture decision records and index |
| `docs/runbooks/` | Gated per-machine try-it procedures, e.g. the opencode 1.x to 2.x upgrade ([ADR-0025](docs/adr/0025-pin-opencode-to-the-1.x-line.md) gate, now landed by [ADR-0032](docs/adr/0032-track-the-opencode-2.x-line.md)) |

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
8. **A file a tool rewrites in place is machine-owned.** Do not stow-link it:
   the machine owns the file at the tool's expected path, and the tracked config
   is delivered as a separate file the machine file includes or sources (git
   `[include]`, zsh `source`). `install.sh` seeds or migrates it, backing up
   first. When the tool has no include mechanism, fall back to the copy-once
   template or the merge-from-template contract
   ([ADR-0035](docs/adr/0035-machine-owned-config-includes-tracked-config.md)).

## Making Changes

1. Edit files under `dotfiles/`.
2. Apply with `./install.sh`, or `stow -d dotfiles -t ~ --no-folding <pkg>`.
   Always pass `--no-folding`: a folded directory makes `$HOME/.config/<pkg>`
   a symlink to the repo, which lets `install.sh` move tracked files out of the
   tree ([ADR-0016](docs/adr/0016-never-back-up-files-that-resolve-into-the-repo.md)).
3. Verify with the commands in `README.md`.
4. When behavior changes, update `docs/architecture.md` and add or supersede an
   ADR.
5. Commit and push. A change is not finished until it is on `origin/main`; do
   not leave work uncommitted. Push a functional change only once it has been
   confirmed to work — a manual test, or the user saying it does. A
   non-functional change (docs, comments, a version pin) can go straight in.
   Match the message style in `git log`, and keep unrelated changes in separate
   commits.

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
devcontainer --version
claude --version
opencode --version       # 2.x (ADR-0032)
test -x bin/git-cleanup  # repo helper script (ADR-0033)
test -x bin/git-workspace # worktree helper script (ADR-0040)
test -x bin/check-models   # model testing script (ADR-0037)
test -x bin/mac-vps      # laptop/VPS toggle script (ADR-0042)
test -L ~/.config/opencode/plugins/herdr-worktree-open.js  # stowed plugin (ADR-0036)
test -L ~/.config/opencode/model-recommendation/tui.js     # stowed recommendation banner plugin (ADR-0037)
test ! -L ~/.zshrc       # machine-owned; sources the tracked rc (ADR-0034)
[[ "${OSTYPE}" != darwin* ]] || zsh -ic 'whence -w opencode' | grep -q 'opencode: function'  # caffeinate wrapper, macOS only (ADR-0039)
test ! -L ~/.gitconfig   # machine-owned; includes the tracked config (ADR-0035)
! command -v nono        # retired by ADR-0031
! command -v supacode    # self-installed; cleaned by uninstall-nono-supacode.sh
```

`opencode` and `claude` are the plain binaries on `$PATH`: no sandbox, so
herdr labels the agent from the pane's foreground process and a session
reaches everything the user can reach
([ADR-0031](docs/adr/0031-retire-the-nono-sandbox.md)). The single exception
is a macOS zsh function that execs the opencode TUI under `caffeinate -i` so
the Mac stays awake while a TUI runs; the exec keeps the foreground process
name `opencode`, and server subcommands run unwrapped
([ADR-0039](docs/adr/0039-caffeinate-the-opencode-tui.md)).

The opencode 2.x switch was landed with
[docs/runbooks/upgrade-to-opencode2.md](docs/runbooks/upgrade-to-opencode2.md)
([ADR-0032](docs/adr/0032-track-the-opencode-2.x-line.md)), so
`opencode --version` reports 2.x. The gate's failure mode was a config gap, not
the gateway: a custom provider must name `"npm": "@ai-sdk/openai-compatible"`.
