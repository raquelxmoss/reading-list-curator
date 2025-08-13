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
end
