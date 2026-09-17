# tui-ide-ADR-0012: Obsidian-compatible Markdown editing

**Status:** Accepted
**Date:** 2026-09-17

## Context

The vault content lives in the `second-brain` repo, but Markdown editing happens
here in the interactive toolchain (Neovim). The docs in this repo use plain
GitHub Markdown, while the vault uses Obsidian conventions (frontmatter,
wikilinks, callouts, tags). We need rendering, syntax highlighting, and vault
navigation without breaking the out-of-scope rule for vault content.

## Decision

We will add three Neovim plugins, all lazy-loaded on the `markdown` filetype:

- `nvim-treesitter` for `markdown` and `markdown_inline` parsing.
- `render-markdown.nvim` with the `obsidian` preset for in-buffer rendering.
- `obsidian.nvim` for vault management (wikilinks, `ObsidianQuickSwitch`,
  daily notes), with its own rendering UI disabled (`ui = { enable = false }`)
  so it does not clash with render-markdown.

Obsidian and its rendering UI overlap heavily, so obsidian.nvim handles
structure (backlinks, new notes, follow link) and render-markdown.nvim handles
appearance. The vault path is machine-specific and comes from a git-ignored
overlay `~/.config/nvim/lua/obsidian-local.lua`, following ADR-0008.

## Consequences

### Positive

- Obsidian-flavored Markdown renders like Obsidian inside Neovim.
- Vault navigation (switch note, new note) works without leaving the editor.
- Documented, tested pairing: health-checked `ui.enable=false` avoids the known
  obsidian.nvim + render-markdown.nvim conflict.
- No vault content or paths leak into this repo.

### Negative

- Two plugins plus treesitter parsers to maintain.
- Vault navigation dependson a hand-copied overlay per machine.

### Neutral

- No nvim-cmp integration; completion is out of scope for now.

## See Also

- [ADR-0008](0008-local-overlay-for-sensitive-values.md)
- [Architecture](../architecture.md)