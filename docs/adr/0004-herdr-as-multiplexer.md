# tui-ide-ADR-0004: herdr as the multiplexer

**Status:** Accepted
**Date:** 2026-09-16

## Context

The environment needs persistent sessions that survive disconnects and a layout that stays usable on a narrow mobile screen. Candidates: tmux, Zellij, and herdr. tmux is ubiquitous but has a steep, dated configuration surface. Zellij is friendlier but less aligned with the mobile and agent workflow.

## Decision

We will use herdr as the multiplexer on both the workstation and the host. The agent runs in a herdr pane.

## Consequences

### Positive

- Server-side sessions detach and reattach across mosh reconnects.
- A curated, narrow-screen-friendly TUI suits the iPhone over Moshi.
- herdr integrates with the opencode agent surface used for work.

### Negative

- herdr is less ubiquitous than tmux, so it is one more tool to install on every machine.
- Less community configuration to borrow.

### Neutral

- tmux remains available on machines that already have it; this repo does not require its removal.

## See Also

- [Architecture](../architecture.md)
- [ADR-0007](0007-agent-surface-in-herdr-pane.md)
