# tui-ide-ADR-0005: Neovim as the editor

**Status:** Accepted
**Date:** 2026-09-16

## Context

The environment needs an editor that works over mosh, on a phone-sized screen, and alongside an agent that edits files in the same sessions. Candidates: Helix, Emacs, VS Code (remote), and Neovim. Helix is modal and modern but has a smaller plugin ecosystem.

## Decision

We will use Neovim as the human editing surface. The agent edits are handled by the opencode TUI, not by Neovim. The `EDITOR` variable stays `hx` until the Neovim config is proven and the switch is staged.

## Consequences

### Positive

- Neovim is fast over mosh and scriptable in Lua.
- A large plugin ecosystem covers most editing needs.
- Config lives in git and is portable across macOS and Linux.

### Negative

- Lua configuration is a learning surface for anyone coming from Vimscript.
- Keeping `EDITOR` on `hx` until the switch means a temporary split.

### Neutral

- Helix can still serve as an alternate editor for quick edits.

## See Also

- [Architecture](../architecture.md)
- [ADR-0007](0007-agent-surface-in-herdr-pane.md)
