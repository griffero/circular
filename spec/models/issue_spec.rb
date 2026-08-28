# frozen_string_literal: true

require "rails_helper"

RSpec.describe Issue do
  describe "associations" do
    it { is_expected.to belong_to(:team) }
    it { is_expected.to belong_to(:creator).class_name("User") }
    it { is_expected.to belong_to(:assignee).class_name("User").optional }
    it { is_expected.to belong_to(:project).optional }
    it { is_expected.to belong_to(:parent).class_name("Issue").optional }
    it { is_expected.to have_many(:sub_issues).class_name("Issue").with_foreign_key(:parent_id) }
    it { is_expected.to have_many(:issue_labels).dependent(:destroy) }
    it { is_expected.to have_many(:labels).through(:issue_labels) }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
    it { is_expected.to have_many(:activities).class_name("IssueActivity").dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_least(1).is_at_most(500) }
    # status is optional when using workflow_state (Linear migration)
    it { is_expected.to allow_value(nil).for(:status) }
    it { is_expected.to validate_presence_of(:priority) }
    it { is_expected.to validate_inclusion_of(:priority).in_range(0..4) }

    it "defines valid statuses" do
      expect(described_class.statuses.keys).to match_array(%w[backlog todo in_progress in_review done canceled])
    end
  end

  describe "auto-generated identifier" do
    let(:team) { create(:team, key: "ENG") }
    let(:user) { create(:user) }

    it "generates identifier from team key and number" do
      issue = create(:issue, team: team, creator: user)
      expect(issue.identifier).to eq("ENG-1")
    end

    it "increments number for each issue in team" do
      issue1 = create(:issue, team: team, creator: user)
      issue2 = create(:issue, team: team, creator: user)

      expect(issue1.number).to eq(1)
      expect(issue2.number).to eq(2)
    end
  end

  describe "scopes" do
    let(:team) { create(:team) }
    let(:user) { create(:user) }

    describe ".open" do
      it "returns issues that are not done or canceled" do
        open_issue = create(:issue, :todo, team: team, creator: user)
        done_issue = create(:issue, :done, team: team, creator: user)
        canceled_issue = create(:issue, :canceled, team: team, creator: user)

        expect(described_class.open).to include(open_issue)
        expect(described_class.open).not_to include(done_issue, canceled_issue)
      end
    end

    describe ".closed" do
      it "returns issues that are done or canceled" do
        open_issue = create(:issue, :todo, team: team, creator: user)
        done_issue = create(:issue, :done, team: team, creator: user)

        expect(described_class.closed).to include(done_issue)
        expect(described_class.closed).not_to include(open_issue)
      end
    end

    describe ".by_assignee" do
      it "returns issues assigned to a user" do
        assignee = create(:user)
        assigned_issue = create(:issue, team: team, creator: user, assignee: assignee)
        unassigned_issue = create(:issue, team: team, creator: user)

        expect(described_class.by_assignee(assignee.id)).to include(assigned_issue)
        expect(described_class.by_assignee(assignee.id)).not_to include(unassigned_issue)
      end
    end
  end

  describe "#complete!" do
    let(:issue) { create(:issue, :in_progress) }

    it "marks the issue as done" do
      issue.complete!
      expect(issue.reload.status).to eq("done")
      expect(issue.completed_at).to be_present
    end
  end

  describe "#cancel!" do
    let(:issue) { create(:issue, :in_progress) }

    it "marks the issue as canceled" do
      issue.cancel!
      expect(issue.reload.status).to eq("canceled")
      expect(issue.canceled_at).to be_present
    end
  end

  describe "#start!" do
    let(:issue) { create(:issue, :todo) }

    it "marks the issue as in progress" do
      issue.start!
      expect(issue.reload.status).to eq("in_progress")
      expect(issue.started_at).to be_present
    end
  end
end
