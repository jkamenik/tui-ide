# tui-ide-ADR-0031: Retire the nono agent sandbox

**Status:** Accepted, amended by [ADR-0039](0039-caffeinate-the-opencode-tui.md)
**Date:** 2026-10-12
**Supersedes:** [ADR-0020](0020-sandbox-agent-clis-with-nono.md),
[ADR-0021](0021-derive-nono-profile-from-observed-use.md),
[ADR-0022](0022-label-sandboxed-agent-for-herdr.md),
[ADR-0027](0027-pin-the-opencode-nono-pack-to-0.2.0.md), and
[ADR-0028](0028-pre-create-opencode-state-dirs-at-bootstrap.md)

## Context

[ADR-0020](0020-sandbox-agent-clis-with-nono.md) put `opencode` and `claude`
under nono so the kernel enforced a default-deny filesystem boundary around the
agents. Keeping that boundary working then generated four more decisions:
[ADR-0021](0021-derive-nono-profile-from-observed-use.md) made the tracked
profile a derived artifact re-read from the session database every time a path
came up denied,
[ADR-0022](0022-label-sandboxed-agent-for-herdr.md) added a `HERDR_AGENT` hint
because `nono run` supervises rather than execs and herdr could no longer see
the agent, [ADR-0027](0027-pin-the-opencode-nono-pack-to-0.2.0.md) pinned the
capability pack because a pack upgrade appended a v2-only flag the pinned v1
binary rejects, and
[ADR-0028](0028-pre-create-opencode-state-dirs-at-bootstrap.md) pre-created six
state directories at bootstrap because an upstream pack ships its own fix
unwired. The wrapper itself carries `--read` grants for every `$PATH` entry
under `$HOME` and a `--suppress-save-prompt` list spanning every ancestor of
the workdir just to start without a post-exit review.

The boundary's value was keeping `~/.ssh`, `~/.aws`, `~/.config/gcloud`,
`~/.config/gh`, and the shell configs away from the agents. The cost was a
second version pin coupled to the opencode formula pin
([ADR-0025](0025-pin-opencode-to-the-1.x-line.md)) so lifting either one alone
reintroduces a launch failure, recurring denial triage, and bootstrap
scaffolding that duplicates a list the pack was supposed to own. The user
judged that trade no longer worth taking on this workstation, whose agents act
under the same account that owns the credentials anyway.

## Decision

Remove nono from the toolchain:

- `Brewfile` drops `brew "nono"`; `install.sh` drops the apt release-`.deb`
  fallback, the pack pull, and the pack pin.
- `dotfiles/nono` is deleted, tracked profile and overlay example with it.
- The `nono_agent` zsh wrapper and the `opencode-yolo` / `claude-yolo` variants
  are deleted. `opencode` and `claude` are the plain binaries on `$PATH`.
- The six `mkdir -p` state directories ADR-0028 added are dropped: opencode
  creates its own state when nothing denies the `mkdir`.
- No `HERDR_AGENT` hint is needed: the agent is again the pane's foreground
  process, which is what herdr reads.

Claude Code's own sandbox stays off in the tracked settings template
([ADR-0019](0019-merge-claude-user-settings.md)); that is unchanged, but it now
means no layer bounds the `claude` process either.

Machines provisioned before this change are cleaned by
`uninstall-nono-supacode.sh` at the repo root: uninstall the package, move
nono's and Supacode's real state into `~/.dotfiles-backup/` before deleting it,
drop the Supacode opencode plugin and skills, and say what a non-managed
leftover needs. It is idempotent, so a re-run is a no-op, and it is
transitional: once every machine has run it, the script itself can be deleted.

## Consequences

### Positive

- The opencode 2.x upgrade is one change again: lifting the formula pin no
  longer has to be coordinated with lifting a pack pin, ADR-0027's coupling
  goes away, and the `--standalone` flag that broke v1 launches is no longer in
  the launch command at all.
- Agents start directly: no wrapper flags, no denial reviews, no first-run
  directory ordering, and herdr labels them from the process itself.
- `install.sh` loses a network dependency (the pack registry) and a machine
  state (`nono pin`) that no other part of the repo could observe.

### Negative

- Agents run with the full access of the user account: every credential store
  ADR-0020 denied is reachable, and the safety argument for `-yolo` becoming
  the default quietly becomes the actual state.
- The derived grants in `tui-ide-agent` are retired, so re-adopting any
  boundary starts from re-derivation, not from a kept profile.

### Neutral

- The boundary remains re-adoptable upstream: nono's packs continue to evolve
  for opencode v2 isolation, and nothing here now assumes the wrapper exists.
- Supacode was never provisioned by this repo — the app installed its own CLI
  link, opencode plugin, and skills — so its removal is cleanup, not a
  decision, and rides in the same transitional script.

## See Also

- [ADR-0020](0020-sandbox-agent-clis-with-nono.md)
- [ADR-0025](0025-pin-opencode-to-the-1.x-line.md)
- [ADR-0019](0019-merge-claude-user-settings.md)
- [Architecture](../architecture.md)
