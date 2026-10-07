# tui-ide-ADR-0028: Pre-create opencode's state directories at bootstrap

**Status:** Accepted
**Date:** 2026-10-06

## Context

[ADR-0020](0020-sandbox-agent-clis-with-nono.md) runs `opencode` under
`nono run --profile tui-ide-agent`, and that profile extends the
`nolabs-ai/opencode` pack, whose `filesystem.allow` list names six opencode
state directories: `~/.opencode`, `~/.config/opencode`, `~/.cache/opencode`,
`~/.local/share/opencode`, `~/.local/share/opentui`, and
`~/.local/state/opencode`.

nono resolves `filesystem.allow` against the filesystem as it stands when the
sandbox is built, so a path that does not exist yet produces no grant. On a
fresh machine none of the six exist, all six are dropped from the capability
set, and the first sandboxed launch fails:

```
Error: Unexpected error
AlreadyExists: FileSystem.makeDirectory (/Users/.../.opencode)
```

The failure is confusing twice over. opencode cannot stat the directory it was
never granted, assumes it is absent, and calls `mkdir` on a copy that appeared
during the session after the grant was resolved, so the error is `AlreadyExists`
rather than a permission failure — nono reports `No path denials were observed`.
The run also leaves `~/.opencode` behind, so the *next* launch succeeds and the
bug never reproduces on a second try. `opencode debug config` works outside the
sandbox, which makes it look like a profile problem rather than an ordering one.

The `nolabs-ai/opencode` pack already carries the fix for this:
`bin/ensure-dirs.sh` pre-creates exactly those six directories and its header
identifies it as a `session_hooks.before` script. It does not run, because the
pack's `package.json` declares it under `artifacts` with `"type": "plugin"` and
never lists it in `wiring`. Nothing outside the pack can rewire it: the
capability set is upstream and signature-verified, so this repo does not edit
pack files, and the defect stays upstream until the pack ships its own fix.

## Decision

`install.sh` creates the six opencode state directories with `mkdir -p` before
it seeds anything else opencode-related, and reports only the directories it
actually created. It runs inside the existing `have opencode` guard, so a
machine without opencode does nothing.

The directories are not stowed: they hold machine-generated state
(`node_modules`, caches, session data), and a tracked link would put a write
into the repo tree, which [ADR-0014](0014-stow-dotfiles-without-folding.md)
exists to prevent. Creating them is idempotent and costs nothing on a machine
where opencode has already run.

## Consequences

### Positive

- A fresh machine launches sandboxed `opencode` on the first try instead of
  dying once and healing on the second.
- The fix lives where the rest of bootstrap lives, so it is covered by
  `install.sh`'s existing backup and idempotency guarantees.
- The six paths are named once, next to the pack pin that declares them, so a
  pack profile change is visible in the same place it has to be mirrored.

### Negative

- The repo now duplicates a list the pack was supposed to own, so a future
  change to the pack's `filesystem.allow` must be copied here by hand or the
  first-run failure returns silently.
- The underlying defect is upstream in the pack's `wiring`, and in nono's
  resolve-then-create ordering; this papers over it rather than fixing it.

### Neutral

- The pack's `bin/ensure-dirs.sh` remains dead weight. It is still listed in
  `artifacts`, hashed in the lockfile, and never executed.
- The step stays correct if a later pack fixes its own wiring: `mkdir -p` is a
  no-op on directories that already exist, so the local step then does nothing
  instead of conflicting with the pack's.

## See Also

- [ADR-0014](0014-stow-dotfiles-without-folding.md)
- [ADR-0020](0020-sandbox-agent-clis-with-nono.md)
