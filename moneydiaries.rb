# moneydiaries.rb
# frozen_string_literal: true

require "dotenv/load"
require_relative "lib/reddit"
require_relative "lib/ai_extract"

puts "Fetching MoneyDiariesACTIVE monthly book rec threads..."
threads = Reddit.search_threads.first(1)
puts "Found #{threads.size} thread(s)."

all_comments = []

threads.each_with_index do |permalink, idx|
  puts "Thread ##{idx + 1}: #{permalink}"
  comments = Reddit.fetch_comments(permalink)
  puts "  → #{comments.size} comments"
  all_comments.concat(comments)
end

books = AIExtract.book_titles_from_comments(all_comments)
puts "Found #{books.size} books:"
puts books.first(10)

require_relative "lib/google_books"

enriched_books = books.first(3).map do |b|
    GoogleBooks.search_book(b)
  end.compact
  
  puts enriched_books.first(3) # quick check