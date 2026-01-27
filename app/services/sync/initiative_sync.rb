# frozen_string_literal: true

module Sync
  class InitiativeSync < BaseSync
    def sync_all
      Rails.logger.info "Starting initiative sync..."
      count = 0
      skipped = 0

      client.initiatives.each do |data|
        initiative = sync_one(data)
        if initiative
          count += 1
        else
          skipped += 1
        end
      end

      Rails.logger.info "Initiative sync complete: #{count} synced, #{skipped} skipped"
      count
    end

    def sync_one(data)
      return nil unless data["id"]

      initiative = Initiative.find_or_initialize_by(linear_id: data["id"])

      # Parse target date to get year/quarter
      target_year = nil
      target_quarter = nil
      if data["targetDate"]
        target_date = Date.parse(data["targetDate"])
        target_year = target_date.year
        target_quarter = ((target_date.month - 1) / 3) + 1
      end

      # Find owner
      owner = User.find_by(linear_id: data.dig("owner", "id")) if data.dig("owner", "id")

      # Map Linear status to our status
      status = map_status(data["status"])

      initiative.assign_attributes(
        name: data["name"],
        slug: data["slugId"] || data["name"].parameterize,
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
        initiative
      else
        Rails.logger.error "Failed to sync initiative #{data['id']}: #{initiative.errors.full_messages.join(', ')}"
        nil
      end
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
