# frozen_string_literal: true

require "rss"
require "time"

module RSSGenerator
  def self.generate_feed(books, options = {})
    title = options[:title] || "Reading List Recommendations"
    description = options[:description] || "Book recommendations curated from Reddit"
    link = options[:link] || "https://example.com"

    RSS::Maker.make("2.0") do |maker|
      maker.channel.title = title
      maker.channel.description = description
      maker.channel.link = link
      maker.channel.updated = Time.now.to_s

      books.each do |book|
        maker.items.new_item do |item|
          item.title = format_title(book)
          item.link = book[:google_books_link] || link
          item.description = format_description(book)
          item.pubDate = parse_date(book[:published_date])
          item.guid.content = book[:isbn] || "#{book[:title]}-#{book[:authors]}".downcase.gsub(/\s+/, '-')
          item.guid.isPermaLink = false

          # Add enclosure for book thumbnail if available
          if book[:thumbnail]
            item.enclosure.url = book[:thumbnail]
            item.enclosure.type = "image/jpeg"
            item.enclosure.length = 0  # Size unknown
          end
        end
      end
    end
  end

  def self.load_existing_feed(file_path)
    return [] unless File.exist?(file_path)

    begin
      rss = RSS::Parser.parse(File.read(file_path))
      rss.items.map do |item|
        {
          title: extract_title_from_formatted(item.title),
          authors: extract_author_from_formatted(item.title),
          google_books_link: item.link,
          description: extract_description_from_html(item.description),
          published_date: item.pubDate ? item.pubDate.strftime('%Y-%m-%d') : nil,
          isbn: item.guid.content.match(/^\d+$/) ? item.guid.content : nil,
          thumbnail: item.enclosure ? item.enclosure.url : nil,
          categories: extract_categories_from_html(item.description),
          page_count: extract_page_count_from_html(item.description),
          sentiment: extract_sentiment_from_html(item.description),
          review_summary: extract_review_summary_from_html(item.description)
        }
      end
    rescue => e
      puts "Warning: Could not parse existing RSS feed: #{e.message}"
      []
    end
  end

  def self.merge_and_generate_feed(new_books, existing_file_path, options = {})
    existing_books = load_existing_feed(existing_file_path)
    existing_isbns = existing_books.map { |book| book[:isbn] }.compact.to_set
    existing_titles = existing_books.map { |book| "#{book[:title]}-#{book[:authors]}".downcase }.to_set

    # Filter out duplicates based on ISBN or title+author
    unique_new_books = new_books.reject do |book|
      isbn_match = book[:isbn] && existing_isbns.include?(book[:isbn])
      title_match = existing_titles.include?("#{book[:title]}-#{book[:authors]}".downcase)
      isbn_match || title_match
    end

    puts "Found #{unique_new_books.size} new unique books to add (#{new_books.size - unique_new_books.size} duplicates filtered out)"

    all_books = existing_books + unique_new_books
    generate_feed(all_books, options)
  end
  
  private

  def self.extract_title_from_formatted(formatted_title)
    # Extract title from "Title by Author" format
    formatted_title.split(' by ').first
  end

  def self.extract_author_from_formatted(formatted_title)
    # Extract author from "Title by Author" format
    parts = formatted_title.split(' by ')
    parts.length > 1 ? parts.last : "Unknown Author"
  end

  def self.extract_description_from_html(html_description)
    # Extract the main description text from HTML
    return nil unless html_description

    match = html_description.match(/<strong>Description:<\/strong>\s*([^<]+)/m)
    match ? match[1].strip.gsub(/\.\.\.$/, '') : nil
  end

  def self.extract_categories_from_html(html_description)
    # Extract categories from HTML description
    return nil unless html_description

    match = html_description.match(/Categories:\s*([^<]+)/m)
    match ? match[1].strip : nil
  end

  def self.extract_page_count_from_html(html_description)
    # Extract page count from HTML description
    return nil unless html_description

    match = html_description.match(/Pages:\s*(\d+)/m)
    match ? match[1].to_i : nil
  end

  def self.extract_sentiment_from_html(html_description)
    # Extract sentiment from HTML description (for existing feeds)
    return nil unless html_description

    if html_description.include?("Community Review 👍")
      "positive"
    elsif html_description.include?("Community Review 👎")
      "negative"
    elsif html_description.include?("Community Review 📖")
      "neutral"
    else
      nil
    end
  end

  def self.extract_review_summary_from_html(html_description)
    # Extract review summary from HTML description (for existing feeds)
    return nil unless html_description

    match = html_description.match(/<strong>Community Review [👍👎📖]:<\/strong>\s*([^<]+)/m)
    match ? match[1].strip : nil
  end

  def self.format_title(book)
    title = book[:title] || "Unknown Title"
    author = book[:authors] || "Unknown Author"
    "#{title} by #{author}"
  end
  
  def self.format_description(book)
    parts = []

    # Add sentiment flag and review summary if available
    if book[:review_summary] && book[:sentiment]
      sentiment_emoji = case book[:sentiment]
                       when "positive" then "👍"
                       when "negative" then "👎"
                       else "📖"
                       end

      parts << "<p><strong>Community Review #{sentiment_emoji}:</strong> #{book[:review_summary]}</p>"

      if book[:original_comment]
        parts << "<p><em>\"#{book[:original_comment]}\"</em></p>"
      end
    end

    # Add main description (truncated if too long)
    if book[:description]
      truncated = book[:description].length > 300 ?
        "#{book[:description][0..297]}..." :
        book[:description]
      parts << "<p><strong>Description:</strong> #{truncated}</p>"
    end

    # Add book metadata
    metadata = []
    metadata << "Published: #{book[:published_date]}" if book[:published_date]
    metadata << "Pages: #{book[:page_count]}" if book[:page_count] && book[:page_count] > 0
    metadata << "Categories: #{Array(book[:categories]).join(', ')}" if book[:categories]
    metadata << "ISBN: #{book[:isbn]}" if book[:isbn]

    if metadata.any?
      parts << "<p><strong>Details:</strong><br/>#{metadata.join('<br/>')}</p>"
    end

    # Add thumbnail image
    if book[:thumbnail]
      parts << "<p><img src=\"#{book[:thumbnail]}\" alt=\"#{book[:title]} cover\" style=\"max-width: 200px;\"/></p>"
    end

    # Add Goodreads link if we have ISBN
    if book[:isbn]
      parts << "<p><a href=\"https://www.goodreads.com/book/isbn/#{book[:isbn]}\">📚 Add to Goodreads</a></p>"
    end

    parts.join("\n")
  end
  
  def self.parse_date(date_string)
    return Time.now unless date_string
    
    begin
      # Handle various date formats from Google Books
      case date_string
      when /^\d{4}$/  # Year only
        Time.parse("#{date_string}-01-01")
      when /^\d{4}-\d{2}$/  # Year-month
        Time.parse("#{date_string}-01")
      else
        Time.parse(date_string)
      end
    rescue
      Time.now
    end
  end
end