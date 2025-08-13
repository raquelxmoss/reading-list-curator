# Reading List Curator

Automatically curates book recommendations from r/MoneyDiariesACTIVE monthly threads into an RSS feed.

## Setup Instructions

### 1. Push to GitHub
First, create a new repository on GitHub and push this code:

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/reading-list-curator.git
git push -u origin main
```

### 2. Add GitHub Secrets
Go to your repository's Settings → Secrets and variables → Actions, and add:

- `OPENAI_API_KEY`: Your OpenAI API key for AI book extraction
- `REDDIT_USER_AGENT`: Your Reddit user agent (e.g., "md-curator/1.0 by yourusername")

### 3. Enable GitHub Actions
The workflow will:
- Run daily at 9 AM UTC (you can adjust in `.github/workflows/update-book-feed.yml`)
- Fetch the latest comments from MoneyDiariesACTIVE book threads
- Extract book recommendations using AI
- Enrich with Google Books data
- Generate and commit an RSS feed

### 4. Manual Run (for testing)
Go to Actions tab → "Update Book Recommendations Feed" → "Run workflow"

### 5. Subscribe to RSS Feed
Once running, your RSS feed will be available at:
`https://raw.githubusercontent.com/YOUR_USERNAME/reading-list-curator/main/book_recommendations.rss`

### 6. Set up ConvertKit
1. In ConvertKit, go to Broadcasts → RSS
2. Add your RSS feed URL
3. Configure digest frequency (weekly/monthly)
4. Customize email template
5. You'll receive book recommendations right in your inbox!

## Local Development

```bash
bundle install
ruby moneydiaries.rb
```

The RSS feed will be saved to `book_recommendations.rss`.