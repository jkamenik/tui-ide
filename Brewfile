# tui-ide: shared toolchain (macOS and Linuxbrew).
# macOS-only casks live in Brewfile.macos; casks that also build on Linuxbrew
# (such as claude-code) live here.
brew "git"
brew "git-lfs"
brew "gh"
brew "ansible"
brew "neovim"
brew "mosh"
brew "herdr"
# opencode comes from the tap, not homebrew-core: the tap ships both lines as
# separate, conflicting formulae (anomalyco/tap/opencode = 1.x,
# anomalyco/tap/opencode-v2 = 2.x) while core moved onto 2.x. We are on the 1.x
# line for now (ADR-0025); install.sh pins the formula, which is what holds the
# line, since `brew bundle` otherwise upgrades it on the next run.
brew "anomalyco/tap/opencode"
# nono is the kernel-enforced sandbox the agent CLIs run under (ADR-0020).
# Landlock on Linux, Seatbelt on macOS, from one binary.
brew "nono"
# devcontainer is the Dev Containers CLI. Homebrew installs it as the npm
# package @devcontainers/cli, so it brings node in as a dependency.
brew "devcontainer"
cask "claude-code"
brew "ripgrep"
brew "stow"
brew "jq"
brew "lazygit"
tap "cavanaug/tap-extras"
tap "anomalyco/tap"
brew "cavanaug/tap-extras/mermaid-ascii"
brew "hashicorp/tap/terraform"
