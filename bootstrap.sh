#!/usr/bin/env bash
# DO NOT USE WIHOUT CHECKING. THIS MAY NOT WORK.
# Exit on error, unset variables, and failed pipes for safer script execution
set -euo pipefail

# 1) Xcode CLT (prompts if needed)
# xcode-select -p >/dev/null 2>&1 || xcode-select --install || true
# mkdir -p "$HOME/dev/homebase" && cd "$HOME/dev/homebase"
# git clone https://github.com/smnd/homebase.git 

# 2) Homebrew
if ! command -v brew >/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 3) Tools + apps
BREWFILE="$(dirname "$0")/Brewfile"
read -r -p "Run 'brew bundle' to install tools/apps from ${BREWFILE}? [y/N]: " run_brew_bundle
if [[ "${run_brew_bundle:-}" =~ ^[Yy]$ ]]; then
  brew bundle --file="$BREWFILE"
else
  echo "Skipping brew bundle install."
fi

# 4) VS Code CLI (once): user must run in UI → Cmd+Shift+P → "Shell Command: Install 'code' in PATH"
if ! command -v code >/dev/null; then
  echo "Open VS Code → Cmd+Shift+P → Install 'code' command in PATH, continue this script."
  read -r -p "Install 'code' command now and continue once it's available? [y/N]: " install_code_cli
  if [[ ! "${install_code_cli:-}" =~ ^[Yy]$ ]]; then
    echo "Exiting until 'code' command is installed."
    exit 1
  fi

  if ! command -v code >/dev/null; then
    echo "'code' command still missing; rerun this script after installation."
    exit 1
  fi
fi

# 5) Dotfiles via stow
cd "$(dirname "$0")"
stow -t "$HOME" dotfiles/zsh dotfiles/finicky scripts
# dotfiles/git dotfiles/code

# 6) Permissions
chmod -R u+x "$HOME/Scripts" 2>/dev/null || true

# 7) Host-specific (optional)
HOST_DIR="hosts/$(scutil --get ComputerName 2>/dev/null || hostname)"
[ -d "$HOST_DIR" ] && stow -t "$HOME" "$HOST_DIR"

# 8) VS Code extensions
[ -f vscode/extensions.txt ] && xargs -n1 code --install-extension <vscode/extensions.txt || true

echo "✅ Done. Restart Terminal or run: source ~/.zshrc"
