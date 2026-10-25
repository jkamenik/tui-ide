# tui-ide-ADR-0042: Check Remote Login in `mac-vps` instead of toggling it

**Status:** Accepted; supersedes [0041](0041-toggle-laptop-and-vps-modes-with-mac-vps.md)
**Date:** 2026-10-25

## Context

ADR-0041 had `mac-vps on/off` enable and disable Remote Login itself, through
`systemsetup` with a `launchctl` fallback. The first real runs showed both
halves of that scope were wrong. Operationally: `systemsetup -setremotelogin`
blocks indefinitely in a context where TCC grants no Full Disk Access, which
hung `mac-vps off` mid-command — the script had to grow a deadline, a
foreground sudo priming step, and a process-tree kill just to call it safely.
Design-wise: shutting sshd off after each visit buys nothing. The port is not
exposed to the internet (no forwarding), auth is key plus password, and FileVault
blocks every session after a reboot anyway — while the disable re-adds a manual
step to every future trip.

## Decision

`mac-vps` never changes Remote Login. It only *checks* whether port 22 is
listening:

1. **`status`** reports the port as a row alongside the power settings.
2. **`on`** applies the never-sleep `pmset` block, then reports reachability:
   exit `0` when awake and listening, exit `2` with the exact System Settings
   path (`General → Sharing → Remote Login`) when awake but silent, exit `1`
   when pmset did not take.
3. **`off`** restores the stock `pmset` snapshot and leaves Remote Login
   exactly as it is.

Mode follows reachability rather than a pair of per-switch states: awake +
listening is VPS mode (`0`), sleeping is laptop mode (`1`) regardless of
Remote Login's state, and mixed power settings — or awake with nothing on
`:22` — is partial (`2`), the case where the Mac could not be reached.

The script's entire privileged interface is therefore `pmset`; the
`set_remote_login`, `run_timed`, and SSH-session refusal code from ADR-0041's
scope is removed as unreachable.

## Consequences

### Positive

- No TCC/`systemsetup` dependency at all: the only privileged commands are the
  four `pmset` writes that were verified working on the first real run.
- No deadline machinery — the failure mode that hung `off` cannot recur,
  because the code that caused it is gone rather than merely bounded.
- `off` stops mid-trip-proofing in the wrong direction: nothing re-breaks the
  next trip's setup.

### Negative

- A Mac with Remote Login off is diagnosed, not fixed: `on` exits `2` until
  the user makes the one System Settings click, so a fully hands-off setup is
  no longer promised.
- sshd stays on year-round. Accepted: it was never internet-reachable, and
  the pre-travel checklist still verifies it either way.

### Neutral

- The runbook keeps Remote Login as an explicit, manually verified checklist
  item, now matching the script's scope.

## See Also

- [ADR-0041](0041-toggle-laptop-and-vps-modes-with-mac-vps.md) — superseded
- [ADR-0033](0033-repo-scripts-in-bin-on-path.md) — `bin/` on `$PATH`
- `automations/docs/remote-ssh.md` — travel runbook (automations repo)
