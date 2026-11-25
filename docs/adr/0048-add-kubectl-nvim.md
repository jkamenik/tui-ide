# tui-ide-ADR-0048: Add kubectl.nvim as the in-editor Kubernetes browser

**Status:** Accepted
**Date:** 2026-11-24

## Context

The toolchain now includes `k9s` and `helm` for working with Kubernetes
clusters, but Neovim had no view of a cluster: reading logs, inspecting a
resource, or editing a manifest meant leaving the editor for another pane.

[ramilito/kubectl.nvim](https://github.com/ramilito/kubectl.nvim) is a
k9s-style browser inside Neovim. Resources, logs, exec sessions, and manifests
open as buffers, so the usual motions, search, and editing apply.

## Decision

1. Add `kubectl.nvim` as a lazy.nvim plugin
   (`dotfiles/nvim/.config/nvim/lua/plugins/kubectl.lua`), tracking the `2.*`
   releases, with `saghen/blink.download` as its dependency (it fetches the
   plugin's prebuilt client library, so no Rust toolchain is needed). The
   plugin loads on first use, not at startup.
2. Bind a `<leader>k` group: `kk` toggles the browser in its own tab. Register
   the group in which-key.
3. Add `helm` to the shared `Brewfile` beside `k9s`. It was installed on this
   machine but not declared.

`k9s` stays available in a terminal pane for the full-screen workflow;
`kubectl.nvim` covers the cases where the result should land in a buffer.

## Consequences

### Positive

- Cluster resources, logs, and manifests are editable in Neovim without
  switching panes.

### Negative

- Two more plugins to keep updated; `lazy-lock.json` pins both.
- Needs `kubectl` on `$PATH` and a working kubeconfig. Here `kubectl` comes
  from the `gcloud-cli` cask rather than the Brewfile.

### Neutral

- Works on macOS and Linux; no machine-specific values.

## See Also

- [ADR-0046](0046-add-claudecode-nvim.md) — the `<leader>a` group, the same
  plugin-plus-which-key pattern
