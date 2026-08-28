# frozen_string_literal: true

module Api
  module V1
    class UsersController < BaseController
      before_action :set_user, only: %i[show update destroy role]
      before_action :require_admin!, only: %i[index destroy role]
      before_action :authorize_update!, only: %i[update]

      def index
        users = User.includes(:teams, :projects).order(:name)

        render json: {
          users: UserSerializer.render_as_hash(users, view: :with_teams)
        }
      end

      def show
        render json: {
          user: UserSerializer.render_as_hash(@user, view: :detailed)
        }
      end

      def update
        if @user.update(user_params)
          render json: {
            user: UserSerializer.render_as_hash(@user)
          }
        else
          render json: { error: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        # Prevent deleting yourself or the last owner
        if @user == current_user
          return render json: { error: "Cannot delete yourself" }, status: :unprocessable_entity
        end

        if @user.owner? && User.owners.count == 1
          return render json: { error: "Cannot delete the last owner" }, status: :unprocessable_entity
        end

        @user.destroy!
        head :no_content
      end

      def role
        new_role = params[:role]

        unless %w[member admin owner].include?(new_role)
          return render json: { error: "Invalid role" }, status: :unprocessable_entity
        end

        # Prevent demoting the last owner
        if @user.owner? && new_role != "owner" && User.owners.count == 1
          return render json: { error: "Cannot demote the last owner" }, status: :unprocessable_entity
        end

        # Only owners can promote to owner
        if new_role == "owner" && !current_user.owner?
          return render json: { error: "Only owners can promote to owner" }, status: :forbidden
        end

        @user.update!(role: new_role)

        render json: {
          user: UserSerializer.render_as_hash(@user)
        }
      end

      private

      def set_user
        @user = User.find(params[:id])
      end

      def authorize_update!
        return if current_user&.admin?
        return if @user == current_user

        render json: { error: "Forbidden" }, status: :forbidden
      end

      def user_params
        permitted = [ :name, :display_name, :avatar_url, :timezone ]
        permitted << :email if current_user&.admin?

        # Only owners can change roles and active status
        if current_user&.owner?
          permitted += [ :role, :active ]
        end

        params.fetch(:user, params).permit(permitted)
      end
    end
  end
end
