#!/bin/bash

# Daily quote generator - runs at 6am via cron
# Writes to QUOTE_OF_THE_DAY.md in the repo root

REPO_ROOT="/home/user/homebase"
OUTPUT_FILE="$REPO_ROOT/QUOTE_OF_THE_DAY.md"

# Array of quotes
quotes=(
  "The only way to do great work is to love what you do. — Steve Jobs"
  "Innovation distinguishes between a leader and a follower. — Steve Jobs"
  "Life is what happens when you're busy making other plans. — John Lennon"
  "The future belongs to those who believe in the beauty of their dreams. — Eleanor Roosevelt"
  "It is during our darkest moments that we must focus to see the light. — Aristotle"
  "The only impossible journey is the one you never begin. — Tony Robbins"
  "Success is not final, failure is not fatal. — Winston Churchill"
  "Believe you can and you're halfway there. — Theodore Roosevelt"
  "Do what you can, with what you have, where you are. — Theodore Roosevelt"
  "Everything you want is on the other side of fear. — Jack Canfield"
  "The best time to plant a tree was 20 years ago. The second best time is now. — Chinese Proverb"
  "Well done is better than well said. — Benjamin Franklin"
  "Keep your face always toward the sunshine, and shadows will fall behind you. — Walt Whitman"
  "A room without books is like a body without a soul. — Cicero"
  "To be yourself in a world that is constantly trying to make you something else is the greatest accomplishment. — Ralph Waldo Emerson"
)

# Get quote based on day of year for consistency
DAY_OF_YEAR=$(date +%j)
QUOTE_INDEX=$((($DAY_OF_YEAR - 1) % ${#quotes[@]}))
QUOTE="${quotes[$QUOTE_INDEX]}"

# Generate content with date
TODAY=$(date "+%Y-%m-%d")
CONTENT="# Quote of the Day

**${TODAY}**

> ${QUOTE}"

# Write to file, overwriting previous quote
echo "$CONTENT" > "$OUTPUT_FILE"

exit 0
