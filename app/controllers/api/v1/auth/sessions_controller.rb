# frozen_string_literal: true

module Api
  module V1
    module Auth
      class SessionsController < ApplicationController
        before_action :authenticate_user!, only: %i[logout me]

        # POST /api/v1/auth/magic-link
        # Send magic link to email (creates user if doesn't exist)
        def send_magic_link
          email = params[:email]&.downcase&.strip

          if email.blank? || !email.match?(URI::MailTo::EMAIL_REGEXP)
            return render json: { error: "Please provide a valid email address" }, status: :unprocessable_entity
          end

          unless fintoc_email?(email)
            return render json: { error: "Only @fintoc.com email addresses are allowed" },
                          status: :unprocessable_entity
          end

          user = User.find_by_email(email)

          if user.nil?
            # Create new user - first user becomes owner
            is_first_user = User.count.zero?
            user = User.new(
              email: email,
              name: email,
              role: is_first_user ? "owner" : "member"
            )

            unless user.save
              return render json: { error: user.errors.full_messages.join(", ") }, status: :unprocessable_entity
            end
          end

          # Generate and send magic link
          token = user.generate_magic_link_token!
          MagicLinkMailer.magic_link_email(user, token).deliver_later

          render json: { message: "Magic link sent to #{email}" }
        end

        # POST /api/v1/auth/verify-magic-link
        # Verify magic link token and log in
        def verify_magic_link
          token = params[:token]

          if token.blank?
            return render json: { error: "Token is required" }, status: :unprocessable_entity
          end

          user = User.find_by_magic_link_token(token)

          if user.nil?
            return render json: { error: "Invalid or expired magic link" }, status: :unauthorized
          end

          unless fintoc_email?(user.email)
            return render json: { error: "Only @fintoc.com email addresses are allowed" },
                          status: :unprocessable_entity
          end

          # Clear the token (one-time use)
          user.clear_magic_link_token!

          # Log in the user
          session[:user_id] = user.id
          cookies.encrypted[:user_id] = { value: user.id, httponly: true }

          render json: auth_response(user)
        end

        # POST /api/v1/auth/token-login
        # One-time token login (no email magic link)
        def token_login
          return head :not_found unless token_login_enabled?

          token = params[:token].to_s

          if token.blank? || token != token_login_secret
            return render json: { error: "Invalid token" }, status: :unauthorized
          end

          if token_login_used?(token)
            return render json: { error: "Token already used" }, status: :unauthorized
          end

          user = User.find_or_create_by!(email: token_login_email) do |record|
            record.name = "Admin Admin"
            record.role = "admin"
          end

          mark_token_login_used(token)

          session[:user_id] = user.id
          cookies.encrypted[:user_id] = { value: user.id, httponly: true }

          render json: auth_response(user)
        end

        def logout
          session.delete(:user_id)
          cookies.delete(:user_id)
          head :no_content
        end

        def me
          render json: auth_response(current_user)
        end

        private

        def auth_response(user)
          {
            user: UserSerializer.render_as_hash(user),
            teams: TeamSerializer.render_as_hash(Team.ordered, view: :minimal),
            projects: ProjectSerializer.render_as_hash(Project.active.ordered, view: :minimal)
          }
        end

        def fintoc_email?(email)
          email.present? && email.match?(/\A[^@\s]+@fintoc\.com\z/i)
        end

        def token_login_enabled?
          token_login_secret.present?
        end

        def token_login_secret
          ENV["TOKEN_LOGIN_SECRET"].to_s
        end

        def token_login_email
          ENV.fetch("TOKEN_LOGIN_EMAIL", "admin.admin@fintoc.com")
        end

        def token_login_used?(token)
          Rails.cache.read(token_login_cache_key(token)) == true
        end

        def mark_token_login_used(token)
          Rails.cache.write(token_login_cache_key(token), true, expires_in: 24.hours)
        end

        def token_login_cache_key(token)
          "token-login-used:#{token}"
        end
      end
    end
  end
end
