# iTerm2

iTerm2 stores its profile in `~/.config/iterm2/AppSupport` when the custom
preferences folder is enabled. That folder is currently empty, so the profile
still lives in the default location.

## One-time GUI setup

1. iTerm2 > Settings > General > Preferences.
2. Check "Load preferences from a custom folder or URL".
3. Point it at `~/.config/iterm2/AppSupport`.
4. iTerm2 writes `com.googlecode.iterm2.plist` there. Commit that file.

Once the custom folder is live, this repo owns the profile and a fresh machine
can be seeded by copying the plist into place before first launch.

## Required settings for this stack

- **Font:** a Nerd Font (Meslo LGS NF from the Brewfile) so herdr's symbol
  status indicators render. Set it in Settings > Profiles > Text.
- **Colors:** the warm-burnout scheme. herdr inherits it via
  `[theme] name = "terminal"`.
- **Key binding for multi-line input:** add Shift+Enter to send hex
  `0x1b 0x0d` (iTerm2 > Settings > Profiles > Keys).
- **Clipboard:** OSC 52 is used by Neovim over mosh. No local clipboard
  provider is needed.
- **Terminal type:** ensure truecolor is reported (default in modern iTerm2).
