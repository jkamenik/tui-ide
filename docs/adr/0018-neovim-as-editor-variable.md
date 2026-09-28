# tui-ide-ADR-0018: Neovim as `$EDITOR`, with `vi` aliased to nvim

**Status:** Accepted
**Date:** 2026-09-28
**Supersedes:** [ADR-0005](0005-neovim-as-editor.md)

## Context

[ADR-0005](0005-neovim-as-editor.md) chose Neovim as the human editing surface
but deliberately held `EDITOR` on `hx` "until the Neovim config is proven and
the switch is staged". The staging is done: the Lua config, the plugin set, and
the Obsidian-compatible rendering are in place, and `hx` is not installed by
`Brewfile` or by the apt fallback, so `EDITOR=hx` pointed at a binary that does
not exist. Every program that honors `EDITOR` — `git commit` without `-m`,
`crontab -e`, `sudoedit` — failed on a fresh machine.

The same reasoning made `vi` worth redirecting. It is vim on macOS and vi on
Linux, so habits and copied commands land in an editor the repo does not
configure.

## Decision

`EDITOR` is `nvim` in `dotfiles/zsh/.zshrc`, and `VISUAL` mirrors it so tools
that prefer the full-screen variable cannot disagree. `vi` is aliased to `nvim`
in interactive zsh. Neovim remains the human editing surface, as
[ADR-0005](0005-neovim-as-editor.md) decided; this record only completes that
decision by moving the variable.

## Consequences

### Positive

- `git commit`, `crontab -e`, and `sudoedit` open the configured editor instead
  of failing on a missing `hx`.
- `VISUAL` cannot drift from `EDITOR`.
- `vi` in a pasted command opens the same config as `nvim`.

### Negative

- The alias is interactive-shell only. A program that `exec`s `vi` directly —
  a script, or a `sudo` rule with a hardcoded path — still gets vim or vi. A
  `vi` shim in `dotfiles/zsh/bin` (already on `PATH`) would cover those, at
  the cost of a second file to maintain.
- Helix is no longer the default. It was not installed by the toolchain, so
  this loses nothing that worked, but it does drop the alternate editor
  ADR-0005 left open.

### Neutral

- `hx` stays usable by absolute path for anyone who installs it separately.

## See Also

- [ADR-0005](0005-neovim-as-editor.md)
- [ADR-0002](0002-homebrew-bundle-and-gnu-stow.md)
- [Architecture](../architecture.md)
