# tui-ide-ADR-0043: Ensure Herdr integration and caffeinate Claude Code on macOS

**Status:** Accepted
**Date:** 2026-11-13
**Amends:** [ADR-0031](0031-retire-the-nono-sandbox.md) (its
"plain binaries on `$PATH`, no zsh wrapper" clause, for `claude` on macOS
only; the nono retirement itself stands)

## Context

Claude Code (`claude`) serves as an alternate agent surface alongside OpenCode
in Herdr multiplexer panes ([ADR-0007](0007-agent-surface-in-herdr-pane.md),
[ADR-0019](0019-merge-claude-user-settings.md)).

Two operational friction points existed across machines:

1. **Idle sleep during long turns:** On macOS, unattended long-running agent
   turns would pause or abort when the machine entered idle sleep.
   [ADR-0039](0039-caffeinate-the-opencode-tui.md) resolved this for OpenCode
   via a `caffeinate -i` zsh wrapper function, but `claude` remained an
   unwrapped binary susceptible to sleep interruptions.
2. **Herdr integration tracking:** Herdr tracks agent session state, turn
   indicators, and notifications via lifecycle hooks (`~/.claude/hooks/herdr-agent-state.sh`).
   This hook was previously installed manually with `herdr integration install claude`,
   meaning fresh setups or out-of-date hooks were not guaranteed across runs.

## Decision

1. **Caffeinate `claude` on macOS:**
   In `dotfiles/zsh/.config/zsh/tui-ide.zsh`, define a `claude` zsh function
   guarded to macOS with `caffeinate` and `claude` on `$PATH`. It wraps
   executions in `caffeinate -i "${commands[claude]}" "$@"`. Because `caffeinate`
   forks and execs the target binary in the parent process, the foreground
   process remains `claude` for Herdr's pane inspection, and the idle-sleep
   assertion releases as soon as Claude exits.

2. **Automate Herdr integration in `install.sh`:**
   In `install.sh`, automatically run `herdr integration install claude` and
   `herdr integration install opencode` whenever `herdr` and the respective agent
   CLIs are present.

3. **Check authentication status in `install.sh`:**
   At bootstrap, if `claude` is installed but unauthenticated (`claude auth status`
   fails), prompt the user with `claude auth login` in the "Next steps" section.

## Consequences

### Positive

- Claude Code sessions on macOS remain active without machine sleep pausing
  mid-turn.
- Herdr agent status hooks are automatically installed and kept up-to-date across
  all machines on `./install.sh`.
- Account authentication remains completely local and per-machine (Keychain and
  local tokens), supporting different accounts on corporate and personal machines
  without repository pollution.

### Negative

- Bypassing the interactive zsh shell (such as directly invoking the binary via
  another supervisor without sourcing the shell rc) runs unwrapped without
  caffeinate.

### Neutral

- Credentials and tokens are managed entirely by Claude Code's native mechanisms
  (`claude auth login`) and remain untracked.

## See Also

- [ADR-0019](0019-merge-claude-user-settings.md)
- [ADR-0031](0031-retire-the-nono-sandbox.md)
- [ADR-0039](0039-caffeinate-the-opencode-tui.md)
- [Architecture](../architecture.md)
