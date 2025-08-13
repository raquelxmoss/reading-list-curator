# lib/extract.rb
# frozen_string_literal: true

module Extract
    # Simple heuristic to grab capitalised phrases that look like book titles
    POSSIBLE = /
      (?:["“])?                   # optional opening quote
      ([A-Z][\w’'&:.\- ]{2,})     # title-ish chunk
      (?:["”])?                   # optional closing quote
    /x
  
    STOP_WORDS = %w[Monthly Book Recommendation Thread MoneyDiariesACTIVE]
    TRASH = /\b(ISBN|ASIN|http|www\.|reddit|comment|spoiler)\b/i
  
    def self.titles_from_comments(comments)
      raw = comments.flat_map { |c| c.scan(POSSIBLE).flatten }
      raw
        .map { |t| t.strip.gsub(/\s+/, " ") }
        .reject { |t| t =~ %r{https?://|www\.} } # remove anything with a URL
        .reject { |t| t.length < 4 || t.length > 140 || t =~ TRASH }
        .reject { |t| STOP_WORDS.include?(t) }
        .uniq
    end
  end