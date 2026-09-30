# tui-ide-ADR-0020: Sandbox the agent CLIs with nono

**Status:** Accepted
**Date:** 2026-09-28

## Context

This repo runs two coding agents, opencode (the primary surface, per
[ADR-0007](0007-agent-surface-in-herdr-pane.md)) and Claude Code (the alternate).
Both read the codebase, write files, and run arbitrary commands with the
credentials and filesystem of the user who launched them. Nothing in the stack
bounds what they can reach: the zsh dotfiles put the developer's own `$PATH`,
`$HOME`, SSH agent, and cloud credentials in scope, and an agent acts on
whatever the prompt, a dependency, or a file in the repository tells it to.

The boundary has to be one the agent cannot argue its way past. Application-level
controls do not qualify — a permission prompt is a request the agent can
re-issue. Claude Code's own sandbox is application-level and Anthropic
documents an intentional escape hatch in it: when a command fails because of a
sandbox restriction, Claude may retry the same command with
`dangerouslyDisableSandbox` and take the ordinary permission flow instead.

nono applies a default-deny filesystem allow-list in the kernel instead —
Landlock on Linux, Seatbelt on macOS. There is no `sandbox_expand()`: once
applied, the restrictions are irrevocable for the process tree, and no userspace
code inside can widen them. It is a single Homebrew formula that builds and
bottles on both platforms, so it costs one `Brewfile` line.

nono ships capability profiles for both agents as signed registry packs rather
than as config this repo would have to track, so the policy under review is
upstream's, versioned, and pulled on demand.

## Decision

`opencode` and `claude` themselves are the sandboxed entry points. Each becomes
a zsh function that runs the real binary under `nono run` with the agent's
registry profile, and `opencode-yolo` / `claude-yolo` are the same binaries with
no boundary. Sandboxing is the default, and opting out is a visible, typed
choice rather than a flag that has to be known in advance.

- `nono` is a `Brewfile` formula. The apt fallback installs upstream's release
  `.deb`, which depends only on a `libc6` floor.
- `install.sh` pulls `nolabs-ai/claude` and `nolabs-ai/opencode` after the
  toolchain. `nono run --profile ...` offers to install a missing pack on a TTY
  and exits with a hint when there is none, so the prompt belongs on the
  bootstrap's output, not on the first agent launch.
- The wrappers add `--allow-cwd`. Both profiles already declare a read+write
  workdir, so this takes that level instead of prompting per launch, plus
  `--read` for each existing `$PATH` entry under `$HOME`.
- Claude Code's own sandbox is disabled in the tracked settings template, and
  `allowUnsandboxedCommands` is pinned `false` so the retry escape hatch stays
  closed even if a project-level settings file turns the sandbox back on.

The launch path is deliberately narrow. The wrappers do not accept nono flags;
anything beyond the profile is a direct `nono run`, which keeps the grant
explicit at the point it is made and keeps the common case one keystroke.

## Consequences

### Positive

- The agent boundary is kernel-enforced and irreversible, so a prompt injection
  cannot widen it. Credential stores (`~/.ssh`, `~/.aws`, `~/.config/gcloud`,
  `~/.config/gh`) and the shell configs are denied by nono's policy groups
  rather than merely unprompted.
- The capability sets are maintained upstream, signature-verified on pull, and
  upgraded with `nono update`, instead of drifting in a tracked JSON file.
- Both platforms get the same boundary from one formula, so a Linux workstation
  is not the weaker machine.
- A denial is explainable: `nono why --path <blocked> --op read` names the
  rule, and the Claude pack's hooks teach Claude to run it and offer the user
  a grant rather than a workaround.
- Claude Code stops being a second, weaker sandbox with a documented way out.

### Negative

- The default agent session can no longer read the whole home directory. Tool
  paths that live outside the profile's grants fail as a permission error, which
  reads like a bug the first time. `nono pull` a newer pack, or extend the
  profile in `~/.config/nono/profiles/`, or use the `-yolo` variant.
- Shadowing `opencode` and `claude` with shell functions is shell-level. It
  applies to interactive zsh only: a script, a herdr command pinned to an
  absolute path, or another shell runs the real binary unsandboxed. That is the
  same tradeoff [ADR-0018](0018-neovim-as-editor-variable.md) accepted for
  `vi`, and it is why the unsandboxed path is named rather than hidden.
- `install.sh` now depends on the nono registry being reachable. A failure
  there is reported and skipped, so the bootstrap completes, but the profiles
  are missing until `nono pull` is re-run.
- A future pack release can widen a profile. Signature verification proves who
  published it, not that the grants stayed narrow.

### Neutral

- nono stays in the process tree as a supervisor for `nono run`, which is what
  enables its credential-injection and rollback features. `nono wrap` execs
  instead, but it drops the network proxy, which these profiles need.
- The `--read` grant for `$HOME` `$PATH` entries is a small widening of the
  profile, computed per launch. Read-only, and bounded to the directories the
  developer's own shell already exposes for execution.
- Disabling Claude Code's sandbox is defense removed in exchange for a
  stronger one. It also disables Claude's own network allowlist, so outbound
  filtering is whatever nono's profile grants.
- The `claude-code` pack grants `~/Library/Keychains` read+write, overriding
  nono's keychain deny, because Claude Code persists its OAuth token in the
  login keychain and cannot refresh a session without it. That is an upstream
  pack decision rather than a grant made here, but it does mean the Claude
  profile is looser than the opencode one on macOS, which denies the keychain.
  Verify either with `nono why --path <path> --op read` after a pack update.

## See Also

- [ADR-0007](0007-agent-surface-in-herdr-pane.md)
- [ADR-0018](0018-neovim-as-editor-variable.md)
- [ADR-0019](0019-merge-claude-user-settings.md)
- [ADR-0002](0002-homebrew-bundle-and-gnu-stow.md)
- [ADR-0017](0017-lazygit-from-brewfile-or-github-releases.md)
- [ADR-0021](0021-derive-nono-profile-from-observed-use.md)
- [ADR-0022](0022-label-sandboxed-agent-for-herdr.md)
- [Architecture](../architecture.md)
