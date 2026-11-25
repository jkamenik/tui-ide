# tui-ide-ADR-0049: Stow the global Claude Code CLAUDE.md and a toolsmith nudge hook

**Status:** Accepted
**Date:** 2026-11-25

## Context

[ADR-0047](0047-install-toolsmith-and-sync-its-tools-repo.md) installs the
toolsmith plugin, which tells agents not to write throwaway helper scripts. In
practice the instruction fades. The plugin's SessionStart hook states it once, at
the start of a session, so in a long session or after compaction it is far back
or gone. A system prompt that suggests putting scripts in a scratch directory
works against it. Agents then write multi-line heredocs, `perl -e` programs and
polling loops themselves, which is the behavior toolsmith exists to stop.

Two pieces of Claude Code configuration can carry the rule, and neither is
tracked here:

- `~/.claude/CLAUDE.md` is the user-level instruction file, re-read on every
  session and kept through compaction. It exists on one machine only, written by
  hand. It already holds the herdr worktree rules, which have no history and no
  way to reach a second machine, the same gap
  [ADR-0030](0030-stow-the-global-opencode-agents-md.md) closed for opencode.
- A `PreToolUse` hook can check a tool call at the moment it is made.
  [ADR-0019](0019-merge-claude-user-settings.md) keeps `hooks` out of the settings
  template because iTerm2 and herdr write machine-specific entries there, and its
  `jq` merge replaces arrays. A tracked `hooks.PreToolUse` would therefore erase
  the iTerm2 `cc-status` entry that is already in that array.

## Decision

1. **Stow the global `CLAUDE.md`.** Track it at
   `dotfiles/claude-md/.claude/CLAUDE.md` and add `claude-md` to `DOTFILES`. It is
   portable prose with no machine-local values, so a link is right and the repo
   is the one source of truth. A machine with a real `CLAUDE.md` is handled by the
   existing stow loop: backed up to `~/.dotfiles-backup/<timestamp>/`, then
   replaced by the link. The tracked file carries the worktree rules unchanged and
   a new section: helper scripts go to the toolsmith, scratch holds data only, and
   scripts that ship in a project's own repo are mission work.
2. **Stow a nudge hook script.** Track it at
   `dotfiles/claude-hooks/.claude/hooks/toolsmith-nudge.sh` and add `claude-hooks`
   to `DOTFILES`. It reads the tool call from stdin and, for a Bash command or a
   Write that looks like a helper script, prints an `additionalContext` message
   the model reads. **It only warns.** It always exits 0 and never sets a
   permission decision, so the call proceeds through the normal permission flow.
   It flags a heredoc (except for commit and PR text), an inline interpreter
   program over 5 lines or 300 characters, a shell loop in a command over 5 lines,
   and a script file written to a scratch directory. `TOOLSMITH_NUDGE=0` turns it
   off.
3. **Register the hook by appending, not merging.** `install.sh` adds a
   `PreToolUse` entry (`Bash|Write`) to `~/.claude/settings.json` only when the
   command is not already there, using `jq` to append to the array. The existing
   hooks stay. The previous file is backed up first, a symlinked settings file is
   left alone, and the command uses `~` so the file holds no machine-specific
   path.

## Consequences

### Positive

- The rule travels with the repo and survives compaction, because `CLAUDE.md` is
  re-read each session. The hook checks at the moment a script is about to be
  written, which the session-start message cannot.
- The worktree rules gain history and reach a second machine.
- The hook never blocks, so a false positive costs one line of context.
- Re-running `install.sh` is idempotent and keeps the iTerm2 and herdr hooks.

### Negative

- The detection is heuristic. It will warn on a legitimate project script written
  through a heredoc and miss a script built from piped one-liners. The message
  says mission work is exempt so the model can proceed.
- `install.sh` now edits `settings.json` in a second place, next to the template
  merge. That stays separate because the merge cannot append.
- A link to `CLAUDE.md` means a tool that rewrites the file by replacing it (not
  editing in place) turns the link into a real file; the next run backs it up and
  re-links.
- `additionalContext` on `PreToolUse` without a permission decision is not
  explicitly documented, and the hooks reference names no minimum version. It was
  confirmed in a live session on Claude Code 2.1.323: the model received the
  message and the tool call ran. A later version could change that.

### Neutral

- Skipping `jq`, or a settings file that is a symlink, leaves the hook
  unregistered with a message; `CLAUDE.md` still applies.

## See Also

- [ADR-0019](0019-merge-claude-user-settings.md) — settings template and merge
- [ADR-0030](0030-stow-the-global-opencode-agents-md.md) — the same pattern for
  opencode's global `AGENTS.md`
- [ADR-0045](0045-stow-a-claude-code-status-line.md) — a stowed Claude script
- [ADR-0047](0047-install-toolsmith-and-sync-its-tools-repo.md) — toolsmith install
