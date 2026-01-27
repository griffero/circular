# frozen_string_literal: true

module Sync
  class UserSync < BaseSync
    class << self
      def upsert_from_linear(data)
        user = User.find_or_initialize_by(linear_id: data["id"])
        action = user.new_record? ? "create" : "update"
        is_new = user.new_record?

        user.assign_attributes(
          email: data["email"],
          name: data["name"] || data["displayName"] || data["email"].split("@").first,
          display_name: data["displayName"],
          avatar_url: data["avatarUrl"],
          admin: data["admin"] || false,
          guest: data["guest"] || false,
          active: data["active"] != false,
          timezone: data["timezone"] || "UTC"
        )

        # Set role based on Linear admin status for new users
        if is_new
          user.role = if data["admin"]
                        # First admin becomes owner, rest are admins
                        User.owners.exists? ? "admin" : "owner"
                      else
                        "member"
                      end
        end

        user.save!
        log_sync("User", data["id"], action)
        user
      end

      def delete_from_linear(linear_id)
        user = User.find_by(linear_id: linear_id)
        return unless user

        # Don't actually delete users, just mark as inactive
        user.update!(active: false)
        log_sync("User", linear_id, "delete")
      end
    end
  end
end
