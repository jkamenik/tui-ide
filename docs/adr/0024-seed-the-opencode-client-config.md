# tui-ide-ADR-0024: Seed the opencode client config from a tracked example

**Status:** Accepted
**Date:** 2026-10-02
**Supersedes:** [ADR-0023](0023-seed-the-opencode-tui-config.md)

## Context

opencode 2 replaced the layered v1 terminal client config with one global file,
`~/.config/opencode/cli.json`, and moved the terminal client into a separate
process from the service. The client owns this file; the service never reads it.
`theme` also changed shape, from a bare name to `{ "name", "mode" }`.

On first v2 start the client migrates `~/.config/opencode/tui.json` and the
persisted preference store into `cli.json`. It does **not** read `tui.jsonc`.
ADR-0023 seeded `tui.jsonc`, so a machine set up from the tracked example went
through the v2 upgrade with no `cli.json` and no migration: the theme silently
reverted to opencode's default, which is exactly the drift ADR-0013 existed to
prevent. Nothing failed, so the mismatch with the tracked iTerm2 palette was
invisible.

The v1 file is now ignored by the client, so seeding it is worse than useless on
a v2 machine and misleading to read.

## Decision

`install.sh` copies `dotfiles/opencode/.config/opencode/cli.json.example` to
`~/.config/opencode/cli.json` when the destination does not exist, and says
where to edit it. The example carries `"theme": { "name": "system", "mode":
"system" }`, which is the v2 spelling of the v1 `"theme": "system"` the repo
has always tracked: opencode renders from the terminal palette, the same source
herdr uses.

The copy stays one-shot, a symlink is left alone and reported, and the tracked
`*.example` suffix keeps the template out of the live config path, all as
ADR-0023 established. Nothing is merged, because the client config is JSON and
the machine-local entries (the herdr session plugin path) are the user's to
write. `install.sh` prints the `plugins` spelling to use when they want that
plugin, since the example cannot carry a comment.

The v1 `tui.jsonc.example` is retired. An existing `tui.json` or `tui.jsonc` on
a machine is left on disk untouched, and `install.sh` prints a note naming the
one-time move into `cli.json`, because a v1 file that opencode no longer reads
is otherwise invisible.

## Consequences

### Positive

- A fresh v2 machine gets the terminal-palette theme with no manual step and no
  dependency on a migration that never ran.
- The repo no longer tracks a file opencode 2 ignores, so the example cannot
  drift into being wrong again without a version bump to notice.
- The note makes the one manual migration on an upgraded machine explicit.

### Negative

- An upgraded machine still needs the one-time move out of `tui.json(c)`;
  `install.sh` reports it but does not perform it, because rewriting a live
  config is not something a bootstrap should do silently.
- Changes to the example still do not reach machines that already have a
  `cli.json`, the same drift ADR-0008's overlay accepts.

### Neutral

- The tracked file keeps its `.example` suffix and `dotfiles/opencode/` stays a
  template directory rather than a stow package, so ADR-0023's reasoning about
  `~/.config/opencode` still applies unchanged.
- The agent config (`opencode.json`) remains machine-local and untracked.
  opencode 2 requires a custom provider to name its runtime package, where v1
  defaulted to the OpenAI-compatible SDK, so a v1 provider entry needs `"npm"`
  added or the `providers` spelling written out; that is a per-machine edit and
  the README says so.

## See Also

- [ADR-0023](0023-seed-the-opencode-tui-config.md)
- [ADR-0013](0013-apply-color-scheme-on-fresh-machine.md)
- [ADR-0019](0019-merge-claude-user-settings.md)
- [Architecture](../architecture.md)