# Tracked shell config for the tui-ide toolchain. install.sh stows this file to
# ~/.config/zsh/tui-ide.zsh, and the machine-owned ~/.zshrc sources it, so a tool
# that rewrites ~/.zshrc in place (Aikido, brew, nvm, gcloud, ...) never dirties
# tracked content. Keep machine-specific values out of here (convention 4); put
# them in ~/.zshrc or ~/.zshrc.local instead. See ADR-0034.
#
# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:$HOME/.local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

if [ -f "$ZSH/oh-my-zsh.sh" ]; then
  source "$ZSH/oh-my-zsh.sh"
else
  echo "oh-my-zsh not found at $ZSH; run ./install.sh to install it" >&2
fi

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi
export EDITOR=nvim
# Some tools (sudo, crontab) prefer the full-screen editor variable; keep the
# two in step so they cannot disagree. See ADR-0018.
export VISUAL="$EDITOR"

# Apple Terminal does not answer nvim's background-color (OSC11/DSR) probe,
# which delays nvim startup and shows E1568. Skip the probe only there; iTerm2
# keeps auto-detection.
if [[ "$TERM_PROGRAM" == "Apple_Terminal" ]]; then
  export NVIM_NOTTYFAST=1
fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# `vi` is vim on macOS and vi on Linux; aim muscle memory at the configured
# editor instead. An alias only covers interactive shells, so a program that
# execs `vi` itself still gets the real one. See ADR-0018.
alias vi=nvim

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# `claude` is the plain binary on $PATH. The nono wrappers both agents used to
# run under are retired (ADR-0031), so the agent is the pane's foreground
# process and herdr identifies it without a HERDR_AGENT hint.

# macOS: a long agent turn dies to idle sleep, so launch the opencode TUI
# under `caffeinate -i`, which holds an idle-sleep assertion for exactly as
# long as the TUI runs. caffeinate forks and execs the command in its parent,
# so the job keeps its pid, keeps the name `opencode`, and stays the pane's
# foreground process (ADR-0031's herdr property survives); a watcher child
# owns the assertion and exits when the TUI dies, releasing it. The detached
# `opencode serve --service` daemon lives outside that lifetime and never
# holds sleep back. Only the TUI launch is wrapped — a bare invocation, flags,
# or a directory argument; any subcommand (run, service, serve, acp, ...)
# execs the plain binary so the server can never end up under caffeinate.
# See ADR-0039.
if [[ "$OSTYPE" == darwin* ]] && [[ -n "${commands[caffeinate]:-}" ]] \
   && [[ -n "${commands[opencode]:-}" ]]; then
  opencode() {
    local bin="${commands[opencode]}"
    case "${1:-}" in
      '' | -*)
        caffeinate -i "$bin" "$@" ;;
      *)
        if [[ -d "$1" ]]; then
          caffeinate -i "$bin" "$@"   # `opencode <dir>` also opens the TUI
        else
          "$bin" "$@"
        fi ;;
    esac
  }
fi

# Load nvm so project-pinned Node versions resolve. `--no-use` defers
# switching off the system Node until a .nvmrc selects one, so an unversioned
# directory keeps the default. The completion file is bash-named but zsh-safe.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" --no-use
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# Machine-local shell overrides. install.sh writes this repo's bin/ (git-cleanup
# and friends) onto $PATH in ~/.zshrc.local, because the absolute repo path
# differs per machine and must not be tracked (convention 4). Sourced last so a
# local override can also adjust anything above. See ADR-0033.
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
