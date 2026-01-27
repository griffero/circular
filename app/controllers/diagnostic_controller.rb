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
        projects: Project.count,
        project_updates: ProjectUpdate.count,
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
        issues: Issue.where.not(linear_id: nil).count,
        labels: Label.where.not(linear_id: nil).count
      },
      sample_project_update: sample_data,
      timestamp: Time.current.iso8601
    }
  end
end
