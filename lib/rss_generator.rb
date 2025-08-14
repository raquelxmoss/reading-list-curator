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
  
  private
  
  def self.format_title(book)
    title = book[:title] || "Unknown Title"
    author = book[:authors] || "Unknown Author"
    "#{title} by #{author}"
  end
  
  def self.format_description(book)
    parts = []
    
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