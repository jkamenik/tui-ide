# tui-ide-ADR-0006: mosh over Tailscale, OpenSSH for files

**Status:** Accepted
**Date:** 2026-09-16

## Context

Clients reach an always-on host from laptops and a phone across networks that may change or drop. Plain SSH drops the session when the network changes. A private network is also needed so the host is never publicly exposed. Candidates: plain SSH, SSH with autossh, mosh, and Tailscale.

## Decision

We will use mosh for interactive sessions over a Tailscale tailnet. OpenSSH remains for file transfer and one-off commands where mosh does not apply. The host keeps a single ingress rule for UDP 41641 behind `allow_tailscale_direct`.

## Consequences

### Positive

- Sessions survive network changes and roaming, which matters on mobile.
- Tailscale removes the need for a public SSH port.
- One narrow ingress rule keeps the host's network exposure minimal.

### Negative

- mosh needs UDP, so some restrictive networks block it and fall back to SSH.
- Tailscale must be installed and joined on every client, including the phone.

### Neutral

- OpenSSH stays installed regardless, since mosh bootstraps over it.

## See Also

- [Architecture](../architecture.md)
- [ADR-0003](0003-terminal-clients-iterm2-and-moshi.md)
