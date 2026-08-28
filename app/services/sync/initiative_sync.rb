# frozen_string_literal: true

module Sync
  class InitiativeSync < BaseSync
    class << self
      def upsert_from_linear(data)
        return nil unless data["id"]

        initiative = Initiative.find_or_initialize_by(linear_id: data["id"])
        action = initiative.new_record? ? "create" : "update"

        # Parse target date to get year/quarter
        target_year = nil
        target_quarter = nil
        if data["targetDate"]
          begin
            target_date = Date.parse(data["targetDate"])
            target_year = target_date.year
            target_quarter = ((target_date.month - 1) / 3) + 1
          rescue ArgumentError
            # Invalid date format, skip
          end
        end

        # Find owner
        owner = User.find_by(linear_id: data.dig("owner", "id")) if data.dig("owner", "id")

        # Map Linear status to our status
        status = map_status(data["status"])

        # Generate slug from slugId or name
        slug = data["slugId"].presence || data["name"].parameterize

        # Handle duplicate slugs
        if initiative.new_record?
          existing = Initiative.find_by(slug: slug)
          if existing && existing.linear_id != data["id"]
            slug = "#{slug}-#{SecureRandom.hex(4)}"
          end
        end

        initiative.assign_attributes(
          name: data["name"],
          slug: slug,
          description: data["description"],
          icon: data["icon"],
          color: data["color"],
          status: status,
          health: data["health"],
          target_year: target_year,
          target_quarter: target_quarter,
          target_date: data["targetDate"],
          sort_order: data["sortOrder"] || 0,
          owner: owner
        )

        if initiative.save
          # Sync project associations
          sync_projects(initiative, data.dig("projects", "nodes") || [])
          log_sync("Initiative", data["id"], action)
          initiative
        else
          Rails.logger.error "Failed to sync initiative #{data["id"]}: #{initiative.errors.full_messages.join(", ")}"
          nil
        end
      end

      def delete_from_linear(linear_id)
        initiative = Initiative.find_by(linear_id: linear_id)
        return unless initiative

        initiative.destroy!
        log_sync("Initiative", linear_id, "delete")
      end

      private

      def map_status(linear_status)
        case linear_status&.downcase
        when "planned" then "planned"
        when "started", "active", "inprogress" then "started"
        when "paused" then "paused"
        when "completed", "done" then "completed"
        when "canceled", "cancelled" then "canceled"
        else "backlog"
        end
      end

      def sync_projects(initiative, project_nodes)
        return if project_nodes.empty?

        linear_project_ids = project_nodes.map { |p| p["id"] }

        # Find all projects that exist in our system
        projects = Project.where(linear_id: linear_project_ids)

        # Clear existing associations and re-add
        initiative.initiative_projects.destroy_all

        projects.each_with_index do |project, index|
          InitiativeProject.create!(
            initiative: initiative,
            project: project,
            sort_order: index
          )
        end
      end
    end
  end
end
