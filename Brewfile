# reference: https://github.com/vraravam/dotfiles/blob/4dfa90c0846c25b3e08ad660624c3c36f871e3c1/files/--HOME--/Brewfile#L8-L10

# Taps (sources)
tap "homebrew/bundle"
tap "homebrew/cask"
tap "homebrew/cask-fonts"
tap "homebrew/core"

# global preferences for all 'brew install' commands
cask_args appdir: '/Applications', fontdir: '/Library/Fonts', no_quarantine: true, adopt: true

# formulae pulled in from homebrew to replace system equivalents to fix any security issues since the OS was released
brew 'bash'
brew 'curl'
brew 'git'
brew 'less'
brew 'rsync'
brew 'wget'
brew 'zsh'

brew 'gh'
brew 'starship'

# brew "zsh"
# brew "coreutils"
# brew "findutils"
# brew "gnu-sed"
# brew "ripgrep"       # fast search
# brew "fd"            # find alternative
# brew "jq"            # JSON tools
# brew "yq"            # YAML tools
# brew "fzf"           # fuzzy finder (run: $(brew --prefix)/opt/fzf/install)
# brew "zoxide"        # smarter cd
# brew "eza"           # ls alternative
# brew "tree"
# brew "wget"
# brew "gnupg"

# install most essential apps directly 

cask "1password"
cask "raycast"
cask "visual-studio-code"
cask "carbon-copy-cloner"
cask "connectmenow"
cask "expressvpn"
cask "figma"
cask "finicky"
cask "hiddenbar"
cask "istat-menus"
cask "iterm2"
cask "keyboardcleantool"
cask "latest"
cask "notion"
cask "obsidian"
cask "shottr"
cask "spotify"
cask "stay"
cask "tailscale-app"
cask "vlc"
cask "whatsapp"

# install Mac App Store apps via `mas`
brew 'mas'
mas 'PDFgear', id: 6469021132
mas 'Things', id: 904280696

# install dev tools and runtimes
brew "python@3.13"
brew "pipx"          # isolated Python CLIs
# brew "node"
# brew "pnpm"
# brew "direnv"        # per-folder envs
# brew "gh"            # GitHub CLI
# brew "httpie"

# media manipulation tools 
# brew "ffmpeg"
# brew "imagemagick"
# brew "exiftool"

# fonts for the terminal and code editors
brew "font-jetbrains-mono"
brew "font-fira-code-nerd-font"

# ---------- VS Code extensions
vscode "davidanson.vscode-markdownlint"
vscode "docker.docker"
vscode "dotjoshjohnson.xml"
vscode "ecmel.vscode-html-css"
vscode "github.copilot"
vscode "github.copilot-chat"
vscode "inferrinizzard.prettier-sql-vscode"
vscode "kevinrose.vsc-python-indent"
vscode "mechatroner.rainbow-csv"
vscode "ms-azuretools.vscode-containers"
vscode "ms-azuretools.vscode-docker"
vscode "ms-python.debugpy"
vscode "ms-python.isort"
vscode "ms-python.python"
vscode "ms-python.vscode-pylance"
vscode "ms-python.vscode-python-envs"
vscode "ms-vscode-remote.remote-ssh"
vscode "ms-vscode-remote.remote-ssh-edit"
vscode "ms-vscode.remote-explorer"
vscode "redhat.vscode-yaml"
vscode "yzhang.markdown-all-in-one"
