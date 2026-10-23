# tui-ide-ADR-0040: Create and open Git worktrees with `git-workspace`

**Status:** Accepted
**Date:** 2026-10-23

## Context

Managing Git worktrees across repositories requires coordinating multiple tools:
1. Creating or opening the Git worktree (`git worktree add`).
2. Registering and focusing the corresponding workspace tab in the Herdr terminal multiplexer.
3. Notifying OpenCode via its HTTP API (`/api/worktree/refresh`) so the worktree inventory in OpenCode stays synchronized without requiring manual refreshes or server restarts.

Doing these steps manually is error-prone, results in duplicate or orphaned Herdr workspaces, and leaves OpenCode unaware of newly created worktrees.

## Decision

Provide `bin/git-workspace` (exposed on `$PATH` via [ADR-0033](0033-repo-scripts-in-bin-on-path.md), and usable as `git workspace <branch> [base]`):

1. **Worktree Resolution & Creation:**
   - Detects the primary repository checkout root (`git rev-parse --git-common-dir`).
   - If the worktree or branch already exists, reuses it without creating duplicates.
   - If creating a new worktree, resolves the base branch (defaulting to the primary remote default branch) and creates the linked worktree.
2. **Herdr Workspace Integration:**
   - If Herdr is available, creates or opens the workspace tab (`herdr worktree create` / `herdr worktree open`) and focuses it unless `--no-focus` is passed.
3. **OpenCode Inventory Synchronization:**
   - Queries OpenCode's HTTP API (`/api/project`) to resolve the canonical project ID.
   - Posts a refresh request to `/api/worktree/refresh`, making the worktree immediately available to OpenCode sessions and pickers.

## Consequences

### Positive

- Single command (`git workspace <branch>`) handles the entire setup lifecycle: Git worktree, Herdr workspace tab, and OpenCode inventory synchronization.
- Idempotent: focusing an existing worktree switches to it cleanly instead of failing or creating duplicates.
- Pairs symmetrically with `bin/git-cleanup` ([ADR-0038](0038-remove-merged-worktrees-in-git-cleanup.md)) for the complete worktree lifecycle.

### Negative

- None.

### Neutral

- Falls back to pure Git worktree creation if Herdr or OpenCode is not running.

## See Also

- [ADR-0033](0033-repo-scripts-in-bin-on-path.md): Repo helper scripts in `bin/` on `$PATH`
- [ADR-0036](0036-stow-the-herdr-worktree-open-plugin.md): Stow the herdr worktree-open opencode plugin
- [ADR-0038](0038-remove-merged-worktrees-in-git-cleanup.md): Remove merged Git worktrees and Herdr workspaces in `git-cleanup`
- [Architecture](../architecture.md)
