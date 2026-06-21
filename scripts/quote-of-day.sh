#!/bin/bash

# Quotes of the day - one per line
QUOTES=(
  "The only way to do great work is to love what you do. — Steve Jobs"
  "Innovation distinguishes between a leader and a follower. — Steve Jobs"
  "Life is what happens when you're busy making other plans. — John Lennon"
  "The future belongs to those who believe in the beauty of their dreams. — Eleanor Roosevelt"
  "It is during our darkest moments that we must focus to see the light. — Aristotle"
  "The only impossible journey is the one you never begin. — Tony Robbins"
  "In the middle of difficulty lies opportunity. — Albert Einstein"
  "Be yourself; everyone else is already taken. — Oscar Wilde"
  "The best time to plant a tree was 20 years ago. The second best time is now. — Chinese Proverb"
  "Your time is limited, don't waste it living someone else's life. — Steve Jobs"
  "The purpose of our lives is to be happy. — Dalai Lama"
  "Get busy living or get busy dying. — Stephen King"
  "You miss 100% of the shots you don't take. — Wayne Gretzky"
  "Whether you think you can, or you think you can't – you're right. — Henry Ford"
  "The only thing we have to fear is fear itself. — Franklin D. Roosevelt"
  "Everything you've ever wanted is on the other side of fear. — George Addair"
  "Believe you can and you're halfway there. — Theodore Roosevelt"
  "Do something today that your future self will thank you for. — Sean Patrick Flanery"
  "The best revenge is massive success. — Frank Sinatra"
  "You don't have to be great to start, but you have to start to be great. — Zig Ziglar"
)

# Select a random quote
QUOTE="${QUOTES[$RANDOM % ${#QUOTES[@]}]}"
DATE=$(date '+%B %d, %Y')

# Write to repo root
cat > /home/user/homebase/QUOTE_OF_DAY.md << EOF
# Quote of the Day

**$DATE**

> $QUOTE
EOF

echo "Quote updated: $QUOTE"
