# tui-ide-ADR-0011: LazyGit as the git client

**Status:** Accepted
**Date:** 2026-09-16

## Context

The stack owns an interactive git surface. Commit, stage, diff, and history
were done ad hoc at the shell. Neovim has git support three ways: fugitive
(in-buffer), gitsigns (blame and hunks), and a git TUI. The user asked to start
with a terminal git client rather than in-editor bindings.

## Decision

We will add LazyGit as the git client. It installs from `Brewfile` (`lazygit`,
also in the apt fallback) and launches from Neovim with `<leader>gg` via
`kdheepak/lazygit.nvim`. The which-key spec groups it under `<leader>g`.

## Consequences

### Positive

- Full commit/stage/diff/history UI without writing editor bindings.
- Cross-platform via the same Homebrew formula; apt fallback included.
- Fits the multi-pane herdr model — lazygit is one more TUI, not an in-buffer
  plugin.

### Negative

- Does not surface inline blame or per-hunk staging inside the editor; that is
  gitsigns work, deferred until a need shows up.

### Neutral

- LazyGit is a separate binary, so the editor stays terminal-only.

## See Also

- [ADR-0005](0005-neovim-as-editor.md)
- [Architecture](../architecture.md)