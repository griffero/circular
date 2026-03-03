# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users API" do
  let(:acting_user) { create(:user, email: "acting@fintoc.com", role: "member") }

  before do
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(acting_user)
  end

  describe "PATCH /api/v1/users/:id" do
    context "when updating own profile as member" do
      it "allows profile fields and blocks email changes" do
        patch "/api/v1/users/#{acting_user.id}",
              params: {
                user: {
                  name: "Updated Name",
                  display_name: "Updated Display",
                  timezone: "America/Santiago",
                  email: "blocked@fintoc.com"
                }
              }

        expect(response).to have_http_status(:ok)
        acting_user.reload
        expect(acting_user.name).to eq("Updated Name")
        expect(acting_user.display_name).to eq("Updated Display")
        expect(acting_user.timezone).to eq("America/Santiago")
        expect(acting_user.email).to eq("acting@fintoc.com")
      end
    end

    context "when member updates another user" do
      let(:other_user) { create(:user, email: "other@fintoc.com") }

      it "returns forbidden" do
        patch "/api/v1/users/#{other_user.id}", params: { user: { name: "Nope" } }

        expect(response).to have_http_status(:forbidden)
        expect(json_response[:error]).to eq("Forbidden")
      end
    end

    context "when admin updates another user with flat params" do
      let(:acting_user) { create(:user, :admin, email: "admin@fintoc.com") }
      let(:other_user) { create(:user, email: "other@fintoc.com", display_name: "Before") }

      it "accepts top-level params and updates email/display_name" do
        patch "/api/v1/users/#{other_user.id}",
              params: {
                name: "Admin Updated",
                display_name: "After",
                email: "other-updated@fintoc.com"
              }

        expect(response).to have_http_status(:ok)
        other_user.reload
        expect(other_user.name).to eq("Admin Updated")
        expect(other_user.display_name).to eq("After")
        expect(other_user.email).to eq("other-updated@fintoc.com")
      end
    end
  end
end
