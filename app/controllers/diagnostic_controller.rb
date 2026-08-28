# frozen_string_literal: true

class DiagnosticController < ApplicationController
  # No authentication required for diagnostic endpoint

  def show
    # Sample project update to show data structure
    sample_update = ProjectUpdate.includes(:project, :user).first
    sample_data = if sample_update
                    {
                      id: sample_update.id,
                      body: sample_update.body&.truncate(100),
                      health: sample_update.health,
                      project: sample_update.project ? {
                        id: sample_update.project.id,
                        name: sample_update.project.name,
                        slug: sample_update.project.slug
                      } : nil,
                      user: sample_update.user ? {
                        id: sample_update.user.id,
                        name: sample_update.user.name,
                        email: sample_update.user.email
                      } : nil
                    }
    end

    render json: {
      status: "ok",
      counts: {
        users: User.count,
        teams: Team.count,
        team_memberships: TeamMembership.count,
        projects: Project.count,
        project_updates: ProjectUpdate.count,
        initiatives: safe_count(Initiative),
        issues: Issue.count,
        labels: Label.count,
        workflow_states: WorkflowState.count,
        cycles: Cycle.count,
        comments: Comment.count
      },
      linear_synced: {
        users: User.where.not(linear_id: nil).count,
        teams: Team.where.not(linear_id: nil).count,
        projects: Project.where.not(linear_id: nil).count,
        project_updates: ProjectUpdate.where.not(linear_id: nil).count,
        initiatives: safe_count(Initiative, linear_synced: true),
        issues: Issue.where.not(linear_id: nil).count,
        labels: Label.where.not(linear_id: nil).count,
        cycles: Cycle.where.not(linear_id: nil).count,
        comments: Comment.where.not(linear_id: nil).count,
        workflow_states: WorkflowState.where.not(linear_id: nil).count
      },
      sample_project_update: sample_data,
      timestamp: Time.current.iso8601
    }
  end

  # GET /diagnostic/user?email=xxx
  def user
    email = params[:email]
    user = User.includes(:teams, :team_memberships).find_by_email(email)

    if user
      render json: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        admin: user.admin?,
        owner: user.owner?,
        linear_id: user.linear_id,
        active: user.active,
        teams: user.teams.map { |t| { id: t.id, name: t.name, key: t.key } },
        team_count: user.teams.count
      }
    else
      render json: { error: "User not found" }, status: :not_found
    end
  end

  # POST /diagnostic/make_admin?email=xxx
  def make_admin
    email = params[:email]
    user = User.find_by_email(email)

    if user
      user.update!(role: "owner")
      render json: {
        message: "User #{email} is now owner",
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role
        }
      }
    else
      render json: { error: "User not found" }, status: :not_found
    end
  end

  # POST /diagnostic/merge_users
  # Merges source_email user INTO target_email user (keeps target, deletes source)
  # All associations from source are moved to target
  def merge_users
    source_email = params[:source_email]&.downcase
    target_email = params[:target_email]&.downcase

    source = User.find_by_email(source_email)
    target = User.find_by_email(target_email)

    if source.nil?
      return render json: { error: "Source user not found: #{source_email}" }, status: :not_found
    end
    if target.nil?
      return render json: { error: "Target user not found: #{target_email}" }, status: :not_found
    end
    if source.id == target.id
      return render json: { error: "Cannot merge user with itself" }, status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      # Transfer linear_id if target doesn't have one
      if target.linear_id.nil? && source.linear_id.present?
        linear_id_to_transfer = source.linear_id
        # First remove from source to avoid unique constraint violation
        source.update_column(:linear_id, nil)
        target.update!(linear_id: linear_id_to_transfer)
      end

      # Keep better name (not just email)
      if target.name == target.email && source.name != source.email
        target.update!(name: source.name)
      end

      # Keep avatar if target doesn't have one
      if target.avatar_url.blank? && source.avatar_url.present?
        target.update!(avatar_url: source.avatar_url)
      end

      # Transfer team memberships
      source.team_memberships.each do |tm|
        unless TeamMembership.exists?(user_id: target.id, team_id: tm.team_id)
          tm.update!(user_id: target.id)
        end
      end

      # Transfer project memberships
      source.project_memberships.each do |pm|
        unless ProjectMembership.exists?(user_id: target.id, project_id: pm.project_id)
          pm.update!(user_id: target.id)
        end
      end

      # Transfer led projects
      Project.where(lead_id: source.id).update_all(lead_id: target.id)

      # Transfer owned initiatives
      if Initiative.table_exists?
        Initiative.where(owner_id: source.id).update_all(owner_id: target.id)
      end

      # Transfer issues
      Issue.where(creator_id: source.id).update_all(creator_id: target.id)
      Issue.where(assignee_id: source.id).update_all(assignee_id: target.id)

      # Transfer comments
      Comment.where(user_id: source.id).update_all(user_id: target.id)

      # Transfer project updates
      ProjectUpdate.where(user_id: source.id).update_all(user_id: target.id)

      # Transfer activities
      IssueActivity.where(user_id: source.id).update_all(user_id: target.id)

      # Delete source user
      source.reload
      source.destroy!
    end

    render json: {
      message: "Merged #{source_email} into #{target_email}",
      user: {
        id: target.id,
        email: target.email,
        name: target.name,
        linear_id: target.linear_id,
        role: target.role
      }
    }
  rescue StandardError => e
    render json: { error: "Merge failed: #{e.message}" }, status: :internal_server_error
  end

  # POST /diagnostic/update_user_email
  # Updates a user's email (useful to change Linear email to login email)
  def update_user_email
    current_email = params[:current_email]&.downcase
    new_email = params[:new_email]&.downcase

    user = User.find_by_email(current_email)

    if user.nil?
      return render json: { error: "User not found: #{current_email}" }, status: :not_found
    end

    if User.find_by_email(new_email)
      return render json: { error: "Email already in use: #{new_email}. Use merge_users instead." }, status: :unprocessable_entity
    end

    user.update!(email: new_email)

    render json: {
      message: "Updated email from #{current_email} to #{new_email}",
      user: {
        id: user.id,
        email: user.email,
        name: user.name
      }
    }
  rescue StandardError => e
    render json: { error: "Update failed: #{e.message}" }, status: :internal_server_error
  end

  # GET /diagnostic/users?search=xxx
  def users
    search = params[:search]&.downcase

    users = if search.present?
              User.where("LOWER(email) LIKE ? OR LOWER(name) LIKE ?", "%#{search}%", "%#{search}%")
    else
              User.all
    end

    render json: {
      total: users.count,
      users: users.limit(100).map do |u|
        {
          id: u.id,
          email: u.email,
          name: u.name,
          role: u.role,
          linear_id: u.linear_id,
          has_linear: u.linear_id.present?
        }
      end
    }
  end

  # GET /diagnostic/initiatives
  def initiatives
    unless Initiative.table_exists?
      render json: { error: "Initiatives table does not exist" }
      return
    end

    status_counts = Initiative.group(:status).count
    sample_initiatives = Initiative.includes(:owner, :projects).limit(5).map do |init|
      {
        id: init.id,
        name: init.name,
        status: init.status,
        health: init.health,
        projects_count: init.projects.count,
        owner: init.owner&.name
      }
    end

    render json: {
      total: Initiative.count,
      by_status: status_counts,
      sample: sample_initiatives
    }
  end

  # GET /diagnostic/memberships
  def memberships
    teams_with_members = Team.includes(:members).map do |team|
      {
        id: team.id,
        name: team.name,
        key: team.key,
        member_count: team.members.count,
        members: team.members.limit(10).map { |m| { id: m.id, name: m.name, email: m.email } }
      }
    end

    render json: {
      total_teams: Team.count,
      total_memberships: TeamMembership.count,
      teams: teams_with_members
    }
  end

  # POST /diagnostic/unmerge_user
  # Separates a user that was incorrectly merged - creates new user with linear_id
  def unmerge_user
    email = params[:email]&.downcase
    new_email = params[:new_email]&.downcase
    linear_id = params[:linear_id]
    new_name = params[:new_name]

    if email.blank? || new_email.blank? || linear_id.blank? || new_name.blank?
      return render json: { error: "Required: email, new_email, linear_id, new_name" }, status: :unprocessable_entity
    end

    source = User.find_by_email(email)
    if source.nil?
      return render json: { error: "Source user not found: #{email}" }, status: :not_found
    end

    if User.find_by_email(new_email)
      return render json: { error: "Email already in use: #{new_email}" }, status: :unprocessable_entity
    end

    if source.linear_id != linear_id
      return render json: { error: "Linear ID mismatch. Source has: #{source.linear_id}, you provided: #{linear_id}" }, status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      # Remove linear_id from source
      source.update!(linear_id: nil, name: email.split("@").first.titleize)

      # Create new user with the linear_id
      new_user = User.create!(
        email: new_email,
        name: new_name,
        linear_id: linear_id,
        role: "member",
        active: true
      )

      render json: {
        message: "Unmerged successfully",
        source_user: {
          id: source.id,
          email: source.email,
          name: source.name,
          linear_id: source.linear_id
        },
        new_user: {
          id: new_user.id,
          email: new_user.email,
          name: new_user.name,
          linear_id: new_user.linear_id
        }
      }
    end
  rescue StandardError => e
    render json: { error: "Unmerge failed: #{e.message}" }, status: :internal_server_error
  end

  # POST /diagnostic/trigger_linear_sync
  # Triggers a full sync from Linear
  def trigger_linear_sync
    LinearImporter.new.import_all
    render json: { message: "Linear sync triggered" }
  rescue StandardError => e
    render json: { error: "Sync failed: #{e.message}" }, status: :internal_server_error
  end

  private

  # Safe count that returns 0 if table doesn't exist
  def safe_count(model, linear_synced: false)
    if linear_synced
      model.where.not(linear_id: nil).count
    else
      model.count
    end
  rescue ActiveRecord::StatementInvalid
    0
  end
end
