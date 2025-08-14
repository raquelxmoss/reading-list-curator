# frozen_string_literal: true

require "json"
require "time"

class Deduper
  TRACKING_FILE = "dedup_tracking.json"

  def initialize
    @data = load_tracking_data
  end

  def seen_comment?(comment_id)
    @data["seen_comment_ids"].include?(comment_id)
  end

  def mark_comments_seen(comment_ids)
    @data["seen_comment_ids"].concat(comment_ids).uniq!
    @data["last_processed_at"] = Time.now.iso8601
    save_tracking_data
  end

  def filter_new_comments(comments_with_ids)
    new_comments = comments_with_ids.reject { |c| seen_comment?(c[:id]) }
    puts "Found #{new_comments.size} new comments (out of #{comments_with_ids.size} total)"
    new_comments
  end

  def stats
    {
      total_seen_comments: @data["seen_comment_ids"].size,
      last_processed: @data["last_processed_at"],
      tracking_since: @data["started_tracking_at"]
    }
  end

  private

  def load_tracking_data
    if File.exist?(TRACKING_FILE)
      JSON.parse(File.read(TRACKING_FILE))
    else
      {
        "seen_comment_ids" => [],
        "last_processed_at" => nil,
        "started_tracking_at" => Time.now.iso8601
      }
    end
  end

  def save_tracking_data
    File.write(TRACKING_FILE, JSON.pretty_generate(@data))
  end
end
