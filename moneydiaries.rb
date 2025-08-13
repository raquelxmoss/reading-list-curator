# moneydiaries.rb
# frozen_string_literal: true

require "dotenv/load"
require_relative "lib/reddit"
require_relative "lib/ai_extract"

puts "Fetching MoneyDiariesACTIVE monthly book rec threads..."
threads = Reddit.search_threads.first(1)

all_comments = []

threads.each_with_index do |permalink, idx|
  comments = Reddit.fetch_comments(permalink)
  all_comments.concat(comments)
end

books = AIExtract.book_titles_from_comments(all_comments)

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
