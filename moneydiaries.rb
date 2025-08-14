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

books = AIExtract.book_titles_from_comments(all_comments)

# Mark these comments as seen for next run
deduper.mark_comments_seen(comment_ids)
puts "Marked #{comment_ids.size} comments as processed"

require_relative "lib/google_books"

enriched_books = books.map do |b|
  GoogleBooks.search_book(b)
end.compact

require_relative "lib/rss_generator"

rss_feed = RSSGenerator.generate_feed(enriched_books, {
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
