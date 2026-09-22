eval "$(/opt/homebrew/bin/brew shellenv zsh)"

if [[ "$(uname)" == "Darwin" ]]; then
  export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"
fi