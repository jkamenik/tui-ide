# tui-ide-ADR-0038: Remove merged Git worktrees and Herdr workspaces in git-cleanup

**Status:** Accepted
**Date:** 2026-10-20

## Context

`bin/git-cleanup` brings a Git checkout back in sync with its remote and deletes
local branches whose upstream is gone. When repositories use Git worktrees, two
issues arise:

1. Git rejects deleting a branch that is currently checked out in a linked
   worktree (`error: cannot delete branch '<branch>' used by worktree at '...'`),
   so stale branches left in worktrees cause branch pruning to fail.
2. If a worktree was opened as a workspace in Herdr, removing the worktree
   directory with `git worktree remove` leaves a stale workspace in Herdr's
   sidebar.

Git has no post-worktree removal hook to notify multiplexers or external tools.
However, Herdr provides CLI and socket control: `herdr worktree list` maps
worktrees to open workspace IDs, and `herdr worktree remove --workspace <id>`
both closes the Herdr workspace and removes the Git worktree checkout.

## Decision

Update `bin/git-cleanup` to inspect and prune linked Git worktrees before local
branch cleanup:

1. **Safety gates:**
   - Refuse to run from inside a linked worktree; cleanup must run from the
     primary checkout.
   - For every linked worktree, verify `git -C <path> status --porcelain`. Skip
     any worktree with uncommitted changes (staged, unstaged, or untracked) to
     prevent data loss.

2. **Merged check:**
   A worktree is eligible for removal if its branch (or detached HEAD commit)
   is an ancestor of the target branch (`git merge-base --is-ancestor`), or if
   its remote-tracking branch is `[gone]`.

3. **Herdr-aware removal:**
   - If `herdr` and `jq` are available, query `herdr worktree list --cwd <root>`.
   - If the worktree has an active Herdr workspace, remove it via
     `herdr worktree remove --workspace <workspace_id>`, which closes the Herdr
     workspace and deletes the Git worktree.
   - If Herdr is not running or the worktree has no open Herdr workspace, remove
     it with `git worktree remove <path>`.

4. **Branch pruning:**
   Delete branches whose upstream is gone or that are fully merged into the target.
   Skip any branch still checked out in an active (e.g. dirty) linked worktree.

## Consequences

### Positive

- Merged PR worktrees are cleaned up automatically without leaving stale
  directories on disk or ghost workspaces in Herdr's sidebar.
- Git no longer blocks deleting branches checked out in merged worktrees.
- Uncommitted changes in dirty worktrees and active branches are safely preserved.
- Works seamlessly whether Herdr is running or not.

### Negative

- None.

### Neutral

- Querying Herdr workspace IDs requires `jq`; if `jq` or `herdr` is missing,
  worktree removal cleanly falls back to standard `git worktree remove`.

## See Also

- [ADR-0033](0033-repo-scripts-in-bin-on-path.md)
- [ADR-0036](0036-stow-the-herdr-worktree-open-plugin.md)
- [Architecture](../architecture.md)
