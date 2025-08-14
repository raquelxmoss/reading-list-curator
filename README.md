# Reading List Curator

Automatically curates book recommendations from r/MoneyDiariesACTIVE monthly threads into an RSS feed.

## Current Status

**Note:** GitHub Actions is blocked by Reddit, so this runs locally via cron job instead.

## Local Setup

### Prerequisites
- Ruby installed
- Bundle installed (`gem install bundler`)
- Git configured with push access to your GitHub repo

### Installation

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/reading-list-curator.git
cd reading-list-curator

# Install dependencies
bundle install

# Set up environment variables
cp .env.example .env
# Edit .env with your OPENAI_API_KEY and REDDIT_USER_AGENT
```

### Running Manually

```bash
ruby moneydiaries.rb
```

This will:
1. Fetch the latest MoneyDiariesACTIVE book thread
2. Extract all comments
3. Use AI to identify book recommendations
4. Enrich with Google Books data
5. Generate `book_recommendations.rss`

### Push to GitHub

After running, push the updated RSS feed:

```bash
git add book_recommendations.rss
git commit -m "Update book recommendations"
git push
```

## RSS Feed Access

Your RSS feed will be available at:
`https://raw.githubusercontent.com/YOUR_USERNAME/reading-list-curator/main/book_recommendations.rss`

## ConvertKit Setup
1. In ConvertKit, go to Broadcasts → RSS
2. Add your RSS feed URL from above
3. Configure digest frequency (weekly/monthly)
4. Customize email template
5. You'll receive book recommendations right in your inbox!

## Local Development

```bash
bundle install
ruby moneydiaries.rb
```

The RSS feed will be saved to `book_recommendations.rss`.