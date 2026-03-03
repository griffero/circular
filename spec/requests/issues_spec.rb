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
    end
  end

  describe "PATCH /api/v1/issues/:id" do
    let(:team) { create(:team, key: "API") }
    let(:issue) { create(:issue, team: team, creator: user, status: "todo") }
    let(:started_state) { create(:workflow_state, team: team, name: "In Progress", state_type: "started", position: 20.0) }
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
