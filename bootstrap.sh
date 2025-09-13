#!/usr/bin/env bash
set -euo pipefail

# 1) Xcode CLT (prompts if needed)
xcode-select -p >/dev/null 2>&1 || xcode-select --install || true

# 2) Homebrew
if ! command -v brew >/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 3) Tools + apps
brew bundle --file="$(dirname "$0")/Brewfile"
brew install stow

# 4) VS Code CLI (once): user must run in UI → Cmd+Shift+P → "Shell Command: Install 'code' in PATH"
if ! command -v code >/dev/null; then
  echo "Open VS Code → Cmd+Shift+P → Install 'code' command in PATH, then re-run this script."
  exit 1
fi

# 5) Dotfiles via stow
cd "$(dirname "$0")"
stow -t "$HOME" dotfiles/zsh dotfiles/finicky dotfiles/git dotfiles/code scripts

# 6) Permissions
chmod -R u+x "$HOME/Scripts" 2>/dev/null || true

# 7) Host-specific (optional)
HOST_DIR="hosts/$(scutil --get ComputerName 2>/dev/null || hostname)"
[ -d "$HOST_DIR" ] && stow -t "$HOME" "$HOST_DIR"

# 8) VS Code extensions
[ -f vscode/extensions.txt ] && xargs -n1 code --install-extension < vscode/extensions.txt || true

echo "✅ Done. Restart Terminal or run: source ~/.zshrc"
