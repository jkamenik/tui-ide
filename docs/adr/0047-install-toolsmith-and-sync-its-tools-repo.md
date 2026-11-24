# tui-ide-ADR-0047: Install toolsmith and sync its tools repo between machines

**Status:** Accepted
**Date:** 2026-11-24

## Context

[toolsmith](https://github.com/prime-radiant-inc/toolsmith) is a Claude Code
plugin that stops agents writing throwaway helper scripts. Its `toolsmith`
subagent builds reusable tools in a git repo at `~/.local/share/toolsmith/tools`
and catalogs them, and working agents search that catalog before writing a
script. Tools built on one machine are only useful on another if the repo
travels with the user.

toolsmith requires that repo to have its own `.git`: `toolsmith-repo` checks
`.git` first so that a parent repo's `HEAD` never counts, and it commits into
the repo on every new tool. The tools therefore cannot be plain tracked files
inside this repo, and a submodule would need a pointer bump here after every
tool the subagent builds. toolsmith documents one supported way to keep the
repo elsewhere: make the fixed path a symlink to it.

## Decision

1. `install.sh` adds the `prime-radiant-inc/prime-radiant-marketplace`
   marketplace and installs `toolsmith@prime-radiant-marketplace` when `claude`
   is present, skipping each step that is already done.
2. The tools repo is a separate git repo, `jkamenik/toolsmith-tools`, cloned to
   `~/github.com/jkamenik/toolsmith-tools`. `TOOLSMITH_TOOLS_REPO` and
   `TOOLSMITH_TOOLS_DIR` override the remote and the clone location. This repo
   records only where it lives, not its contents.
3. `~/.local/share/toolsmith/tools` is a symlink to the clone. A real directory
   already at that path (a repo toolsmith made before this ran) is moved to the
   clone location, never deleted. If both exist, `install.sh` warns and leaves
   them for the user.
4. A re-run fast-forwards the clone when it has a remote and a clean tree.
   Clone, pull, and plugin failures only warn, so an offline machine or a
   remote that does not exist yet never stops the bootstrap. With no clone yet,
   an empty directory is enough: toolsmith runs `git init` there on first use.
5. The tracked zsh config puts `~/.local/share/toolsmith/tools/bin` on `$PATH`
   so the user can run the tools directly. Agents use absolute paths regardless.
6. Pushing is manual (`git -C ~/github.com/jkamenik/toolsmith-tools push`).
   toolsmith commits locally; nothing here pushes on its behalf.

## Consequences

### Positive

- A tool built on one machine reaches the others with a push and the next
  `install.sh` run, with no pointer to maintain in this repo.
- Machines that already ran toolsmith keep their existing tools.

### Negative

- The remote must be created once (`gh repo create jkamenik/toolsmith-tools
  --private`); until then each machine keeps a local-only repo.
- Tools are not versioned with this repo, so a machine can run older tools than
  another until it pulls.
- `install.sh` assumes the `~/github.com/jkamenik/` layout unless overridden.

### Neutral

- The toolsmith permission rules (`additionalDirectories` and
  `Bash(toolsmith-repo *)`) are not in the settings template. The
  [ADR-0019](0019-merge-claude-user-settings.md) merge replaces arrays rather
  than joining them, so a tracked `allow` list would erase a machine's own.
  Without them, default permission mode prompts on the toolsmith's commands.

## See Also

- [ADR-0019](0019-merge-claude-user-settings.md) — merged Claude Code settings
- [ADR-0033](0033-repo-scripts-in-bin-on-path.md) — scripts reach `$PATH`
  through shell config
