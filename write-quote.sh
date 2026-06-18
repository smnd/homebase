#!/bin/bash
# Write quote of the day to QUOTE.md

QUOTE_FILE="QUOTE.md"
DATE=$(date +"%Y-%m-%d")

# Array of inspirational quotes
QUOTES=(
  "The only way to do great work is to love what you do. — Steve Jobs"
  "Innovation distinguishes between a leader and a follower. — Steve Jobs"
  "Life is what happens when you're busy making other plans. — John Lennon"
  "The future belongs to those who believe in the beauty of their dreams. — Eleanor Roosevelt"
  "It is during our darkest moments that we must focus to see the light. — Aristotle"
  "The only impossible journey is the one you never begin. — Tony Robbins"
  "In the middle of difficulty lies opportunity. — Albert Einstein"
  "Success is not final, failure is not fatal. — Winston Churchill"
  "Don't watch the clock; do what it does. Keep going. — Sam Levenson"
  "The best way to predict the future is to create it. — Peter Drucker"
)

# Select a random quote
RANDOM_INDEX=$((RANDOM % ${#QUOTES[@]}))
QUOTE="${QUOTES[$RANDOM_INDEX]}"

# Write to QUOTE.md
cat > "$QUOTE_FILE" << EOF
# Quote of the Day

**$DATE**

> $QUOTE

---
*Updated daily at 6:00 AM UTC*
EOF

echo "Quote written to $QUOTE_FILE"
