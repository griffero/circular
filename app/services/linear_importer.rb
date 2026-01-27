# frozen_string_literal: true

class LinearImporter
  attr_reader :client, :stats

  def initialize(api_key: ENV["LINEAR_API_KEY"])
    @client = LinearClient.new(api_key: api_key)
    @stats = Hash.new(0)
  end

  def import_all
    Rails.logger.info "Starting Linear import..."

    # Import in dependency order
    import_users
    import_teams
    import_workflow_states
    import_labels
    import_projects
    import_project_updates
    import_initiatives  # After projects so we can link them
    import_cycles
    import_issues
    import_comments
    import_issue_relations

    Rails.logger.info "Linear import completed!"
    Rails.logger.info "Stats: #{stats.inspect}"

    stats
  end

  def import_users
    Rails.logger.info "Importing users..."
    client.users.each do |data|
      Sync::UserSync.upsert_from_linear(data)
      @stats[:users] += 1
    rescue StandardError => e
      Rails.logger.error "Failed to import user #{data['id']}: #{e.message}"
      @stats[:user_errors] += 1
    end
    Rails.logger.info "Imported #{stats[:users]} users"
  end

  def import_teams
    Rails.logger.info "Importing teams..."
    client.teams.each do |data|
      Sync::TeamSync.upsert_from_linear(data)
      @stats[:teams] += 1
    rescue StandardError => e
      Rails.logger.error "Failed to import team #{data['id']}: #{e.message}"
      @stats[:team_errors] += 1
    end
    Rails.logger.info "Imported #{stats[:teams]} teams"
  end

  def import_workflow_states
    Rails.logger.info "Importing workflow states..."
    client.workflow_states.each do |data|
      Sync::WorkflowStateSync.upsert_from_linear(data)
      @stats[:workflow_states] += 1
    rescue StandardError => e
      Rails.logger.error "Failed to import workflow state #{data['id']}: #{e.message}"
      @stats[:workflow_state_errors] += 1
    end
    Rails.logger.info "Imported #{stats[:workflow_states]} workflow states"
  end

  def import_labels
    Rails.logger.info "Importing labels..."

    # First pass: import all labels without parents
    labels_data = client.labels.to_a

    # Sort to import parent labels first (groups and labels without parents)
    parent_labels = labels_data.select { |l| l["isGroup"] || l.dig("parent", "id").nil? }
    child_labels = labels_data.reject { |l| l["isGroup"] || l.dig("parent", "id").nil? }

    parent_labels.each do |data|
      Sync::LabelSync.upsert_from_linear(data)
      @stats[:labels] += 1
    rescue StandardError => e
      Rails.logger.error "Failed to import label #{data['id']}: #{e.message}"
      @stats[:label_errors] += 1
    end

    # Second pass: import child labels
    child_labels.each do |data|
      Sync::LabelSync.upsert_from_linear(data)
      @stats[:labels] += 1
    rescue StandardError => e
      Rails.logger.error "Failed to import label #{data['id']}: #{e.message}"
      @stats[:label_errors] += 1
    end

    Rails.logger.info "Imported #{stats[:labels]} labels"
  end

  def import_projects
    Rails.logger.info "Importing projects..."
    client.projects.each do |data|
      Sync::ProjectSync.upsert_from_linear(data)
      @stats[:projects] += 1
    rescue StandardError => e
      Rails.logger.error "Failed to import project #{data['id']}: #{e.message}"
      @stats[:project_errors] += 1
    end
    Rails.logger.info "Imported #{stats[:projects]} projects"
  end

  def import_project_updates
    Rails.logger.info "Importing project updates..."
    client.project_updates.each do |data|
      Sync::ProjectUpdateSync.upsert_from_linear(data)
      @stats[:project_updates] += 1
    rescue StandardError => e
      Rails.logger.error "Failed to import project update #{data['id']}: #{e.message}"
      @stats[:project_update_errors] += 1
    end
    Rails.logger.info "Imported #{stats[:project_updates]} project updates"
  end

  def import_initiatives
    Rails.logger.info "Importing initiatives..."
    sync = Sync::InitiativeSync.new(client)
    count = sync.sync_all
    @stats[:initiatives] = count
    Rails.logger.info "Imported #{count} initiatives"
  rescue StandardError => e
    Rails.logger.error "Failed to import initiatives: #{e.message}"
    @stats[:initiative_errors] = 1
  end

  def import_cycles
    Rails.logger.info "Importing cycles..."
    client.cycles.each do |data|
      Sync::CycleSync.upsert_from_linear(data)
      @stats[:cycles] += 1
    rescue StandardError => e
      Rails.logger.error "Failed to import cycle #{data['id']}: #{e.message}"
      @stats[:cycle_errors] += 1
    end
    Rails.logger.info "Imported #{stats[:cycles]} cycles"
  end

  def import_issues
    Rails.logger.info "Importing issues..."

    # Collect all issues first
    issues_data = client.issues.to_a

    # Sort to import parent issues first
    parent_issues = issues_data.reject { |i| i.dig("parent", "id") }
    child_issues = issues_data.select { |i| i.dig("parent", "id") }

    Rails.logger.info "Importing #{parent_issues.count} parent issues..."
    parent_issues.each do |data|
      Sync::IssueSync.upsert_from_linear(data)
      @stats[:issues] += 1
    rescue StandardError => e
      Rails.logger.error "Failed to import issue #{data['id']}: #{e.message}"
      @stats[:issue_errors] += 1
    end

    Rails.logger.info "Importing #{child_issues.count} child issues..."
    child_issues.each do |data|
      Sync::IssueSync.upsert_from_linear(data)
      @stats[:issues] += 1
    rescue StandardError => e
      Rails.logger.error "Failed to import issue #{data['id']}: #{e.message}"
      @stats[:issue_errors] += 1
    end

    Rails.logger.info "Imported #{stats[:issues]} issues"
  end

  def import_comments
    Rails.logger.info "Importing comments..."

    # Collect all comments
    comments_data = client.comments.to_a

    # Sort to import parent comments first
    parent_comments = comments_data.reject { |c| c.dig("parent", "id") }
    child_comments = comments_data.select { |c| c.dig("parent", "id") }

    parent_comments.each do |data|
      Sync::CommentSync.upsert_from_linear(data)
      @stats[:comments] += 1
    rescue StandardError => e
      Rails.logger.error "Failed to import comment #{data['id']}: #{e.message}"
      @stats[:comment_errors] += 1
    end

    child_comments.each do |data|
      Sync::CommentSync.upsert_from_linear(data)
      @stats[:comments] += 1
    rescue StandardError => e
      Rails.logger.error "Failed to import comment #{data['id']}: #{e.message}"
      @stats[:comment_errors] += 1
    end

    Rails.logger.info "Imported #{stats[:comments]} comments"
  end

  def import_issue_relations
    Rails.logger.info "Importing issue relations..."
    client.issue_relations.each do |data|
      Sync::IssueRelationSync.upsert_from_linear(data)
      @stats[:issue_relations] += 1
    rescue StandardError => e
      Rails.logger.error "Failed to import issue relation #{data['id']}: #{e.message}"
      @stats[:issue_relation_errors] += 1
    end
    Rails.logger.info "Imported #{stats[:issue_relations]} issue relations"
  end

  # Import updated data since a specific time
  def import_changes_since(time)
    Rails.logger.info "Importing changes since #{time}..."

    # For incremental sync, only sync issues and their related data
    client.issues(updated_after: time).each do |data|
      Sync::IssueSync.upsert_from_linear(data)
      @stats[:issues] += 1
    rescue StandardError => e
      Rails.logger.error "Failed to sync issue #{data['id']}: #{e.message}"
      @stats[:issue_errors] += 1
    end

    Rails.logger.info "Synced #{stats[:issues]} issues"
    stats
  end
end
