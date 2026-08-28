# frozen_string_literal: true

namespace :slack do
  desc "Sync Slack emojis"
  task sync_emojis: :environment do
    puts "Starting Slack emoji sync..."
    puts "Token: #{ENV["SLACK_BOT_TOKEN"] ? "Present (" + ENV["SLACK_BOT_TOKEN"][0..10] + "...)" : "MISSING!"}"

    SyncSlackEmojisJob.perform_now

    puts "Emoji count: #{SlackEmoji.count}"
    puts "\n=== Sample Emojis ==="
    SlackEmoji.limit(10).each do |emoji|
      puts "  #{emoji.name}: #{emoji.url[0..50]}..."
    end
  end
end

namespace :linear do
  desc "Import all data from Linear"
  task import: :environment do
    puts "Starting full Linear import..."
    puts "API Key: #{ENV["LINEAR_API_KEY"] ? "Present" : "MISSING!"}"

    importer = LinearImporter.new
    stats = importer.import_all

    puts "\n=== Import Complete ==="
    puts "Users: #{stats[:users]} (#{stats[:user_errors]} errors)"
    puts "Teams: #{stats[:teams]} (#{stats[:team_errors]} errors)"
    puts "Workflow States: #{stats[:workflow_states]} (#{stats[:workflow_state_errors]} errors)"
    puts "Labels: #{stats[:labels]} (#{stats[:label_errors]} errors)"
    puts "Projects: #{stats[:projects]} (#{stats[:project_errors]} errors)"
    puts "Project Updates: #{stats[:project_updates]} (#{stats[:project_update_errors]} errors)"
    puts "Cycles: #{stats[:cycles]} (#{stats[:cycle_errors]} errors)"
    puts "Issues: #{stats[:issues]} (#{stats[:issue_errors]} errors)"
    puts "Comments: #{stats[:comments]} (#{stats[:comment_errors]} errors)"
    puts "Issue Relations: #{stats[:issue_relations]} (#{stats[:issue_relation_errors]} errors)"
  end

  desc "Import changes from Linear since a specific time (default: 1 hour ago)"
  task :sync, [ :since ] => :environment do |_t, args|
    since = args[:since] ? Time.parse(args[:since]) : 1.hour.ago
    puts "Syncing changes since #{since}..."

    importer = LinearImporter.new
    stats = importer.import_changes_since(since)

    puts "\n=== Sync Complete ==="
    puts "Issues synced: #{stats[:issues]} (#{stats[:issue_errors]} errors)"
  end

  desc "Test Linear API connection"
  task test: :environment do
    puts "Testing Linear API connection..."

    client = LinearClient.new
    org = client.organization

    puts "Connected to organization: #{org["name"]} (#{org["urlKey"]})"

    # Get counts
    users = client.users.count
    teams = client.teams.count

    puts "Users: #{users}"
    puts "Teams: #{teams}"
    puts "\nConnection successful!"
  rescue StandardError => e
    puts "Error: #{e.message}"
    puts e.backtrace.first(5).join("\n")
  end

  desc "Show sync status"
  task status: :environment do
    puts "=== Sync Status ==="
    puts "Users: #{User.where.not(linear_id: nil).count} synced"
    puts "Teams: #{Team.where.not(linear_id: nil).count} synced"
    puts "Workflow States: #{WorkflowState.count} total"
    puts "Labels: #{Label.where.not(linear_id: nil).count} synced"
    puts "Projects: #{Project.where.not(linear_id: nil).count} synced"
    puts "Project Updates: #{ProjectUpdate.where.not(linear_id: nil).count} synced"
    puts "Cycles: #{Cycle.count} total"
    puts "Issues: #{Issue.where.not(linear_id: nil).count} synced"
    puts "Comments: #{Comment.where.not(linear_id: nil).count} synced"
    puts "Issue Relations: #{IssueRelation.count} total"
    puts "Team Memberships: #{TeamMembership.count} total"
    puts "Project Memberships: #{ProjectMembership.count} total"

    puts "\n=== Recent Sync Logs ==="
    SyncLog.recent.limit(10).each do |log|
      puts "#{log.created_at.strftime("%H:%M:%S")} - #{log.entity_type} #{log.action} (#{log.status})"
    end
  end

  desc "Import only users from Linear (for initial setup)"
  task import_users: :environment do
    puts "Starting Linear users import..."
    puts "API Key: #{ENV["LINEAR_API_KEY"] ? "Present" : "MISSING!"}"

    importer = LinearImporter.new
    importer.import_users

    puts "\n=== Users Import Complete ==="
    puts "Total users synced: #{User.where.not(linear_id: nil).count}"
    puts "Owners: #{User.owners.count}"
    puts "Admins: #{User.admins.count}"
    puts "Members: #{User.where(role: "member").count}"

    puts "\n=== Sample Users ==="
    User.where.not(linear_id: nil).limit(10).each do |user|
      puts "  #{user.email} - #{user.name} (#{user.role})"
    end
  end

  desc "List all synced users"
  task list_users: :environment do
    puts "=== Synced Users from Linear ==="
    puts ""

    User.where.not(linear_id: nil).order(:name).each do |user|
      status = []
      status << "OWNER" if user.owner?
      status << "admin" if user.admin? && !user.owner?
      status << "guest" if user.guest
      status << "inactive" unless user.active

      puts "#{user.name}"
      puts "  Email: #{user.email}"
      puts "  Display Name: #{user.display_name}" if user.display_name.present?
      puts "  Role: #{user.role}"
      puts "  Status: #{status.any? ? status.join(", ") : "active member"}"
      puts "  Teams: #{user.teams.pluck(:name).join(", ")}" if user.teams.any?
      puts ""
    end

    puts "Total: #{User.where.not(linear_id: nil).count} users"
  end
end
