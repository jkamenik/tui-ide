# Homebrew shell env for interactive zsh. brew is at /opt/homebrew on Apple
# silicon Macs and /home/linuxbrew/.linuxbrew on Linux; guard every branch so
# this file works on boxes without brew (e.g. the always-on VM).
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv zsh)"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
fi

if [[ "$(uname)" == "Darwin" ]]; then
  export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"
fi