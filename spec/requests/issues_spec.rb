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
  end
end
