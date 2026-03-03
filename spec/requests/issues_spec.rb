# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Issues API" do
  let(:user) { create(:user, email: "dev@fintoc.com") }

  before do
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe "POST /api/v1/issues" do
    let(:team) { create(:team, key: "ENG") }

    it "creates a new issue" do
      expect do
        post "/api/v1/issues",
             params: {
               team_id: team.id,
               issue: {
                 title: "Fix auth race condition",
                 description: "Flaky login in edge case",
                 priority: 2
               }
             }
      end.to change(Issue, :count).by(1)

      expect(response).to have_http_status(:created)
      created_issue = Issue.last
      expect(created_issue.team_id).to eq(team.id)
      expect(created_issue.title).to eq("Fix auth race condition")
      expect(created_issue.priority).to eq(2)
      expect(IssueSubscription.exists?(issue_id: created_issue.id, user_id: user.id)).to be(true)
    end
  end

  describe "PATCH /api/v1/issues/:id" do
    let(:team) { create(:team, key: "API") }
    let(:issue) { create(:issue, team: team, creator: user, status: "todo") }
    let(:started_state) { create(:workflow_state, team: team, name: "In Progress", state_type: "started", position: 20.0) }
    let(:assignee) { create(:user, email: "assignee-flow@fintoc.com") }
    let(:cycle) do
      create(
        :cycle,
        team: team,
        number: 1,
        starts_at: Time.current.beginning_of_week,
        ends_at: Time.current.end_of_week
      )
    end

    it "updates workflow_state and cycle fields" do
      patch "/api/v1/issues/#{issue.id}",
            params: {
              issue: {
                workflow_state_id: started_state.id,
                cycle_id: cycle.id,
                title: "Updated title"
              }
            }

      expect(response).to have_http_status(:ok)
      issue.reload
      expect(issue.workflow_state_id).to eq(started_state.id)
      expect(issue.cycle_id).to eq(cycle.id)
      expect(issue.title).to eq("Updated title")
      expect(issue.status).to eq("in_progress")
    end

    it "updates key fields used in issue detail editing" do
      patch "/api/v1/issues/#{issue.id}",
            params: {
              issue: {
                title: "New heading",
                description: "Updated details for this issue"
              }
            }

      expect(response).to have_http_status(:ok)
      issue.reload
      expect(issue.title).to eq("New heading")
      expect(issue.description).to eq("Updated details for this issue")
    end

    it "supports assign and unassign flow" do
      patch "/api/v1/issues/#{issue.id}",
            params: {
              issue: {
                assignee_id: assignee.id
              }
            }
      expect(response).to have_http_status(:ok)
      issue.reload
      expect(issue.assignee_id).to eq(assignee.id)
      expect(IssueSubscription.exists?(issue_id: issue.id, user_id: assignee.id)).to be(true)

      patch "/api/v1/issues/#{issue.id}",
            params: {
              issue: {
                assignee_id: nil
              }
            }
      expect(response).to have_http_status(:ok)
      issue.reload
      expect(issue.assignee_id).to be_nil
    end
  end

  describe "DELETE /api/v1/issues/:id" do
    let(:team) { create(:team, key: "DEL") }
    let!(:issue) { create(:issue, team: team, creator: user) }

    it "deletes an issue" do
      expect do
        delete "/api/v1/issues/#{issue.id}"
      end.to change(Issue, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end

  describe "Issue detail activity comments" do
    let(:team) { create(:team, key: "CMT") }
    let(:issue) { create(:issue, team: team, creator: user, title: "Comment target") }

    it "returns comments for an issue" do
      older = create(:comment, issue: issue, user: user, body: "First note", created_at: 2.minutes.ago)
      newer = create(:comment, issue: issue, user: user, body: "Second note", created_at: 1.minute.ago)

      get "/api/v1/issues/#{issue.id}/comments"

      expect(response).to have_http_status(:ok)
      ids = json_response[:comments].map { |item| item[:id] }
      expect(ids).to eq([older.id, newer.id])
    end

    it "creates a comment for an issue" do
      expect do
        post "/api/v1/issues/#{issue.id}/comments",
             params: {
               comment: {
                 body: "This needs follow-up"
               }
             }
      end.to change(Comment, :count).by(1)

      expect(response).to have_http_status(:created)
      created = Comment.order(:created_at).last
      expect(created.issue_id).to eq(issue.id)
      expect(created.user_id).to eq(user.id)
      expect(created.body).to eq("This needs follow-up")
    end
  end

  describe "GET /api/v1/issues" do
    let(:team_a) { create(:team, key: "TMA") }
    let(:team_b) { create(:team, key: "TMB") }
    let(:backlog_state) { create(:workflow_state, team: team_a, name: "Backlog", state_type: "backlog", position: 10.0) }
    let(:started_state) { create(:workflow_state, team: team_a, name: "Started", state_type: "started", position: 20.0) }
    let(:assignee) { create(:user, email: "assignee@fintoc.com") }

    it "filters by team_id" do
      issue_a = create(:issue, team: team_a, creator: user, title: "Team A issue")
      create(:issue, team: team_b, creator: user, title: "Team B issue")

      get "/api/v1/issues", params: { team_id: team_a.id }

      expect(response).to have_http_status(:ok)
      titles = json_response[:issues].map { |item| item[:title] }
      expect(titles).to contain_exactly(issue_a.title)
    end

    it "filters unassigned issues" do
      unassigned = create(:issue, team: team_a, creator: user, assignee: nil, title: "No owner")
      create(:issue, team: team_a, creator: user, assignee: assignee, title: "Has owner")

      get "/api/v1/issues", params: { team_id: team_a.id, assignee_id: "unassigned" }

      expect(response).to have_http_status(:ok)
      ids = json_response[:issues].map { |item| item[:id] }
      expect(ids).to contain_exactly(unassigned.id)
    end

    it "filters by workflow_state_id" do
      started_issue = create(:issue, team: team_a, creator: user, workflow_state: started_state, title: "Started issue")
      create(:issue, team: team_a, creator: user, workflow_state: backlog_state, title: "Backlog issue")

      get "/api/v1/issues", params: { team_id: team_a.id, workflow_state_id: started_state.id }

      expect(response).to have_http_status(:ok)
      ids = json_response[:issues].map { |item| item[:id] }
      expect(ids).to contain_exactly(started_issue.id)
    end

    it "filters by workflow_state_type triage/backlog as distinct sub-views" do
      triage_state = create(:workflow_state, team: team_a, name: "Triage", state_type: "triage", position: 5.0)
      backlog_issue = create(:issue, team: team_a, creator: user, workflow_state: backlog_state, status: "backlog", title: "Backlog state")
      triage_issue = create(:issue, team: team_a, creator: user, workflow_state: triage_state, status: "backlog", title: "Triage state")
      create(:issue, team: team_a, creator: user, workflow_state: started_state, status: "in_progress", title: "Started state")

      get "/api/v1/issues", params: { team_id: team_a.id, workflow_state_type: "triage" }
      expect(response).to have_http_status(:ok)
      triage_ids = json_response[:issues].map { |item| item[:id] }
      expect(triage_ids).to contain_exactly(triage_issue.id)

      get "/api/v1/issues", params: { team_id: team_a.id, workflow_state_type: "backlog" }
      expect(response).to have_http_status(:ok)
      backlog_ids = json_response[:issues].map { |item| item[:id] }
      expect(backlog_ids).to contain_exactly(backlog_issue.id)
    end

    it "keeps legacy backlog issues without workflow_state in backlog filter" do
      legacy_backlog = create(:issue, team: team_a, creator: user, workflow_state: nil, status: "backlog", title: "Legacy backlog")
      create(:issue, team: team_a, creator: user, workflow_state: nil, status: "todo", title: "Legacy todo")

      get "/api/v1/issues", params: { team_id: team_a.id, workflow_state_type: "backlog" }

      expect(response).to have_http_status(:ok)
      ids = json_response[:issues].map { |item| item[:id] }
      expect(ids).to include(legacy_backlog.id)
    end

    it "applies assignee, status, and priority filters together" do
      matching_issue = create(
        :issue,
        team: team_a,
        creator: user,
        assignee: assignee,
        status: "todo",
        priority: 2,
        title: "Matching issue"
      )
      create(:issue, team: team_a, creator: user, assignee: assignee, status: "todo", priority: 4, title: "Wrong priority")
      create(:issue, team: team_a, creator: user, assignee: assignee, status: "done", priority: 2, title: "Wrong status")
      create(:issue, team: team_a, creator: user, assignee: nil, status: "todo", priority: 2, title: "Unassigned")
      create(:issue, team: team_b, creator: user, assignee: assignee, status: "todo", priority: 2, title: "Wrong team")

      get "/api/v1/issues",
          params: {
            team_id: team_a.id,
            assignee_id: assignee.id,
            status: "todo",
            priority: 2
          }

      expect(response).to have_http_status(:ok)
      ids = json_response[:issues].map { |item| item[:id] }
      expect(ids).to contain_exactly(matching_issue.id)
    end

    it "filters by creator_id" do
      mine = create(:issue, team: team_a, creator: user, title: "Mine by creator")
      other_creator = create(:user, email: "creator-filter-other@fintoc.com")
      create(:issue, team: team_a, creator: other_creator, title: "Not mine by creator")

      get "/api/v1/issues",
          params: { team_id: team_a.id, creator_id: user.id }

      expect(response).to have_http_status(:ok)
      ids = json_response[:issues].map { |item| item[:id] }
      expect(ids).to contain_exactly(mine.id)
    end

    it "filters by statuses list for active sub-view use-cases" do
      todo_issue = create(:issue, team: team_a, creator: user, status: "todo", title: "Todo")
      in_progress_issue = create(:issue, team: team_a, creator: user, status: "in_progress", title: "In progress")
      create(:issue, team: team_a, creator: user, status: "backlog", title: "Backlog")
      create(:issue, team: team_a, creator: user, status: "done", title: "Done")

      get "/api/v1/issues",
          params: { team_id: team_a.id, statuses: "todo,in_progress,in_review" }

      expect(response).to have_http_status(:ok)
      ids = json_response[:issues].map { |item| item[:id] }
      expect(ids).to contain_exactly(todo_issue.id, in_progress_issue.id)
    end

    it "prioritizes statuses list over single status when both are provided" do
      todo_issue = create(:issue, team: team_a, creator: user, status: "todo", title: "Todo")
      done_issue = create(:issue, team: team_a, creator: user, status: "done", title: "Done")
      create(:issue, team: team_a, creator: user, status: "backlog", title: "Backlog")

      get "/api/v1/issues",
          params: { team_id: team_a.id, status: "backlog", statuses: "todo,done" }

      expect(response).to have_http_status(:ok)
      ids = json_response[:issues].map { |item| item[:id] }
      expect(ids).to contain_exactly(todo_issue.id, done_issue.id)
    end

    it "sorts by priority with no-priority issues last by default" do
      urgent = create(:issue, team: team_a, creator: user, priority: 1, updated_at: 10.minutes.ago, title: "Urgent")
      low = create(:issue, team: team_a, creator: user, priority: 4, updated_at: 8.minutes.ago, title: "Low")
      no_priority = create(:issue, team: team_a, creator: user, priority: 0, updated_at: 5.minutes.ago, title: "None")

      get "/api/v1/issues",
          params: { team_id: team_a.id, sort: "priority", direction: "asc" }

      expect(response).to have_http_status(:ok)
      ids = json_response[:issues].map { |item| item[:id] }
      expect(ids.index(urgent.id)).to be < ids.index(low.id)
      expect(ids.index(low.id)).to be < ids.index(no_priority.id)
    end

    it "keeps no-priority issues last when sorting priority descending" do
      high = create(:issue, team: team_a, creator: user, priority: 2, updated_at: 10.minutes.ago, title: "High")
      low = create(:issue, team: team_a, creator: user, priority: 4, updated_at: 8.minutes.ago, title: "Low")
      no_priority = create(:issue, team: team_a, creator: user, priority: 0, updated_at: 5.minutes.ago, title: "None")

      get "/api/v1/issues",
          params: { team_id: team_a.id, sort: "priority", direction: "desc" }

      expect(response).to have_http_status(:ok)
      ids = json_response[:issues].map { |item| item[:id] }
      expect(ids.index(low.id)).to be < ids.index(high.id)
      expect(ids.index(high.id)).to be < ids.index(no_priority.id)
    end

    it "sorts by due_date with undated issues last" do
      overdue = create(:issue, team: team_a, creator: user, due_date: Date.current - 1.day, title: "Past due")
      upcoming = create(:issue, team: team_a, creator: user, due_date: Date.current + 1.day, title: "Upcoming")
      undated = create(:issue, team: team_a, creator: user, due_date: nil, title: "No date")

      get "/api/v1/issues",
          params: { team_id: team_a.id, sort: "due_date", direction: "asc" }

      expect(response).to have_http_status(:ok)
      ids = json_response[:issues].map { |item| item[:id] }
      expect(ids.index(overdue.id)).to be < ids.index(upcoming.id)
      expect(ids.index(upcoming.id)).to be < ids.index(undated.id)
    end

    it "sorts by due_date descending while keeping undated issues last" do
      far_due = create(:issue, team: team_a, creator: user, due_date: Date.current + 7.days, title: "Far due")
      near_due = create(:issue, team: team_a, creator: user, due_date: Date.current + 1.day, title: "Near due")
      undated = create(:issue, team: team_a, creator: user, due_date: nil, title: "No date")

      get "/api/v1/issues",
          params: { team_id: team_a.id, sort: "due_date", direction: "desc" }

      expect(response).to have_http_status(:ok)
      ids = json_response[:issues].map { |item| item[:id] }
      expect(ids.index(far_due.id)).to be < ids.index(near_due.id)
      expect(ids.index(near_due.id)).to be < ids.index(undated.id)
    end

    it "defaults to updated_at desc ordering when sort is omitted" do
      stale = create(:issue, team: team_a, creator: user, updated_at: 3.days.ago, title: "Stale")
      fresh = create(:issue, team: team_a, creator: user, updated_at: 2.hours.ago, title: "Fresh")
      newest = create(:issue, team: team_a, creator: user, updated_at: 5.minutes.ago, title: "Newest")

      get "/api/v1/issues", params: { team_id: team_a.id }

      expect(response).to have_http_status(:ok)
      ids = json_response[:issues].map { |item| item[:id] }
      expect(ids.index(newest.id)).to be < ids.index(fresh.id)
      expect(ids.index(fresh.id)).to be < ids.index(stale.id)
    end

    it "supports updated_at ascending ordering when explicitly requested" do
      oldest = create(:issue, team: team_a, creator: user, updated_at: 3.days.ago, title: "Oldest")
      middle = create(:issue, team: team_a, creator: user, updated_at: 2.hours.ago, title: "Middle")
      newest = create(:issue, team: team_a, creator: user, updated_at: 5.minutes.ago, title: "Newest")

      get "/api/v1/issues", params: { team_id: team_a.id, sort: "updated_at", direction: "asc" }

      expect(response).to have_http_status(:ok)
      ids = json_response[:issues].map { |item| item[:id] }
      expect(ids.index(oldest.id)).to be < ids.index(middle.id)
      expect(ids.index(middle.id)).to be < ids.index(newest.id)
    end

    it "filters by text query on title/description" do
      matching = create(:issue, team: team_a, creator: user, title: "Upgrade API auth", description: "token refresh flow")
      create(:issue, team: team_a, creator: user, title: "Polish dashboard", description: "design QA")

      get "/api/v1/issues", params: { team_id: team_a.id, q: "auth token" }

      expect(response).to have_http_status(:ok)
      ids = json_response[:issues].map { |item| item[:id] }
      expect(ids).to contain_exactly(matching.id)
    end

    it "filters by my_issues flag for current user" do
      mine = create(:issue, team: team_a, creator: user, assignee: user, title: "Mine")
      other_user = create(:user, email: "other-user@fintoc.com")
      create(:issue, team: team_a, creator: user, assignee: other_user, title: "Theirs")

      get "/api/v1/issues",
          params: { team_id: team_a.id, my_issues: "true" }

      expect(response).to have_http_status(:ok)
      ids = json_response[:issues].map { |item| item[:id] }
      expect(ids).to contain_exactly(mine.id)
    end

    it "filters by subscribed flag for current user" do
      subscribed_by_creator = create(:issue, team: team_a, creator: user, title: "Subscribed as creator")
      other_creator = create(:user, email: "subscribed-other@fintoc.com")
      subscribed_explicitly = create(:issue, team: team_a, creator: other_creator, title: "Subscribed explicitly")
      not_subscribed = create(:issue, team: team_a, creator: other_creator, title: "Not subscribed")

      create(:issue_subscription, issue: subscribed_explicitly, user: user)

      get "/api/v1/issues",
          params: { team_id: team_a.id, subscribed: "true" }

      expect(response).to have_http_status(:ok)
      ids = json_response[:issues].map { |item| item[:id] }
      expect(ids).to contain_exactly(subscribed_by_creator.id, subscribed_explicitly.id)
      expect(ids).not_to include(not_subscribed.id)
    end

    it "combines my_issues with statuses filter" do
      matching = create(:issue, team: team_a, creator: user, assignee: user, status: "todo", title: "My active")
      create(:issue, team: team_a, creator: user, assignee: user, status: "done", title: "My done")
      create(:issue, team: team_a, creator: user, assignee: assignee, status: "todo", title: "Not mine")

      get "/api/v1/issues",
          params: { team_id: team_a.id, my_issues: "true", statuses: "todo,in_progress,in_review" }

      expect(response).to have_http_status(:ok)
      ids = json_response[:issues].map { |item| item[:id] }
      expect(ids).to contain_exactly(matching.id)
    end
  end
end
