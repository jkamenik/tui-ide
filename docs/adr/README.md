# Architecture Decision Records

One decision per file, `NNNN-slug.md`. Accepted records are immutable; replace
one by adding a new ADR that supersedes it. Correcting typos, grammar, or a
broken cross-reference link in an accepted record is not a change of decision
and may be fixed in place.

See [Architecture](../architecture.md) for the compiled current state.

| ID | Title | Status | Date |
|----|-------|--------|------|
| [0001](0001-separate-tui-ide-repo.md) | Keep a separate `tui-ide` repo | Accepted | 2026-09-16 |
| [0002](0002-homebrew-bundle-and-gnu-stow.md) | Homebrew Bundle plus GNU Stow for provisioning | Accepted | 2026-09-16 |
| [0003](0003-terminal-clients-iterm2-and-moshi.md) | iTerm2 on macOS and Moshi on iOS | Accepted | 2026-09-16 |
| [0004](0004-herdr-as-multiplexer.md) | herdr as the multiplexer | Accepted | 2026-09-16 |
| [0005](0005-neovim-as-editor.md) | Neovim as the editor | Superseded by [0018](0018-neovim-as-editor-variable.md) | 2026-09-16 |
| [0006](0006-mosh-over-tailscale.md) | mosh over Tailscale, OpenSSH for files | Accepted | 2026-09-16 |
| [0007](0007-agent-surface-in-herdr-pane.md) | Agent surface is the opencode TUI in a herdr pane | Accepted | 2026-09-16 |
| [0008](0008-local-overlay-for-sensitive-values.md) | Overlay files for machine-specific values | Accepted | 2026-09-16 |
| [0009](0009-track-iterm2-preferences.md) | Track iTerm2 preferences from a synced plist | Superseded by [0010](0010-manage-iterm2-plist-in-repo.md) | 2026-09-16 |
| [0010](0010-manage-iterm2-plist-in-repo.md) | Manage the iTerm2 plist in the repo directory | Accepted | 2026-09-16 |
| [0011](0011-lazygit-as-git-client.md) | LazyGit as the git client | Superseded by [0017](0017-lazygit-from-brewfile-or-github-releases.md) | 2026-09-16 |
| [0012](0012-obsidian-compatible-markdown-editing.md) | Obsidian-compatible Markdown editing | Accepted | 2026-09-17 |
| [0013](0013-apply-color-scheme-on-fresh-machine.md) | Apply the tracked color scheme on a fresh machine | Accepted; opencode clause superseded by [0023](0023-seed-the-opencode-tui-config.md) | 2026-09-22 |
| [0014](0014-stow-dotfiles-without-folding.md) | Stow dotfiles without folding | Accepted | 2026-09-22 |
| [0015](0015-run-herdr-server-under-launchd-on-macos.md) | Run the herdr server under launchd on macOS | Accepted | 2026-09-22 |
| [0016](0016-never-back-up-files-that-resolve-into-the-repo.md) | Never back up files that resolve into the repo | Accepted | 2026-09-27 |
| [0017](0017-lazygit-from-brewfile-or-github-releases.md) | LazyGit as the git client, from Brewfile or GitHub releases | Accepted | 2026-09-27 |
| [0018](0018-neovim-as-editor-variable.md) | Neovim as `$EDITOR`, with `vi` aliased to nvim | Accepted | 2026-09-28 |
| [0019](0019-merge-claude-user-settings.md) | Merge Claude Code user settings instead of stowing them | Accepted | 2026-09-28 |
| [0020](0020-sandbox-agent-clis-with-nono.md) | Sandbox the agent CLIs with nono | Accepted | 2026-09-28 |
| [0021](0021-derive-nono-profile-from-observed-use.md) | Derive the nono profile from observed session use | Accepted | 2026-09-28 |
| [0022](0022-label-sandboxed-agent-for-herdr.md) | Label the sandboxed agent for herdr with `HERDR_AGENT` | Accepted | 2026-09-28 |
| [0023](0023-seed-the-opencode-tui-config.md) | Seed the opencode TUI config from a tracked example | Superseded by [0024](0024-seed-the-opencode-client-config.md) | 2026-09-28 |
| [0024](0024-seed-the-opencode-client-config.md) | Seed the opencode client config from a tracked example | Superseded by [0026](0026-seed-the-client-config-the-installed-version-reads.md) | 2026-10-02 |
| [0025](0025-pin-opencode-to-the-1.x-line.md) | Pin opencode to the 1.x line | Accepted | 2026-10-02 |
| [0026](0026-seed-the-client-config-the-installed-version-reads.md) | Seed the client config the installed version reads | Accepted | 2026-10-02 |
| [0027](0027-pin-the-opencode-nono-pack-to-0.2.0.md) | Pin the opencode nono pack to 0.2.0 | Accepted | 2026-10-07 |
| [0028](0028-pre-create-opencode-state-dirs-at-bootstrap.md) | Pre-create opencode's state directories at bootstrap | Accepted | 2026-10-06 |

## Format

Each ADR uses: Status, Context, Decision, Consequences (Positive, Negative,
Neutral), and See Also. Keep them short and in active voice.
