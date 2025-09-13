# Homebase (Private)

My Mac setup: configs (dotfiles) and local scripts.

## Public projects (links only)

<!-- - mytool → https://github.com/YOURNAME/mytool -->
<!-- - myapp  → https://github.com/YOURNAME/myapp -->

## Setup new MacBook

1) Install Homebrew:
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

2) Apps & tools:
   brew bundle

3) In VS Code: Cmd+Shift+P → “Shell Command: Install 'code' in PATH”

4) Put files in place:
   stow -t "$HOME" dotfiles/zsh dotfiles/finicky dotfiles/git dotfiles/ssh dotfiles/code
   mkdir -p "$HOME/Scripts" && rsync -a scripts/Scripts/ "$HOME/Scripts/"

5) Open a new Terminal (or run: source ~/.zshrc)
