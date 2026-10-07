# tui-ide-ADR-0029: go-task as the task runner

**Status:** Accepted
**Date:** 2026-10-07

## Context

Projects in this environment need a way to declare and run repeatable tasks
(build, test, lint). The candidates are the tools already close at hand:

- `make` is preinstalled everywhere, but the semantics that make it usable as a
  task runner (`.PHONY`, shell selection, dependency ordering) are the ones it
  is worst at, and it is not the same tool across platforms.
- `npm run` is only available in Node projects and couples the task definitions
  to a package manifest.
- A shell script per task has no dependency graph, no change detection, and no
  shared invocation surface.

[Task](https://taskfile.dev) (the `go-task` formula) declares tasks in a
`Taskfile.yml`, is a single static Go binary, and runs identically on macOS and
Linux.

## Decision

Add `go-task` to the shared `Brewfile`, so it installs on both macOS and
Linuxbrew like the rest of the toolchain
([ADR-0002](0002-homebrew-bundle-and-gnu-stow.md)). It is verified with
`task --version`.

Task is a general developer tool, not a build step for this repo, so nothing
in `install.sh` invokes it and no Taskfile is tracked here.

## Consequences

### Positive

- Task definitions are portable between macOS and Linux and between projects,
  with no per-language runner.
- One more formula in the existing `brew bundle` step; no new provisioning
  mechanism.

### Negative

- `go-task` conflicts with the `task` formula (taskwarrior), because both
  install a `task` binary. A machine that wants both must choose which one owns
  the name.

### Neutral

- The repo gains a tool but no tracked configuration; a Taskfile is a
  per-project artifact.

## See Also

- [ADR-0002](0002-homebrew-bundle-and-gnu-stow.md)
