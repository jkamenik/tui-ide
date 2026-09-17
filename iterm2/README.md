# iTerm2

The iTerm2 profile is managed directly in this repo at
`dotfiles/iterm2/.config/iterm2/AppSupport/com.googlecode.iterm2.plist`. iTerm2
rewrites its plist atomically, which breaks a symlink, so the custom preferences
folder points straight at the repo directory instead of being stowed. There is
no copy to keep in sync.

## One-time setup

Point iTerm2's custom preferences folder at the repo directory. Either use the
GUI or run:

```bash
defaults write com.googlecode.iterm2 PrefsCustomFolder \
  -string "$HOME/github.com/jkamenik/tui-ide/dotfiles/iterm2/.config/iterm2/AppSupport"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
```

Then restart iTerm2. Via the GUI: iTerm2 > Settings > General > Preferences >
check "Load preferences from a custom folder or URL" and select that directory.
Set "Save changes to folder when iTerm2 quits" to **Automatically** so every
change lands in the repo.

## Committing changes

Because iTerm2 writes the plist in place, GUI changes show up as a working-tree
change. Review and commit them:

```bash
git diff --stat
git add dotfiles/iterm2/.config/iterm2/AppSupport/com.googlecode.iterm2.plist
git commit -m "Update iTerm2 preferences"
```

On a fresh machine, clone the repo and run the one-time setup above; the profile
is already in the tree.

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
