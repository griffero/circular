# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Authentication" do
  describe "POST /api/v1/auth/signup" do
    let(:valid_params) do
      {
        name: "John Doe",
        email: "john@example.com",
        password: "password123"
      }
    end

    context "with valid params" do
      it "creates a new user" do
        expect {
          post "/api/v1/auth/signup", params: valid_params
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json_response[:user][:email]).to eq("john@example.com")
      end

      it "first user becomes owner" do
        post "/api/v1/auth/signup", params: valid_params

        expect(response).to have_http_status(:created)
        user = User.find_by(email: "john@example.com")
        expect(user.role).to eq("owner")
      end

      it "subsequent users become members" do
        create(:user, :owner) # First user
        post "/api/v1/auth/signup", params: valid_params

        expect(response).to have_http_status(:created)
        user = User.find_by(email: "john@example.com")
        expect(user.role).to eq("member")
      end

      it "returns teams and projects in response" do
        create(:team)
        create(:project)

        post "/api/v1/auth/signup", params: valid_params

        expect(response).to have_http_status(:created)
        expect(json_response).to have_key(:teams)
        expect(json_response).to have_key(:projects)
      end
    end

    context "with invalid params" do
      it "returns errors for missing email" do
        post "/api/v1/auth/signup", params: valid_params.except(:email)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:error]).to include(/email/i)
      end

      it "returns errors for duplicate email" do
        create(:user, email: "john@example.com")
        post "/api/v1/auth/signup", params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns errors for short password" do
        post "/api/v1/auth/signup", params: valid_params.merge(password: "short")

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "POST /api/v1/auth/login" do
    let!(:user) { create(:user, email: "john@example.com", password: "password123") }

    context "with valid credentials" do
      it "logs in the user" do
        post "/api/v1/auth/login", params: { email: "john@example.com", password: "password123" }

        expect(response).to have_http_status(:ok)
        expect(json_response[:user][:email]).to eq("john@example.com")
      end

      it "is case-insensitive for email" do
        post "/api/v1/auth/login", params: { email: "JOHN@EXAMPLE.COM", password: "password123" }

        expect(response).to have_http_status(:ok)
      end

      it "returns user role" do
        post "/api/v1/auth/login", params: { email: "john@example.com", password: "password123" }

        expect(response).to have_http_status(:ok)
        expect(json_response[:user]).to have_key(:role)
      end
    end

    context "with invalid credentials" do
      it "returns unauthorized for wrong password" do
        post "/api/v1/auth/login", params: { email: "john@example.com", password: "wrongpassword" }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response[:error]).to eq("Invalid email or password")
      end

      it "returns unauthorized for non-existent email" do
        post "/api/v1/auth/login", params: { email: "nobody@example.com", password: "password123" }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /api/v1/auth/logout" do
    let(:user) { create(:user) }

    before do
      post "/api/v1/auth/login", params: { email: user.email, password: "password123" }
    end

    it "logs out the user" do
      delete "/api/v1/auth/logout"

      expect(response).to have_http_status(:no_content)
    end
  end

  describe "GET /api/v1/auth/me" do
    let(:user) { create(:user) }

    context "when authenticated" do
      before do
        post "/api/v1/auth/login", params: { email: user.email, password: "password123" }
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

  describe "POST /api/v1/auth/magic-link" do
    context "with a fintoc.com email" do
      it "creates a user with the email as name" do
        expect {
          post "/api/v1/auth/magic-link", params: { email: "new.user@fintoc.com" }
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:ok)
        user = User.find_by(email: "new.user@fintoc.com")
        expect(user.name).to eq("new.user@fintoc.com")
      end
    end

    context "with a non-fintoc email" do
      it "rejects the request" do
        expect {
          post "/api/v1/auth/magic-link", params: { email: "new.user@example.com" }
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:error]).to include("fintoc.com")
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
  end
end
