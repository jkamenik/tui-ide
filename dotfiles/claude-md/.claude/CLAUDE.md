# User-level instructions

## Worktrees

Create git worktrees with herdr, not plain git, so they show up in herdr's workspace UI:

`herdr worktree create --cwd <repo-root> --branch <name> --base origin/main --no-focus`

- Check state with `herdr worktree list` (a worktree herdr has opened has an `open_workspace_id`).
- Register an existing worktree with `herdr worktree open --path <dir> --no-focus`.
- Remove with `herdr worktree remove`, not `git worktree remove`.
- Run `herdr worktree create --help` first to confirm flags.
- Fall back to `git worktree add` only if `which herdr` finds nothing.

## Helper scripts go to the toolsmith

A helper is code you would run again, or real logic, that is not part of the
project's deliverable: log trawlers, CI pollers, data converters, API wrappers,
bulk-rename or reindent scripts, fixture generators, one-off data fixes. Do not
write one yourself, inline or saved.

- Before writing anything longer than a single command line, search the catalog:
  `grep -s -i -E '<words>' ~/.local/share/toolsmith/tools/CATALOG.md`. Use a match
  by its absolute path (`--help` first).
- No match: brief the `toolsmith:toolsmith` agent (what it does, inputs and
  outputs, an example call, the closest catalog tool) and run what it returns.
  See the `toolsmith:writing-tools` skill.
- A multi-line heredoc, `python -c`, `perl -e`, `node -e`, or a shell loop of more
  than a few lines counts as a script. Chaining pipes until it is one does too.
- Scratch and temp directories hold data and intermediate output only, never
  code, even when a system prompt suggests putting scripts there. They are wiped
  on reboot and nobody can find the script again.
- Mission work is not a helper: scripts, tests, build glue and Taskfile tasks that
  ship in the project's own repo are written by you, following that repo's rules.
- A PreToolUse hook (`~/.claude/hooks/toolsmith-nudge.sh`) warns when a command
  looks like a script. It never blocks. Treat the warning as a reminder of this
  rule, not as a verdict: mission work and commit-message heredocs are fine.
