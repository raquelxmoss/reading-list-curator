# frozen_string_literal: true

require "httparty"

module Reddit
  SUB = "MoneyDiariesACTIVE"

  def self.search_threads
    q   = "title:%22Monthly%20Book%20Recommendation%20Thread%22"
    url = "https://www.reddit.com/r/#{SUB}/search.json?restrict_sr=on&sort=new&q=#{q}"
    res = HTTParty.get(url, headers: {"User-Agent" => ENV.fetch("REDDIT_USER_AGENT", "md-curator")}).parsed_response
    posts = res.dig("data", "children") || []
    posts.map { |p| p.dig("data", "permalink") }.compact.uniq
  end

  def self.fetch_comments(permalink)
    url = "https://www.reddit.com#{permalink}.json?sort=top"
    res = HTTParty.get(url, headers: {"User-Agent" => ENV.fetch("REDDIT_USER_AGENT", "md-curator")}).parsed_response
    return [] unless res.is_a?(Array)
    tree = res[1].dig("data","children") || []
    comments = flatten_comments(tree)
    comments
  end

  def self.flatten_comments(nodes, acc = [])
    nodes.each do |n|
      data = n["data"] || next
      acc << data["body"] if data["body"]

      replies = data["replies"]
      if replies.is_a?(Hash)
        child_nodes = replies.dig("data", "children")
        flatten_comments(child_nodes, acc) if child_nodes
      end
    end
    acc
  end
end