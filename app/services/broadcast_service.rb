# frozen_string_literal: true

class BroadcastService
  class << self
    # Broadcast issue events to workspace channel
    def issue_created(issue)
      broadcast_to_workspace(issue.workspace_id, {
        type: "issue.created",
        issue: IssueSerializer.render_as_hash(issue, view: :normal)
      })

      broadcast_to_team(issue.team_id, {
        type: "issue.created",
        issue: IssueSerializer.render_as_hash(issue, view: :normal)
      })
    end

    def issue_updated(issue, changed_fields: [])
      broadcast_to_workspace(issue.workspace_id, {
        type: "issue.updated",
        issue: IssueSerializer.render_as_hash(issue, view: :normal),
        changed_fields: changed_fields
      })

      broadcast_to_team(issue.team_id, {
        type: "issue.updated",
        issue: IssueSerializer.render_as_hash(issue, view: :normal),
        changed_fields: changed_fields
      })

      # Also broadcast to issue-specific channel for detail view
      broadcast_to_issue(issue.id, {
        type: "issue.updated",
        issue: IssueSerializer.render_as_hash(issue, view: :detail),
        changed_fields: changed_fields
      })
    end

    def issue_deleted(issue)
      broadcast_to_workspace(issue.workspace_id, {
        type: "issue.deleted",
        issue_id: issue.id
      })

      broadcast_to_team(issue.team_id, {
        type: "issue.deleted",
        issue_id: issue.id
      })
    end

    # Broadcast comment events
    def comment_created(comment)
      issue = comment.issue

      broadcast_to_issue(issue.id, {
        type: "comment.created",
        comment: CommentSerializer.render_as_hash(comment, view: :normal)
      })

      # Notify mentioned users
      notify_mentions(comment) if comment.body.include?("@")
    end

    def comment_updated(comment)
      broadcast_to_issue(comment.issue_id, {
        type: "comment.updated",
        comment: CommentSerializer.render_as_hash(comment, view: :normal)
      })
    end

    def comment_deleted(comment)
      broadcast_to_issue(comment.issue_id, {
        type: "comment.deleted",
        comment_id: comment.id
      })
    end

    # Team events
    def team_created(team)
      broadcast_to_workspace(team.workspace_id, {
        type: "team.created",
        team: TeamSerializer.render_as_hash(team)
      })
    end

    def team_updated(team)
      broadcast_to_workspace(team.workspace_id, {
        type: "team.updated",
        team: TeamSerializer.render_as_hash(team)
      })
    end

    def team_deleted(team)
      broadcast_to_workspace(team.workspace_id, {
        type: "team.deleted",
        team_id: team.id
      })
    end

    # Project events
    def project_created(project)
      broadcast_to_workspace(project.workspace_id, {
        type: "project.created",
        project: ProjectSerializer.render_as_hash(project)
      })
    end

    def project_updated(project)
      broadcast_to_workspace(project.workspace_id, {
        type: "project.updated",
        project: ProjectSerializer.render_as_hash(project)
      })
    end

    def project_deleted(project)
      broadcast_to_workspace(project.workspace_id, {
        type: "project.deleted",
        project_id: project.id
      })
    end

    # Notifications
    def notify_user(user, notification)
      NotificationsChannel.broadcast_to(user, {
        type: "notification.created",
        notification: NotificationSerializer.render_as_hash(notification)
      })
    end

    private

    def broadcast_to_workspace(workspace_id, data)
      ActionCable.server.broadcast("workspace_#{workspace_id}", data)
    end

    def broadcast_to_team(team_id, data)
      ActionCable.server.broadcast("team_#{team_id}", data)
    end

    def broadcast_to_issue(issue_id, data)
      ActionCable.server.broadcast("issue_#{issue_id}", data)
    end

    def notify_mentions(comment)
      # Extract @username mentions and notify
      # This is a simplified version - production would parse properly
      mentioned_usernames = comment.body.scan(/@(\w+)/).flatten
      return if mentioned_usernames.empty?

      users = User.where("LOWER(name) IN (?)", mentioned_usernames.map(&:downcase))
      users.each do |user|
        # Skip the comment author
        next if user.id == comment.user_id

        NotificationsChannel.broadcast_to(user, {
          type: "mention",
          comment: CommentSerializer.render_as_hash(comment, view: :normal),
          issue: IssueSerializer.render_as_hash(comment.issue, view: :minimal)
        })
      end
    end
  end
end
