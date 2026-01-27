# frozen_string_literal: true

class DiagnosticController < ApplicationController
  # No authentication required for diagnostic endpoint

  def show
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
      timestamp: Time.current.iso8601
    }
  end
end
