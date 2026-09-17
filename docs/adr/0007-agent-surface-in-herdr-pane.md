# tui-ide-ADR-0007: Agent surface is the opencode TUI in a herdr pane

**Status:** Accepted
**Date:** 2026-09-16

## Context

AI agents need a place to run that is persistent, remote-reachable, and separate from human editing. Options: an editor plugin (Neovim agent plugin), a standalone agent TUI, or an agent embedded in the multiplexer. Running the agent inside Neovim couples two unstable surfaces.

## Decision

We will run the opencode TUI in a herdr pane as the agent surface. Neovim remains the human editing surface. The agent and the human share the same host session, so they see the same files.

## Consequences

### Positive

- The agent runs server-side and reattaches with the session.
- Editor and agent can be updated independently.
- The phone can watch or drive the agent over Moshi.

### Negative

- Two tools to configure instead of one integrated plugin.
- Pane layout discipline is needed so agent and editor do not fight for space.

### Neutral

- An editor plugin can be added later without changing this decision's intent.

## See Also

- [Architecture](../architecture.md)
- [ADR-0004](0004-herdr-as-multiplexer.md)
- [ADR-0005](0005-neovim-as-editor.md)
