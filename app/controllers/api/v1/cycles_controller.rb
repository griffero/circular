# frozen_string_literal: true

module Api
  module V1
    class CyclesController < BaseController
      before_action :set_team

      def index
        cycles = @team.cycles.order(number: :desc)
        render json: {
          cycles: CycleSerializer.render_as_hash(cycles)
        }
      end

      private

      def set_team
        key = params[:team_key]
        # Support both UUID and team key
        @team = if key.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
                  Team.find(key)
        else
                  Team.find_by!(key: key.upcase)
        end
      end
    end
  end
end
