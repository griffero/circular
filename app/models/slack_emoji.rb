# frozen_string_literal: true

class SlackEmoji < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :url, presence: true

  # Check if this emoji is an alias to another
  def alias?
    alias_for.present?
  end

  # Get the resolved URL (follows alias if present)
  def resolved_url
    if alias?
      SlackEmoji.find_by(name: alias_for)&.url || url
    else
      url
    end
  end

  # Class method to get emoji URL by name
  # Handles the :emoji: format by stripping colons
  def self.url_for(name)
    return nil if name.blank?

    # Strip colons if present (e.g., ":elmo-fire:" -> "elmo-fire")
    clean_name = name.to_s.gsub(/^:|:$/, "")

    emoji = find_by(name: clean_name)
    emoji&.resolved_url
  end

  # Returns a hash of all emojis { name => url }
  # Resolves aliases to their actual URLs
  def self.all_as_hash
    emojis = all.index_by(&:name)

    emojis.transform_values do |emoji|
      if emoji.alias?
        emojis[emoji.alias_for]&.url || emoji.url
      else
        emoji.url
      end
    end
  end
end
