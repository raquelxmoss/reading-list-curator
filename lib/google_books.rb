# frozen_string_literal: true

require "httparty"
require "uri"

module GoogleBooks
  BASE_URL = "https://www.googleapis.com/books/v1/volumes"

  def self.search_book(query)
    return nil if query.nil? || !query.is_a?(Hash) || query.empty?

    # Build search query from hash
    parts = []
    parts << "intitle:#{query['title']}" if query['title'] && !query['title'].empty?
    parts << "inauthor:#{query['author']}" if query['author'] && !query['author'].empty?
    search_query = parts.join('+')

    params = {
      q: search_query,
      country: "US",
      maxResults: 1
    }

    url = "#{BASE_URL}?#{URI.encode_www_form(params)}"

    begin
      response = HTTParty.get(url, headers: {"User-Agent" => "reading-list-curator"})

      return nil unless response.code == 200

      data = response.parsed_response
      return nil unless data["totalItems"] && data["totalItems"] > 0

      item = data["items"].first
      volume_info = item["volumeInfo"]

      {
        title: volume_info["title"],
        authors: volume_info["authors"]&.join(", "),
        published_date: volume_info["publishedDate"],
        description: volume_info["description"],
        page_count: volume_info["pageCount"],
        categories: volume_info["categories"],
        isbn: volume_info["industryIdentifiers"]&.find { |id| id["type"] == "ISBN_13" }&.dig("identifier"),
        google_books_link: volume_info["infoLink"],
        thumbnail: volume_info["imageLinks"]&.dig("thumbnail")
      }
    rescue => e
      puts "Error searching for book: #{e.message}"
      nil
    end
  end
end
