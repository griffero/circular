# frozen_string_literal: true

namespace :counters do
  desc "Reset all counter caches"
  task reset: :environment do
    puts "Resetting counter caches..."

    # Reset project issues_count
    puts "  Resetting projects.issues_count..."
    Project.find_each do |project|
      Project.reset_counters(project.id, :issues)
    rescue StandardError => e
      puts "    Error for project #{project.id}: #{e.message}"
    end

    # Reset team issues_count
    puts "  Resetting teams.issues_count..."
    Team.find_each do |team|
      Team.reset_counters(team.id, :issues)
    rescue StandardError => e
      puts "    Error for team #{team.id}: #{e.message}"
    end

    # Reset issue comments_count
    puts "  Resetting issues.comments_count..."
    Issue.find_each do |issue|
      Issue.reset_counters(issue.id, :comments)
    rescue StandardError => e
      puts "    Error for issue #{issue.id}: #{e.message}"
    end

    # Reset issue sub_issues_count
    puts "  Resetting issues.sub_issues_count..."
    Issue.where.not(parent_id: nil).group(:parent_id).count.each do |parent_id, count|
      Issue.where(id: parent_id).update_all(sub_issues_count: count)
    end

    puts "Done!"
  end

  desc "Reset counter caches using raw SQL (faster for large datasets)"
  task reset_fast: :environment do
    puts "Resetting counter caches with SQL..."

    ActiveRecord::Base.connection.execute(<<~SQL)
      UPDATE projects SET issues_count = (
        SELECT COUNT(*) FROM issues WHERE issues.project_id = projects.id
      )
    SQL
    puts "  Projects done"

    ActiveRecord::Base.connection.execute(<<~SQL)
      UPDATE teams SET issues_count = (
        SELECT COUNT(*) FROM issues WHERE issues.team_id = teams.id
      )
    SQL
    puts "  Teams done"

    ActiveRecord::Base.connection.execute(<<~SQL)
      UPDATE issues SET comments_count = (
        SELECT COUNT(*) FROM comments WHERE comments.issue_id = issues.id
      )
    SQL
    puts "  Issue comments done"

    ActiveRecord::Base.connection.execute(<<~SQL)
      UPDATE issues SET sub_issues_count = (
        SELECT COUNT(*) FROM issues AS children WHERE children.parent_id = issues.id
      )
    SQL
    puts "  Issue sub_issues done"

    puts "Done!"
  end
end
