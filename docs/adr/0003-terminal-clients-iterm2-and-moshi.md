# tui-ide-ADR-0003: iTerm2 on macOS and Moshi on iOS

**Status:** Accepted
**Date:** 2026-09-16

## Context

The macOS terminal needs clickable custom URL schemes (`obsidian://`, `onepassword://`) and a configurable font if the environment is to feel integrated. On iOS, the terminal must reach the always-on host from a phone, where mosh behavior and multiplexer ergonomics matter most. Candidates: Ghostty, Alacritty, WezTerm, Kitty, Terminal.app on macOS; Blink, Termius, Moshi on iOS.

## Decision

We will use iTerm2 on macOS and Moshi on iOS. iTerm2 is installed manually because its preferences and URL schemes are GUI-driven. Blink is the documented fallback on iOS.

## Consequences

### Positive

- iTerm2 supports the custom URL schemes and profile settings the environment relies on.
- Moshi is mosh-native and works well with herdr on a phone-sized screen.
- GUI-only install keeps the cask list honest and avoids a half-configured profile.

### Negative

- iTerm2 settings are not captured in git by default, so profile setup is a manual step.
- Moshi is commercial for advanced features.

### Neutral

- Ghostty or WezTerm remain viable if iTerm2 URL scheme support ever stops being needed.

## See Also

- [Architecture](../architecture.md)
- [iTerm2 setup](../../iterm2/README.md)
