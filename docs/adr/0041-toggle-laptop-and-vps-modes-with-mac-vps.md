# tui-ide-ADR-0041: Toggle laptop and VPS modes with `mac-vps`

**Status:** Accepted
**Date:** 2026-10-25

## Context

The MacBook Pro doubles as a tailnet target: while traveling, John ssh's into
it over Tailscale to do Second Brain work (runbook:
`automations/docs/remote-ssh.md` in the automations repo). Reachability needs
two changes from its normal laptop state — never-sleep `pmset` values and
Remote Login listening on `:22` — and an exact revert on return. Both live as
raw commands in a runbook in another repo, so applying them means copying
commands, and the revert drifts from the stock snapshot if a value is missed.

## Decision

Provide `bin/mac-vps [on|off|status]` (on `$PATH` through
[ADR-0033](0033-repo-scripts-in-bin-on-path.md)), macOS-only:

1. **`status` (default):** report the `pmset` settings that `on`/`off` own, the
   current power source, whether Remote Login is listening on `:22`, the
   Tailscale self entry, and the `ks-laptop-key` fingerprint in
   `authorized_keys`. It changes nothing and exits `0` in VPS mode, `1` in
   laptop mode, `2` when the two halves disagree (e.g. asleep with Remote Login
   on).
2. **`on`:** apply the never-sleep `pmset` block (`sleep 0`, `disablesleep 1`,
   `standby 0`, `womp 1`, `tcpkeepalive 1`, `displaysleep 10`) and ensure
   Remote Login is listening. The Remote Login change is verified against the
   port, not the command's word: `systemsetup` first, `launchctl load -w` on
   the `ssh.plist` as fallback, then a System Settings instruction if both are
   blocked (TCC).
3. **`off`:** restore the 2026-10-25 stock snapshot — exactly the settings
   `on` writes, with their per-power-source defaults — and turn Remote Login
   off. It refuses to disable Remote Login from inside an SSH session
   (`$SSH_CONNECTION`), since that would sever the session it runs in.

Both toggles are idempotent and skip the `sudo` prompt when a half is already
set, so `mac-vps` alone is a reliable "can I reach it?" check with no
privileges needed.

## Consequences

### Positive

- One command each way before leaving and on return; the revert cannot drift
  because `on` and `off` own the complete set of settings between them.
- `status` answers the reachability question (power + `:22` + tailnet + key) in
  one place, and its exit code is scriptable.
- Toggling Remote Login is verified against the real port, so a silent TCC
  failure cannot leave the machine in a state that contradicts its reported
  mode.

### Negative

- macOS-only (`pmset`, `systemsetup`); on Linux the script exits with a clear
  error rather than degrading.
- The stock values are this Mac's snapshot, not a portable default — a
  different Mac should re-derive them from its own `pmset -g custom`.
- `off` disables Remote Login, so the next trip starts with `mac-vps on`
  (that is the point, but it is a two-command cycle, not a one-time setup).

### Neutral

- The runbook keeps the raw commands, so the procedure stays usable when the
  script or this repo is unavailable.
- Complements [ADR-0039](0039-caffeinate-the-opencode-tui.md): that keeps the
  Mac awake for the duration of an opencode TUI session; `mac-vps` is a
  persistent, machine-wide mode for remote access.

## See Also

- [ADR-0033](0033-repo-scripts-in-bin-on-path.md) — `bin/` on `$PATH`
- [ADR-0039](0039-caffeinate-the-opencode-tui.md) — session-scoped caffeinate
- `automations/docs/remote-ssh.md` — travel runbook (automations repo)
