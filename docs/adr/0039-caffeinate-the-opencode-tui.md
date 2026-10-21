# tui-ide-ADR-0039: Caffeinate the opencode TUI launch on macOS

**Status:** Accepted
**Date:** 2026-10-21
**Amends:** [ADR-0031](0031-retire-the-nono-sandbox.md) (its
"plain binaries on `$PATH`, no zsh wrapper" clause, for `opencode` on macOS
only; the nono retirement itself stands)

## Context

An idle-sleeping Mac stops a long agent turn mid-flight. The macOS sleep
assertion should live exactly as long as the opencode TUI does: while a TUI
is open the machine stays awake, and once the last one closes the machine
sleeps again on its normal schedule.

opencode 2.x splits into two process kinds with very different lifetimes
([ADR-0032](0032-track-the-opencode-2.x-line.md)): the interactive TUI, which
is the pane's foreground process, and the background service
(`opencode serve --service`), which detaches to `ppid 1` and outlives every
TUI. An assertion held for the service would keep the machine awake forever,
so the wrapper must cover only the TUI.

`caffeinate -i <command>` turns out to fit the [ADR-0031](0031-retire-the-nono-sandbox.md)
constraint rather than violate it. Its source
(`apple-oss-distributions/PowerManagement/caffeinate.c`) forks and then
`execvp`s the command **in the parent**, flipping the usual relationship: the
shell's job keeps its pid but becomes the `opencode` image, so the pane's
foreground process is still `opencode` and herdr labels it without a hint —
the opposite of `nono run`, which supervised instead of exec'ing and hid the
agent. A small watcher child owns the IOKit assertion, ignores `SIGINT` and
`SIGQUIT` (so Ctrl-C reaches the TUI, not the watcher), and exits when its
parent does, including on crash or `SIGKILL`. The assertion is per-process
and not inherited, so a detached `opencode serve --service` that survives the
TUI holds no sleep power at all. Verified on this machine: the assertion
appears as `caffeinate asserting on behalf of '<utility>'` while the wrapped
process runs and disappears the instant it exits.

## Decision

Define an `opencode` zsh function in `dotfiles/zsh/.config/zsh/tui-ide.zsh`,
guarded to macOS with `caffeinate` and an `opencode` binary on `$PATH` (so
Linux and unprovisioned machines see nothing). The function wraps the TUI
launch — a bare invocation, a flag first argument, or an existing directory
argument — in `caffeinate -i "${commands[opencode]}" "$@"`. Any other first
argument is treated as a subcommand and execs the plain binary, so server-ish
paths (`serve`, `service`, `acp`, `run`, ...) can never end up under
caffeinate. `${commands[opencode]}` resolves the real binary path and avoids
recursing into the function itself.

`-i` (prevent *idle* system sleep) is the chosen flag: the display and the
lid-close behavior keep their normal power policy. `-s` would additionally
hold AC sleep, and `-d` would force the display on forever; neither is wanted
for a TUI that nobody is required to watch.

## Consequences

### Positive

- The Mac stays awake while a TUI is open, on every macOS machine at the next
  `./install.sh`, with no per-machine step.
- Multiple panes stack: each TUI gets its own assertion, and the machine
  sleeps when the last TUI exits.
- A crashed or killed TUI releases the assertion immediately; the watcher
  cannot orphan.
- herdr's foreground-process labeling is untouched: the exec'd job is still
  named `opencode`.

### Negative

- `opencode <dir>` on a not-yet-existing directory, and `opencode mini`, are
  not recognized as TUI launches and run without the assertion; the first
  almost never occurs, the second is a small deliberate gap in a strict
  "TUI only" reading.
- Agent launches that bypass an interactive shell (e.g. herdr exec'ing
  `opencode` directly in a pane) are not caffeinated, because the function
  only exists in shells that source the tracked rc.
- The watcher shares the pane's foreground process group, so a `ps` listing
  of the pane shows an extra `caffeinate` beside `opencode` until the TUI
  exits.

### Neutral

- ADR-0031's "no zsh wrapper" clause is amended, not reversed: it was about
  hiding the agent from herdr (and about nono), and the exec-flip design
  keeps `opencode` visible as the foreground process.
- A hand-typed bare `caffeinate` (no command) still asserts forever; that
  footgun is upstream, and `pmset -g assertions` names it plainly.

## See Also

- [ADR-0031](0031-retire-the-nono-sandbox.md)
- [ADR-0032](0032-track-the-opencode-2.x-line.md)
- [ADR-0034](0034-machine-owned-zshrc-sources-tracked-config.md)
- [Architecture](../architecture.md)
