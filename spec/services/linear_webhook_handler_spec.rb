# frozen_string_literal: true

require "rails_helper"

RSpec.describe LinearWebhookHandler do
  describe "#process" do
    it "fetches the full issue payload from Linear before syncing issue webhooks" do
      payload = {
        "type" => "Issue",
        "action" => "update",
        "data" => {
          "id" => "issue-linear-id",
          "title" => "Partial webhook payload"
        }
      }
      full_issue_payload = {
        "id" => "issue-linear-id",
        "team" => { "id" => "team-linear-id" },
        "creator" => { "id" => "user-linear-id" },
        "state" => { "id" => "state-linear-id" },
        "title" => "Full issue payload"
      }
      client = instance_double(LinearClient, issue: full_issue_payload)

      allow(LinearClient).to receive(:new).and_return(client)
      allow(Sync::IssueSync).to receive(:upsert_from_linear)

      result = described_class.new(payload).process

      expect(client).to have_received(:issue).with("issue-linear-id")
      expect(Sync::IssueSync).to have_received(:upsert_from_linear).with(full_issue_payload)
      expect(result).to eq(success: true, action: "update", type: "Issue")
    end

    it "keeps using the raw payload for non-issue webhook entities" do
      payload = {
        "type" => "Project",
        "action" => "update",
        "data" => { "id" => "project-linear-id", "name" => "Project payload" }
      }

      allow(Sync::ProjectSync).to receive(:upsert_from_linear)
      allow(LinearClient).to receive(:new)

      result = described_class.new(payload).process

      expect(LinearClient).not_to have_received(:new)
      expect(Sync::ProjectSync).to have_received(:upsert_from_linear).with(payload["data"])
      expect(result).to eq(success: true, action: "update", type: "Project")
    end
  end
end
