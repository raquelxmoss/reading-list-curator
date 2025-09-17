# moneydiaries.rb
# frozen_string_literal: true

require "dotenv/load"
require_relative "lib/reddit"
require_relative "lib/ai_extract"
require_relative "lib/deduper"

deduper = Deduper.new
puts "Deduplication stats: #{deduper.stats}"

puts "Fetching MoneyDiariesACTIVE monthly book rec threads..."
threads = Reddit.search_threads.first(1)

all_comments = []
comment_ids = []

threads.each_with_index do |permalink, idx|
  puts "Fetching comments from thread..."
  comments_with_ids = Reddit.fetch_comments_with_ids(permalink)

  # Filter out already-seen comments
  new_comments = deduper.filter_new_comments(comments_with_ids)

  if new_comments.empty?
    puts "No new comments found. Skipping AI extraction."
    exit 0
  end

  # Extract just the comment bodies for AI processing
  all_comments = new_comments.map { |c| c[:body] }
  comment_ids = new_comments.map { |c| c[:id] }
end

# Extract books with sentiment analysis and reviews
puts "Analyzing sentiment and extracting reviews..."
reviewed_books = AIExtract.extract_reviews_and_sentiment(all_comments)

# Also extract just book titles for any missed books
basic_books = AIExtract.book_titles_from_comments(all_comments)

# Merge the two approaches - prioritize books with reviews
books_with_reviews = {}
reviewed_books.each { |book| books_with_reviews["#{book['title']}|#{book['author']}".downcase] = book }

# Add any books that were found by basic extraction but not by review analysis
basic_books.each do |book|
  key = "#{book['title']}|#{book['author']}".downcase
  unless books_with_reviews[key]
    books_with_reviews[key] = book
  end
end

puts "Found #{reviewed_books.size} books with reviews, #{books_with_reviews.size} total books"

# Mark these comments as seen for next run
deduper.mark_comments_seen(comment_ids)
puts "Marked #{comment_ids.size} comments as processed"

require_relative "lib/google_books"

enriched_books = books_with_reviews.values.map do |b|
  # Convert string keys to symbol keys and merge with Google Books data
  book_data = {
    title: b['title'],
    authors: b['author'],
    review_summary: b['review_summary'],
    sentiment: b['sentiment'],
    original_comment: b['original_comment']
  }

  # Get Google Books data and merge
  google_data = GoogleBooks.search_book(b)
  google_data ? google_data.merge(book_data) : book_data
end.compact

require_relative "lib/rss_generator"

rss_feed = RSSGenerator.merge_and_generate_feed(enriched_books, "book_recommendations.rss", {
  title: "MoneyDiariesACTIVE Book Recommendations",
  description: "Monthly book recommendations from r/MoneyDiariesACTIVE",
  link: "https://reddit.com/r/MoneyDiariesACTIVE"
})

# Save RSS feed to file
File.write("book_recommendations.rss", rss_feed.to_s)
puts "\n\nRSS feed saved to book_recommendations.rss"
puts "\nPreview of RSS feed:"
puts "=" * 50
puts rss_feed.to_s[0..1000] + "..."
