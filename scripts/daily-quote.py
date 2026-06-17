#!/usr/bin/env python3
"""Write a quote of the day to the repo root."""

import os
import random
from datetime import datetime
import subprocess

QUOTES = [
    "The only way to do great work is to love what you do. — Steve Jobs",
    "Innovation distinguishes between a leader and a follower. — Steve Jobs",
    "Life is what happens when you're busy making other plans. — John Lennon",
    "The future belongs to those who believe in the beauty of their dreams. — Eleanor Roosevelt",
    "It is during our darkest moments that we must focus to see the light. — Aristotle",
    "The only impossible journey is the one you never begin. — Tony Robbins",
    "In the end, we will remember not the words of our enemies, but the silence of our friends. — Martin Luther King Jr.",
    "The way to get started is to quit talking and begin doing. — Walt Disney",
    "Don't watch the clock; do what it does. Keep going. — Sam Levenson",
    "The best time to plant a tree was 20 years ago. The second best time is now. — Chinese Proverb",
    "Do something today that your future self will thank you for. — Unknown",
    "Great things never came from comfort zones. — Unknown",
    "Dream it. Believe it. Build it. — Unknown",
    "Success is not final, failure is not fatal. — Winston Churchill",
    "Your time is limited, don't waste it living someone else's life. — Steve Jobs",
]

def write_quote():
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    quote_file = os.path.join(repo_root, "QUOTE_OF_THE_DAY.txt")

    quote = random.choice(QUOTES)
    today = datetime.now().strftime("%Y-%m-%d")

    with open(quote_file, "w") as f:
        f.write(f"Quote of the Day - {today}\n")
        f.write("=" * 40 + "\n\n")
        f.write(quote + "\n")

    # Commit and push
    try:
        subprocess.run(["git", "-C", repo_root, "add", "QUOTE_OF_THE_DAY.txt"], check=True)
        subprocess.run(
            ["git", "-C", repo_root, "commit", "-m", f"Daily quote: {today}"],
            check=True,
            capture_output=True
        )
        subprocess.run(["git", "-C", repo_root, "push"], check=True, capture_output=True)
        print(f"Quote written and pushed: {quote}")
    except subprocess.CalledProcessError as e:
        print(f"Error committing/pushing: {e}")

if __name__ == "__main__":
    write_quote()
