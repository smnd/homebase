#!/usr/bin/env zsh
# shellcheck disable=all

# --- Homebrew (Apple Silicon) ---
if command -v brew >/dev/null; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# --- Completions (fast & cached) ---
autoload -Uz compinit && compinit -C
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' rehash true
zstyle ':completion:*' use-cache on

# Scripts folder
export PATH="$HOME/Scripts:$PATH"

# --- History (shared across tabs, big, de-duped) ---
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt APPEND_HISTORY SHARE_HISTORY INC_APPEND_HISTORY_TIME HIST_IGNORE_DUPS HIST_VERIFY

# --- Shell behavior (ergonomics & safety) ---
setopt AUTO_CD            # 'cd' by just typing a folder name
setopt EXTENDED_GLOB
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP
setopt NO_CLOBBER         # prevent '>' from overwriting files; use '>|' to force
setopt CORRECT            # typo suggestions for commands (comment out if annoying)
setopt NO_NOMATCH         # don't error on unmatched globs

# --- Aliases ---
alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -alh'
alias la='ls -A'
alias grep='grep --color=auto'
alias c='clear'
alias reload='exec zsh'
alias week='date +%G-W%V'

alias ez='code ~/.zshrc'
alias ef='code ~/.finicky.js'
alias es='code ~/Scripts'
alias codext='code --list-extensions > ~/dev/homebase/vscode/extensions.txt'

# # Homebrew helpers
# List all casks that are outdated like a "dry-run" (and which have version marked as 'latest')
# alias bcg='brew outdated --greedy'  

# Upgrades all casks that are outdated (and which have version marked as 'latest')
# alias bcug='brew upgrade --greedy'

# Upgrades and cleans up all regular outdated casks and libs (non-greedy)
# alias bupc='brew bundle check || brew bundle --all --cleanup || true; brew bundle cleanup -f || true; brew cleanup --prune=all || true; brew autoremove || true; brew upgrade || true'
alias brewup='brew update && brew upgrade && brew autoremove && brew cleanup'

# Python helpers
alias py='python3'

mkvenv() {
  python3 -m venv .venv && source .venv/bin/activate && python -m pip install --upgrade pip
}
workon() { 
  test -f .venv/bin/activate && source .venv/bin/activate || echo "No .venv here"; 
}

# --- Small, useful functions ---
# Simple helper: make a file executable
mkexec() { chmod +x "$1"; }

# Show Hardware Port name, device, IPv4 (skips loopback & link-local unless -a)
ip() {
  local include_all=false
  [[ "$1" == "-a" ]] && include_all=true

  typeset -A port_for_device
  local line name dev
  while IFS= read -r line; do
    case "$line" in
      "Hardware Port:"*) name=${line#Hardware Port: } ;;
      "Device:"*) dev=${line#Device: }; port_for_device[$dev]="$name" ;;
    esac
  done < <(networksetup -listallhardwareports)

  local ip
  for dev in ${(k)port_for_device}; do
    if ! ip=$(ipconfig getifaddr "$dev" 2>/dev/null); then
      continue
    fi
    if ! $include_all; then
      [[ "$ip" == 127.* || "$ip" == 169.254.* ]] && continue
    fi
    printf "%-20s %-10s %s\n" "${port_for_device[$dev]}" "$dev" "$ip"
  done | sort
}

# Unpacks a single archive into the current folder based on its extension
extract() { case "$1" in
  *.tar.bz2) tar xjf "$1" ;; *.tar.gz) tar xzf "$1" ;; *.tar.xz) tar xJf "$1" ;;
  *.zip) unzip "$1" ;; *.rar) unrar x "$1" ;; *) echo "don't know '$1'";; esac }

# --- Editor & locale ---
# Use VS Code for CLI edits (waits until file is closed)
export EDITOR="code -w"
export VISUAL="$EDITOR"

# export EDITOR="nano"
# export VISUAL="$EDITOR"
export PAGER="less -R"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Created by `pipx` on 2025-09-13 03:25:07
export PATH="$PATH:/Users/suman/.local/bin"

eval "$(starship init zsh)"
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh