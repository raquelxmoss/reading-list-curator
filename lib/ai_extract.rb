# lib/ai_extract.rb
# frozen_string_literal: true

require "httparty"
require "json"

module AIExtract
  def self.book_titles_from_comments(comments)
    raise "Missing OPENAI_API_KEY" unless ENV["OPENAI_API_KEY"]

    results = []

    comments.each_slice(30) do |batch|
      prompt = <<~PROMPT
        Extract all distinct book titles from the following Reddit comments.
        Only include real, published books (fiction or non-fiction).
        If the author is mentioned in the comments, include it in the "author" field.
        If the author is not mentioned, try to guess based on context or leave it blank ("").
        Lean towards newer releases and popular authors when guessing.
        Comments might contain slight errors in titles (like an extra "The" or "A") or use acronyms (e.g., ACOTAR).
        Output ONLY a valid JSON array of objects with this exact structure:
        [
          { "title": "Book Title", "author": "Author Name or blank" },
          { "title": "Another Book", "author": "" }
        ]
        No explanations, no extra text, no Markdown formatting.

        Comments:
        #{batch.join("\n")}
      PROMPT

      resp = HTTParty.post(
        "https://api.openai.com/v1/chat/completions",
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{ENV["OPENAI_API_KEY"]}"
        },
        body: {
          model: "gpt-4o-mini",
          messages: [{ role: "user", content: prompt }],
          temperature: 0
        }.to_json
      )

      content = resp.parsed_response.dig("choices", 0, "message", "content") || "[]"

      # Strip Markdown code fences like ```json ... ```
      content = content.gsub(/\A```(?:json)?\s*/m, "").gsub(/```$/m, "").strip

      begin
        arr = JSON.parse(content)
        if arr.is_a?(Array)
          results.concat(arr.select { |obj| obj.is_a?(Hash) && obj["title"] })
        else
          warn "⚠️ AI output was not an array: #{content.inspect}"
        end
      rescue JSON::ParserError
        warn "⚠️ Could not parse AI output: #{content.inspect}"
      end
    end

    # De-dup by title+author (case-insensitive)
    seen = {}
    results.select do |obj|
      key = "#{obj['title']}|#{obj['author']}".downcase
      !seen[key] && (seen[key] = true)
    end
  end

  def self.extract_reviews_and_sentiment(comments)
    raise "Missing OPENAI_API_KEY" unless ENV["OPENAI_API_KEY"]

    results = []

    comments.each_slice(20) do |batch|
      prompt = <<~PROMPT
        Analyze the following Reddit comments for book recommendations. For each book mentioned:

        1. Extract the book title and author (if mentioned)
        2. Determine sentiment: "positive", "negative", or "neutral"
        3. If positive, create a 1-2 sentence summary of why they recommend it
        4. If negative, create a 1-2 sentence summary of their criticism
        5. If neutral, provide a brief factual summary

        Only include comments that actually discuss or recommend books.

        Output ONLY a valid JSON array with this exact structure:
        [
          {
            "title": "Book Title",
            "author": "Author Name or blank",
            "sentiment": "positive",
            "review_summary": "Brief summary of their recommendation",
            "original_comment": "Relevant excerpt from original comment"
          }
        ]

        Comments:
        #{batch.join("\n\n---\n\n")}
      PROMPT

      resp = HTTParty.post(
        "https://api.openai.com/v1/chat/completions",
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{ENV["OPENAI_API_KEY"]}"
        },
        body: {
          model: "gpt-4o-mini",
          messages: [{ role: "user", content: prompt }],
          temperature: 0.1
        }.to_json
      )

      content = resp.parsed_response.dig("choices", 0, "message", "content") || "[]"
      content = content.gsub(/\A```(?:json)?\s*/m, "").gsub(/```$/m, "").strip

      begin
        arr = JSON.parse(content)
        if arr.is_a?(Array)
          results.concat(arr.select { |obj| obj.is_a?(Hash) && obj["title"] })
        else
          warn "⚠️ AI review analysis output was not an array: #{content.inspect}"
        end
      rescue JSON::ParserError
        warn "⚠️ Could not parse AI review analysis output: #{content.inspect}"
      end
    end

    # De-dup by title+author (case-insensitive)
    seen = {}
    results.select do |obj|
      key = "#{obj['title']}|#{obj['author']}".downcase
      !seen[key] && (seen[key] = true)
    end
  end
end
