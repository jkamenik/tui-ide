# iTerm2

The iTerm2 profile is tracked as a snapshot at
`iterm2/com.googlecode.iterm2.plist`. iTerm2 loads preferences from
`~/.config/iterm2/AppSupport` when the custom preferences folder is enabled;
`install.sh` seeds that file from the snapshot on a fresh macOS machine.

## One-time GUI setup

1. iTerm2 > Settings > General > Preferences.
2. Check "Load preferences from a custom folder or URL".
3. Point it at `~/.config/iterm2/AppSupport`.

Once the custom folder is live, iTerm2 writes the plist there and this repo owns
the profile.

## Syncing changes

The custom folder is the source of truth while you use the GUI. After changing
settings, copy the plist back into the repo and commit it:

```bash
cp ~/.config/iterm2/AppSupport/com.googlecode.iterm2.plist \
  iterm2/com.googlecode.iterm2.plist
```

On a fresh machine, the snapshot is seeded automatically by `install.sh` (only
when the plist is absent), then enable the custom folder above.

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
