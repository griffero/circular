# frozen_string_literal: true

module Api
  module V1
    class TeamsController < BaseController
      before_action :set_team, only: %i[show update destroy]
      before_action :require_admin!, only: %i[create update destroy]

      def index
        teams = Team.includes(:team_memberships, :members).ordered

        render json: {
          teams: TeamSerializer.render_as_hash(teams, view: :with_members)
        }
      end

      def create
        team = Team.new(team_params)

        if team.save
          # Add current user as team lead by default
          TeamMembership.create!(user: current_user, team: team, role: "lead")

          render json: {
            team: TeamSerializer.render_as_hash(team, view: :with_members)
          }, status: :created
        else
          render json: { error: team.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def show
        render json: {
          team: TeamSerializer.render_as_hash(@team, view: :detailed)
        }
      end

      def update
        return if reject_linear_record!(@team)

        if @team.update(team_params)
          render json: {
            team: TeamSerializer.render_as_hash(@team, view: :with_members)
          }
        else
          render json: { error: @team.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        return if reject_linear_record!(@team)

        @team.destroy!
        head :no_content
      end

      private

      def set_team
        @team = Team.find_by!(key: params[:key].upcase)
      end

      def team_params
        params.require(:team).permit(:name, :key, :description, :icon, :color)
      end
    end
  end
end
