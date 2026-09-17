# tui-ide-ADR-0001: Keep a separate `tui-ide` repo

**Status:** Accepted
**Date:** 2026-09-16

## Context

The interactive environment could have lived in the existing `automations` repo, which already holds GCP infra, the runtime, and dotfiles. But `automations` owns scheduled execution and the always-on host. Mixing an interactive client environment into it turns that repo into a grab bag and couples two lifecycles.

## Decision

We will keep a separate `tui-ide` repo for the interactive environment. `automations` remains for scheduled execution and host provisioning. `second-brain` remains for knowledge.

## Consequences

### Positive

- Each repo has one clear responsibility and its own lifecycle.
- `tui-ide` is safe to clone on any workstation, including machines that need no host access.
- Client concerns (fonts, terminal profiles, shell) do not bloat the automation repo.

### Negative

- Dotfiles now live in a third place, so the host cannot share them until `automations` consumes this repo.
- One more repo to clone and keep current.

### Neutral

- Nothing prevents `automations` from pulling `tui-ide` dotfiles later.

## See Also

- [Architecture](../architecture.md)
