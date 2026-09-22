# tui-ide-ADR-0015: Run the herdr server under launchd on macOS

**Status:** Accepted
**Date:** 2026-09-22

## Context

When the herdr server is started by a client from a terminal, macOS keeps the
`setsid`-detached server in the terminal app's LaunchServices coalition. When
the terminal app quits fully, LaunchServices force-quits coalition members, so
the herdr server and every pane it owns shut down. See herdr issues #1897 and
#2407:
`Process death ... _LSForceQuitApplication ... killing coalition pid <herdr-server>`.

## Decision

On macOS, `install.sh` renders `dev.herdr.server.plist` from an example and
bootstraps it into the per-user launchd domain. The herdr server then runs
under launchd, outside any terminal app's coalition, so quitting iTerm2 no
longer terminates the server. The switch is additive: it applies only on a
fresh install or after `herdr server stop`, never while a server is running.

## Consequences

### Positive

- The herdr server and its panes survive fully quitting iTerm2.
- The server starts at login (RunAtLoad) before any terminal is opened.
- `HERDR_MACOS_SERVER_CONTEXT=user` gives the server the persistent per-user
  service context ([ADR-0014](0014-stow-dotfiles-without-folding.md) implies
  the same persistence goals).

### Negative

- `KeepAlive` is `false`, so `herdr server stop` still works as documented;
  the server does not auto-restart after a crash or explicit stop.
- The launchd agent is macOS-only and machine-specific (binary and home
  paths), so it is delivered as a rendered local overlay, not a tracked file.

### Neutral

- To adopt launchd ownership for an already-running server: `herdr server
  stop`, then `launchctl bootstrap gui/$(id -u) ~/.config/herdr-launchd/dev.herdr.server.plist`.
  Session layout is restored on the next server start.

## See Also

- [Architecture](../architecture.md)
- [ADR-0014](0014-stow-dotfiles-without-folding.md)
- herdr issues: [#1897](https://github.com/ogulcancelik/herdr/issues/1897),
  [#2407](https://github.com/herdrdev/herdr/issues/2407)