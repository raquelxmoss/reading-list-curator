# lib/google_books.rb
# frozen_string_literal: true

require "httparty"
require "uri"
require "fuzzystringmatch"

module GoogleBooks
  BASE_URL = "https://www.googleapis.com/books/v1/volumes"

  def self.search_book(args)
    title = args["title"]
    author = args["author"]
    query = author && !author.strip.empty? ? "#{title} by #{author}" : title
    encoded_query = URI.encode_www_form_component(query)
    url = "https://www.googleapis.com/books/v1/volumes?q=#{encoded_query}&orderBy=relevance"


    resp = HTTParty.get(url).parsed_response
    puts resp["items"][0]
    resp["items"][0] || []
  end
end