# tui-ide-ADR-0022: Label the sandboxed agent for herdr with `HERDR_AGENT`

**Status:** Accepted
**Date:** 2026-09-28

## Context

[ADR-0020](0020-sandbox-agent-clis-with-nono.md) made `nono run` a supervisor in
the agent's process tree, which it needs to be for credential injection and
rollback. It therefore does not `exec`: the pane's foreground process becomes
`nono`, and the real agent is a child of it.

That breaks herdr, which identifies an agent in a pane from the pane's
foreground process. With the agent hidden behind a host-visible wrapper, it
dropped out of the agents view and stopped raising notifications — the two
symptoms had one cause. `herdr agent explain` on the affected pane confirmed
there was no visible state to show, and `herdr agent list` showed the sibling
pane, running the same binary unsandboxed, reporting normally.

The socket was never the problem. The integration plugin reaches herdr over
`HERDR_SOCKET_PATH`, that variable is inherited into the sandbox, and a
JSON-RPC `pane.report_agent` sent from inside a sandboxed process is answered
`{"type":"ok"}`. Detection is what reads the process, and detection is what the
wrapper broke.

herdr documents this case directly, in "VMs and sandbox wrappers": a
host-visible wrapper can hide the real agent, and `HERDR_AGENT=<agent>` set on
the wrapper command tells herdr which agent screen manifest to use. Its example
is this exact invocation, `HERDR_AGENT=claude nono run --profile claude-code -- claude`.

## Decision

The wrapper sets `HERDR_AGENT` as a prefix assignment on the `nono run`
invocation, so the value is present in the environment of the `nono` process —
the one herdr can see — and in its children.

- It is set on the command, never exported. herdr reads the hint from the
  foreground process it already tracks, and an export would label every
  inherited process, including the shell.
- Both agent binaries are named after their herdr agent label, so the wrapper
  passes the agent name through as the hint and needs no second table.

## Consequences

### Positive

- The agents view and notifications work again for sandboxed sessions, which is
  the state [ADR-0007](0007-agent-surface-in-herdr-pane.md) depends on. An agent
  that is invisible in herdr is one whose state cannot be rolled up, waited on,
  or attached to.
- One line in one function covers both agents and stays correct if either is
  renamed to match its label, which is the convention that makes the derivation
  work.
- The hint grants the agent nothing. It is a label herdr trusts, not a
  capability, so it cannot widen the sandbox.
- The value is scoped to the wrapper process, so nothing else in the session
  inherits it.

### Negative

- herdr trusts the hint, so a wrapper that passes the wrong agent name produces
  a confidently mislabelled pane rather than an obvious failure. The mapping is
  therefore the binary name, which is checkable by reading the function.
- The hint does nothing outside herdr. A sandboxed agent run in a plain terminal
  gains no visibility, and there is no diagnostic to look at there.

### Neutral

- This restores the pre-nono detection behaviour; it does not improve it. The
  agent is still identified by a declared label rather than an observed
  foreground process.
- A label cannot be applied from inside a VM or container, because herdr cannot
  see a process it did not start. That limitation is herdr's and is unchanged
  here; it is worth knowing before reaching for this variable as a general fix.
- The fix is independent of the profile. A profile that denied the herdr socket
  would break the plugin's reports as well, and `HERDR_AGENT` would not help;
  that path needs the socket granted instead, which
  [ADR-0021](0021-derive-nono-profile-from-observed-use.md) does.

## See Also

- [ADR-0020](0020-sandbox-agent-clis-with-nono.md)
- [ADR-0021](0021-derive-nono-profile-from-observed-use.md)
- [ADR-0007](0007-agent-surface-in-herdr-pane.md)
- [ADR-0004](0004-herdr-as-multiplexer.md)
- [Architecture](../architecture.md)
