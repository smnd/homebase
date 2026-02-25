#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Smart Paste URL
# @raycast.mode silent

url=$(pbpaste)

# Skip if already a markdown link or not a URL
if [[ "$url" == "["* ]] || [[ "$url" != http* ]]; then
  osascript -e 'tell application "System Events" to keystroke "v" using command down'
  exit 0
fi

if [[ "$url" == *"claude.ai/chat"* ]]; then
  echo -n "[Claude]($url)" | pbcopy
elif [[ "$url" == *"linear.app"* ]]; then
  echo -n "[Linear]($url)" | pbcopy
elif [[ "$url" == *"figma.com"* ]]; then
  echo -n "[Figma]($url)" | pbcopy
fi

osascript -e 'tell application "System Events" to keystroke "v" using command down'
