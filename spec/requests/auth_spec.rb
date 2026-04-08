# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Authentication" do
  describe "POST /api/v1/auth/magic-link" do
    context "with a fintoc.com email" do
      it "sends magic link for existing user" do
        user = create(:user, email: "dev@fintoc.com")

        post "/api/v1/auth/magic-link", params: { email: "dev@fintoc.com" }

        expect(response).to have_http_status(:ok)
        expect(json_response[:message]).to include("dev@fintoc.com")
        expect(user.reload.magic_link_token).to be_present
      end

      it "auto-creates first user as owner when no users exist" do
        expect {
          post "/api/v1/auth/magic-link", params: { email: "first@fintoc.com" }
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:ok)
        user = User.find_by(email: "first@fintoc.com")
        expect(user.role).to eq("owner")
      end

      it "returns not_found for unknown user when other users exist" do
        create(:user, email: "existing@fintoc.com")

        post "/api/v1/auth/magic-link", params: { email: "unknown@fintoc.com" }

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with a non-fintoc email" do
      it "rejects the request" do
        expect {
          post "/api/v1/auth/magic-link", params: { email: "user@example.com" }
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:error]).to include("fintoc.com")
      end
    end

    context "with invalid email" do
      it "rejects blank email" do
        post "/api/v1/auth/magic-link", params: { email: "" }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "POST /api/v1/auth/verify-magic-link" do
    context "with a valid fintoc.com token" do
      it "logs in the user" do
        user = create(:user, email: "valid@fintoc.com")
        token = user.generate_magic_link_token!

        post "/api/v1/auth/verify-magic-link", params: { token: token }

        expect(response).to have_http_status(:ok)
        expect(json_response[:user][:email]).to eq("valid@fintoc.com")
      end

      it "clears the token after use" do
        user = create(:user, email: "once@fintoc.com")
        token = user.generate_magic_link_token!

        post "/api/v1/auth/verify-magic-link", params: { token: token }

        expect(response).to have_http_status(:ok)
        expect(user.reload.magic_link_token).to be_nil
      end

      it "returns teams and projects" do
        user = create(:user, email: "teams@fintoc.com")
        token = user.generate_magic_link_token!
        create(:team)
        create(:project)

        post "/api/v1/auth/verify-magic-link", params: { token: token }

        expect(response).to have_http_status(:ok)
        expect(json_response).to have_key(:teams)
        expect(json_response).to have_key(:projects)
      end
    end

    context "with a non-fintoc email token" do
      it "rejects the request" do
        user = create(:user, email: "valid@example.com")
        token = user.generate_magic_link_token!

        post "/api/v1/auth/verify-magic-link", params: { token: token }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:error]).to include("fintoc.com")
      end
    end

    context "with invalid token" do
      it "rejects blank token" do
        post "/api/v1/auth/verify-magic-link", params: { token: "" }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects expired token" do
        user = create(:user, email: "expired@fintoc.com")
        token = user.generate_magic_link_token!
        user.update_column(:magic_link_sent_at, 20.minutes.ago)

        post "/api/v1/auth/verify-magic-link", params: { token: token }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /api/v1/auth/logout" do
    let(:user) { create(:user, email: "logout@fintoc.com") }

    before do
      token = user.generate_magic_link_token!
      post "/api/v1/auth/verify-magic-link", params: { token: token }
    end

    it "logs out the user" do
      delete "/api/v1/auth/logout"

      expect(response).to have_http_status(:no_content)
    end
  end

  describe "GET /api/v1/auth/me" do
    let(:user) { create(:user, email: "me@fintoc.com") }

    context "when authenticated" do
      before do
        token = user.generate_magic_link_token!
        post "/api/v1/auth/verify-magic-link", params: { token: token }
      end

      it "returns the current user" do
        get "/api/v1/auth/me"

        expect(response).to have_http_status(:ok)
        expect(json_response[:user][:id]).to eq(user.id)
      end

      it "returns teams and projects" do
        create(:team)
        create(:project)

        get "/api/v1/auth/me"

        expect(response).to have_http_status(:ok)
        expect(json_response).to have_key(:teams)
        expect(json_response).to have_key(:projects)
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        get "/api/v1/auth/me"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
