# frozen_string_literal: true

module Api
  module V1
    module Auth
      class SessionsController < ApplicationController
        skip_before_action :authenticate_user!, only: %i[send_magic_link verify_magic_link]

        # POST /api/v1/auth/magic-link
        # Send magic link to email (creates user if doesn't exist)
        def send_magic_link
          email = params[:email]&.downcase&.strip

          if email.blank? || !email.match?(URI::MailTo::EMAIL_REGEXP)
            return render json: { error: "Please provide a valid email address" }, status: :unprocessable_entity
          end

          user = User.find_by_email(email)

          if user.nil?
            # Create new user - first user becomes owner
            is_first_user = User.count.zero?
            user = User.new(
              email: email,
              name: email.split("@").first.titleize,
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

          # Clear the token (one-time use)
          user.clear_magic_link_token!

          # Log in the user
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
      end
    end
  end
end
