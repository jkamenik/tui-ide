# tui-ide-ADR-0021: Derive the nono profile from observed session use

**Status:** Accepted
**Date:** 2026-09-28

## Context

[ADR-0020](0020-sandbox-agent-clis-with-nono.md) runs the agents under the
`nolabs-ai/opencode` registry pack. That pack is written for opencode in
general, so it grants what any opencode user might need and denies the rest.
Against this repo specifically, that is the wrong shape in both directions, and
neither direction is visible without looking at what the agent actually did.

The opencode session log answers the question directly. `~/.local/share/opencode/opencode.db`
records every tool call in a `part` table whose `data` is JSON, so the set of
files touched and the set of binaries invoked can be read out of SQLite instead
of guessed at. Across the six sessions in this repo (752 tool calls, 441 of them
`bash`), every resolved binary landed in `/usr/bin`, `/bin`, or `/opt/homebrew`
— all already allowed by the pack, which grants the system and Homebrew groups.
Not one executable hit a deny. By contrast seven directories the agent reached
for were denied outright:

| Path | Why the agent wanted it |
|------|-------------------------|
| `~/.config/nvim` | stowed config; a real directory of in-repo symlinks |
| `~/.config/herdr` | multiplexer config, log, and control sockets |
| `~/.config/iterm2` | preferences this repo tracks |
| `~/Library/Fonts` | font install by the editor plugin |
| `~/Library/LaunchAgents` | the multiplexer LaunchAgent |
| `~/bin` | user scripts (absent on this machine) |
| `~/github.com/jkamenik/second-brain` | sibling repo, one cross-repo read |

So the pack needed no help with executables and a specific, bounded amount of
help with directories. Those two facts have to be stated somewhere, because the
alternative at the moment of a denial is either the unsandboxed `-yolo` variant
or a grant nobody scoped.

## Decision

A tracked user profile, `tui-ide-agent`, extends `nolabs-ai/opencode` and adds
only the directories the session log shows in use. It lives in
`dotfiles/nono/.config/nono/profiles/` and is stowed like every other package,
so `install.sh` recreates it.

- Grants are expressed with `$XDG_CONFIG_HOME`, `$HOME`, and `platform_overrides`
  rather than absolute paths, so the tracked file is portable.
- `~/Library/Fonts` and `~/Library/LaunchAgents` are macOS-only and live under
  `platform_overrides.macos`, so a Linux workstation does not inherit a
  directory that does not exist there.
- `~/bin` is not granted. It does not exist here, and a grant for a directory
  that may never exist is a grant with no evidence behind it.
- `~/.gitconfig.local` is granted read. The tracked `~/.gitconfig` includes it,
  and the pack's `git_config` group grants only the tracked file, so the
  included overlay is the one path in the chain with no grant. Git aborts on an
  include it cannot read rather than continuing without it, so without this
  grant every `git` command in the sandbox fails on the include, not just the
  ones that read git configuration. The path is machine-specific by name but
  universal in practice: the tracked config always includes it, and a grant for
  a file that does not exist on a given machine is inert, so it belongs here
  rather than in the overlay.
- The sibling repo cannot be expressed portably, so it goes in a git-ignored
  `tui-ide-agent-local.json` that extends the tracked profile, per
  [ADR-0008](0008-local-overlay-for-sensitive-values.md). The wrapper prefers
  the overlay when the file exists, so machine-specific grants never need a
  repo change.

Every candidate was checked against the pack before being added, with
`nono why --path <path> --op read`. The pack's own `workdir` grant is not
applied by `why` unless the query is given the same context the wrapper passes,
so the query has to include `-a "$PWD"` to reproduce what a real launch sees.

## Consequences

### Positive

- The boundary stays narrow and every grant is traceable to observed use rather
  than to a guess about what an agent might want.
- The measurement is repeatable. The `part` table in opencode's database is the
  input, and `nono why` is the check, so the profile can be re-derived when the
  work changes rather than accumulating grants.
- The tracked file stays portable, and the one machine-specific path lives in an
  overlay the repo already has a convention for.
- A denied path has a documented remedy that is a one-line profile edit, instead
  of the unsandboxed variant.

### Negative

- A workflow that reaches outside these directories still fails, and still reads
  as a permission error. Fixing it is a profile edit or the `-yolo` variant.
- The grants are derived from six sessions in one repo. They are a floor, not a
  ceiling, and they are as incomplete as the sample.
- A grant outlives the need that justified it. Nothing expires a directory that
  a workflow has simply stopped using, so the profile drifts upward over time
  unless it is re-derived.

### Neutral

- Granting `~/.config/herdr` read+write also grants the multiplexer's control
  sockets, so the agent can drive panes. That is the capability this repo's
  sessions wanted, and it is a real one, not a side effect of a config path.
- `~/Library/LaunchAgents` lets a sandboxed agent write launchd agents, which is
  host-level persistence outside the repo.
- nono refuses a profile that grants its own state root, so an agent cannot
  inspect the audit log of the session it is running in, and `nono ps` from
  inside the sandbox is not available. That is nono's deliberate choice, not a
  gap in this profile.
- A denial raised during a **non-interactive** `nono run` can cause nono to
  write a suggested profile into `~/.config/nono/profiles/`, and the suggestion
  for an opencode path-resolution probe on `/Users` grants read on `/Users` and
  `~/`. Written unexamined, that file would defeat the boundary, and the name it
  takes (`opencode`) does not match any profile the wrappers select. The pack's
  `suppress_save_prompt` covers only its own package directory, so the prompt is
  not suppressed for paths outside it. The wrapper therefore passes
  `--suppress-save-prompt` for each ancestor of the workdir, computed the same
  way it computes the `$PATH` read grants. opencode resolves its own config by
  walking from the workdir to the filesystem root and is denied at every one of
  those ancestors, since a grant covers a directory but not the directories
  leading to it; only ancestors are listed, never the workdir's own children, so
  a genuinely new directory still prompts. A suggested grant for a directory no
  session asked for is the grant that should never be saved unattended.
  Anything else that appears in `~/.config/nono/profiles/` that this repo did
  not put there is worth reviewing before it is selected.

## See Also

- [ADR-0020](0020-sandbox-agent-clis-with-nono.md)
- [ADR-0008](0008-local-overlay-for-sensitive-values.md)
- [ADR-0016](0016-never-back-up-files-that-resolve-into-the-repo.md)
- [Architecture](../architecture.md)
