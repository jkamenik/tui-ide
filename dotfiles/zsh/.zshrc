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

# Sandboxed agent CLIs. See ADR-0020.
#
# `opencode` and `claude` run inside nono, which enforces a default-deny
# filesystem allow-list in the kernel: Landlock on Linux, Seatbelt on macOS.
# `nono run` execs the real binary, so the sandbox applies to the agent and
# every process it spawns, with no shell-level interception inside the session.
#
# Each agent's capability set comes from a signed registry pack that
# `install.sh` pulls, so these wrappers only pick the profile and share the cwd.
# Both profiles already declare a read+write workdir; --allow-cwd takes that
# level rather than prompting on every launch.
#
# `opencode-yolo` and `claude-yolo` are the same binaries with no boundary at
# all, for a session that needs a path its profile denies. Reach for them
# knowing what that gives up; `nono why --path <blocked> --op read` explains
# what a denial was and how to grant it properly.
nono_agent() {
  local profile="$1" agent="$2"
  shift 2

  # Agents spawn tools with posix_spawnp(), which walks $PATH and gives up at
  # the first entry it cannot read (EPERM, not ENOENT, so the search does not
  # continue to the next directory). This file puts ~/bin, ~/.local/bin, and
  # $BUN_INSTALL/bin ahead of the system directories, so grant read access to
  # the $PATH entries under $HOME; without it a tool the agent shells out to
  # fails as a misleading "command not found". Skipped when the directory does
  # not exist, which is the normal case for the first two.
  local -a path_read
  local dir
  for dir in ${(s.:.)PATH}; do
    [[ "$dir" == "$HOME"/* && -d "$dir" ]] || continue
    # (Ie) gives the last matching subscript, 0 when the value is absent, so a
    # PATH that repeats an entry (a reopened terminal, a version manager) is
    # granted once. nono tolerates repeats; this just keeps the line short.
    (( ${path_read[(Ie)$dir]} == 0 )) && path_read+=(--read "$dir")
  done

  # An empty path_read expands to nothing, so the flags below stay well formed.
  command nono run --profile "$profile" --allow-cwd "${path_read[@]}" -- "$agent" "$@"
}

opencode() { nono_agent nolabs-ai/opencode opencode "$@" }
claude() { nono_agent nolabs-ai/claude claude "$@" }

# `command` skips this shell's function, so these reach the real binary.
opencode-yolo() { command opencode "$@" }
claude-yolo() { command claude "$@" }
