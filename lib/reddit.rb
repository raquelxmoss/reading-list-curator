# frozen_string_literal: true

require "httparty"

module Reddit
  SUB = "MoneyDiariesACTIVE"

  def self.search_threads
    q   = "title:%22Monthly%20Book%20Recommendation%20Thread%22"
    url = "https://www.reddit.com/r/#{SUB}/search.json?restrict_sr=on&sort=new&q=#{q}"

    headers = {
      "User-Agent" => ENV.fetch("REDDIT_USER_AGENT", "reading-list-curator/1.0 (by /u/raquelxmoss)"),
      "Accept" => "application/json",
      "Accept-Language" => "en-US,en;q=0.9",
      "Cache-Control" => "no-cache"
    }

    response = HTTParty.get(url, headers: headers)

    # Check if we got blocked (HTML response instead of JSON)
    if response.headers["content-type"]&.include?("text/html")
      puts "Warning: Reddit blocked the request. Response: #{response.body[0..200]}"
      return []
    end

    res = response.parsed_response
    return [] unless res.is_a?(Hash)

    posts = res.dig("data", "children") || []
    posts.map { |p| p.dig("data", "permalink") }.compact.uniq
  end

  def self.fetch_comments(permalink)
    url = "https://www.reddit.com#{permalink}.json?sort=top"

    headers = {
      "User-Agent" => ENV.fetch("REDDIT_USER_AGENT", "reading-list-curator/1.0 (by /u/raquelxmoss)"),
      "Accept" => "application/json",
      "Accept-Language" => "en-US,en;q=0.9",
      "Cache-Control" => "no-cache"
    }

    response = HTTParty.get(url, headers: headers)

    # Check if we got blocked
    if response.headers["content-type"]&.include?("text/html")
      puts "Warning: Reddit blocked the request for comments"
      return []
    end

    res = response.parsed_response
    return [] unless res.is_a?(Array)
    tree = res[1].dig("data","children") || []
    comments = flatten_comments(tree)
    comments
  end

  def self.fetch_comments_with_ids(permalink)
    url = "https://www.reddit.com#{permalink}.json?sort=top"

    headers = {
      "User-Agent" => ENV.fetch("REDDIT_USER_AGENT", "reading-list-curator/1.0 (by /u/raquelxmoss)"),
      "Accept" => "application/json",
      "Accept-Language" => "en-US,en;q=0.9",
      "Cache-Control" => "no-cache"
    }

    response = HTTParty.get(url, headers: headers)

    # Check if we got blocked
    if response.headers["content-type"]&.include?("text/html")
      puts "Warning: Reddit blocked the request for comments"
      return []
    end

    res = response.parsed_response
    return [] unless res.is_a?(Array)
    tree = res[1].dig("data","children") || []
    comments_with_ids = []
    flatten_comments_with_ids(tree, comments_with_ids)
    comments_with_ids
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
  
  def self.flatten_comments_with_ids(nodes, acc = [])
    nodes.each do |n|
      data = n["data"] || next
      if data["body"] && data["id"]
        acc << {
          id: data["id"],
          body: data["body"],
          created_utc: data["created_utc"]
        }
      end

      replies = data["replies"]
      if replies.is_a?(Hash)
        child_nodes = replies.dig("data", "children")
        flatten_comments_with_ids(child_nodes, acc) if child_nodes
      end
    end
    acc
  end
end
