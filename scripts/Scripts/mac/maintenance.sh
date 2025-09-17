#!/bin/zsh
# shellcheck disable=SC1071
# macOS Maintenance Script
# Purpose: One-click (or scheduled) maintenance: quit apps, check OS & app updates, update Homebrew.
# Usage:   ./maintenance.sh [--no-quit] [--no-os] [--no-appstore] [--no-brew] [--no-casks] [--no-clean]
#          ./maintenance.sh --auto          # non-interactive, skips confirmations
# Notes:   Designed to be safe-by-default (no forced quits, no auto OS install).

set -euo pipefail

LOGFILE="${HOME}/Library/Logs/mac_maintenance.log"
mkdir -p "$(dirname "$LOGFILE")"
exec > >(tee -a "$LOGFILE") 2>&1

timestamp() { date "+%Y-%m-%d %H:%M:%S"; }

info()  { printf "[%s] ℹ️  %s\n" "$(timestamp)" "$*"; }
warn()  { printf "[%s] ⚠️  %s\n" "$(timestamp)" "$*"; }
ok()    { printf "[%s] ✅ %s\n" "$(timestamp)" "$*"; }
fail()  { printf "[%s] ❌ %s\n" "$(timestamp)" "$*"; }

# ---------- Options ----------
AUTO=0
DO_QUIT=0
DO_OS=1
DO_APPSTORE=1
DO_BREW=1
DO_CASKS=1
DO_CLEAN=1

for arg in "$@"; do
  case "$arg" in
    --auto) AUTO=1 ;;
    --no-quit) DO_QUIT=0 ;;
    --no-os) DO_OS=0 ;;
    --no-appstore) DO_APPSTORE=0 ;;
    --no-brew) DO_BREW=0 ;;
    --no-casks) DO_CASKS=0 ;;
    --no-clean) DO_CLEAN=0 ;;
    *) warn "Unknown flag: $arg" ;;
  esac
done

# ---------- Helpers ----------

ensure_brew_in_path() {
  if ! command -v brew >/dev/null 2>&1; then
    # Try common locations
    if [ -x "/opt/homebrew/bin/brew" ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x "/usr/local/bin/brew" ]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
}

list_running_apps() {
  /usr/bin/osascript <<'APPLESCRIPT'
  set excludedApps to {"Finder", "Dock", "WindowServer", "ControlCenter", "NotificationCenter", "Shortcuts", "Activity Monitor", "Terminal", "iTerm2", "loginwindow"}
  tell application "System Events"
    set guiProcs to name of every process whose background only is false
  end tell
  set outputList to {}
  repeat with appName in guiProcs
    if excludedApps does not contain (appName as text) then
      copy (appName as text) to end of outputList
    end if
  end repeat
  return outputList as string
APPLESCRIPT
}

quit_apps_gracefully() {
  local apps raw
  raw="$(list_running_apps || true)"
  if [ -z "$raw" ]; then
    info "No user-facing apps to quit."
    return 0
  fi

  # Split by comma delimiter AppleScript returns (e.g., "Safari, Notes, Messages")
  IFS=',' read -rA apps <<< "$raw"
  # Trim whitespace
  for i in {1..${#apps[@]}}; do
    apps[$i]="${apps[$i]#"${apps[$i]%%[![:space:]]*}"}"
    apps[$i]="${apps[$i]%${apps[$i]##*[![:space:]]}}"
  done

  info "Apps to quit: ${apps[*]}"
  if [ $AUTO -eq 0 ]; then
    /usr/bin/osascript <<APPLESCRIPT
      display dialog "Quit these apps?\n\n${raw}\n\nUnsaved work may prompt you to Save/Cancel in each app." buttons {"Cancel","Quit"} default button "Quit" with icon caution
APPLESCRIPT
  fi

  for app in "${apps[@]}"; do
    info "Quitting: $app"
    /usr/bin/osascript -e "tell application \"$app\" to quit" || warn "Could not quit $app"
  done
  ok "Requested all apps to quit (gracefully)."
}

check_os_updates() {
  info "Checking macOS software updates..."
  # Scan & list available updates without installing.
  if /usr/sbin/softwareupdate -l ; then
    ok "Checked for macOS updates. If updates are listed, install from System Settings when convenient."
  else
    warn "softwareupdate reported an error (often 'No new software available')."
  fi

  # Open System Settings > Software Update for visibility (optional)
  if [ $AUTO -eq 0 ]; then
    info "Opening System Settings → Software Update..."
    /usr/bin/open "x-apple.systempreferences:com.apple.Software-Update-Settings.extension" || true
  fi
}

update_app_store_apps() {
  # Prefer 'mas' (Mac App Store CLI) if installed
  if command -v mas >/dev/null 2>&1; then
    info "Checking Mac App Store apps via 'mas'..."
    if mas outdated | grep -q . ; then
      info "Updating Mac App Store apps..."
      mas upgrade || warn "Some App Store app updates may have failed."
      ok "Mac App Store apps updated (mas)."
    else
      ok "No App Store app updates found (mas)."
    fi
  else
    warn "'mas' (Mac App Store CLI) not found. You can install it with: brew install mas"
    if [ $AUTO -eq 0 ]; then
      info "Opening App Store → Updates page so you can update manually."
      /usr/bin/open "macappstore://showUpdatesPage" || /usr/bin/open -a "App Store"
    fi
  fi
}

update_homebrew() {
  ensure_brew_in_path
  if ! command -v brew >/dev/null 2>&1; then
    warn "Homebrew not found. Install from https://brew.sh and re-run."
    return 0
  fi

  info "Updating Homebrew..."
  brew update

  info "Upgrading formulae..."
  brew upgrade || warn "brew upgrade (formulae) had issues."

  if [ $DO_CASKS -eq 1 ]; then
    info "Upgrading casks (including auto-updating apps) — this can be slow..."
    brew upgrade --cask --greedy || warn "brew upgrade (casks) had issues."
  fi

  if [ $DO_CLEAN -eq 1 ]; then
    info "Cleaning up old versions and unused deps..."
    brew autoremove || true
    brew cleanup -s || true
  fi

  ok "Homebrew maintenance complete."
}

open_latest_if_installed() {
  # Check for available updates in Setapp.
  if [ -d "/Applications/Latest.app" ]; then
    info "Opening Latest to let it check for updates..."
    /usr/bin/open -a "Latest" || true
  fi
}

main() {
  info "----- Starting macOS maintenance -----"

  if [ $DO_QUIT -eq 1 ]; then quit_apps_gracefully; fi
  if [ $DO_OS -eq 1 ]; then check_os_updates; fi
  if [ $DO_APPSTORE -eq 1 ]; then update_app_store_apps; fi
  if [ $DO_BREW -eq 1 ]; then update_homebrew; fi

  open_latest_if_installed

  ok "All requested maintenance steps complete."
  info "Log saved to: $LOGFILE"
}

main "$@"
