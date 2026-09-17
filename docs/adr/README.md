# Architecture Decision Records

One decision per file, `NNNN-slug.md`. Accepted records are immutable; replace
one by adding a new ADR that supersedes it.

See [Architecture](../architecture.md) for the compiled current state.

| ID | Title | Status | Date |
|----|-------|--------|------|
| [0001](0001-separate-tui-ide-repo.md) | Keep a separate `tui-ide` repo | Accepted | 2026-09-16 |
| [0002](0002-homebrew-bundle-and-gnu-stow.md) | Homebrew Bundle plus GNU Stow for provisioning | Accepted | 2026-09-16 |
| [0003](0003-terminal-clients-iterm2-and-moshi.md) | iTerm2 on macOS and Moshi on iOS | Accepted | 2026-09-16 |
| [0004](0004-herdr-as-multiplexer.md) | herdr as the multiplexer | Accepted | 2026-09-16 |
| [0005](0005-neovim-as-editor.md) | Neovim as the editor | Accepted | 2026-09-16 |
| [0006](0006-mosh-over-tailscale.md) | mosh over Tailscale, OpenSSH for files | Accepted | 2026-09-16 |
| [0007](0007-agent-surface-in-herdr-pane.md) | Agent surface is the opencode TUI in a herdr pane | Accepted | 2026-09-16 |
| [0008](0008-local-overlay-for-sensitive-values.md) | Overlay files for machine-specific values | Accepted | 2026-09-16 |
| [0009](0009-track-iterm2-preferences.md) | Track iTerm2 preferences from a synced plist | Superseded | 2026-09-16 |
| [0010](0010-manage-iterm2-plist-in-repo.md) | Manage the iTerm2 plist in the repo directory | Accepted | 2026-09-16 |

## Format

Each ADR uses: Status, Context, Decision, Consequences (Positive, Negative,
Neutral), and See Also. Keep them short and in active voice.
