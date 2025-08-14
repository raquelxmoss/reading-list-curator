#!/bin/bash

# Script to fetch book recommendations and push to GitHub
# Run via cron to automate updates

cd "$(dirname "$0")"

echo "[$(date)] Starting book recommendation update..."

# Run the Ruby script
ruby moneydiaries.rb

# Check if RSS file was created/modified
if [ -f "book_recommendations.rss" ]; then
  # Check if there are any changes to commit
  git add book_recommendations.rss

  if git diff --staged --quiet; then
    echo "[$(date)] No changes to RSS feed"
  else
    echo "[$(date)] Pushing updated RSS feed to GitHub..."
    git commit -m "Update book recommendations - $(date +'%Y-%m-%d %H:%M')"
    git push origin main
    echo "[$(date)] Successfully pushed RSS feed to GitHub"
  fi
else
  echo "[$(date)] Error: RSS file not generated"
  exit 1
fi

echo "[$(date)] Update complete"
