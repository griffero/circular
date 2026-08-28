# frozen_string_literal: true

module Api
  module V1
    class WorkflowStatesController < BaseController
      before_action :set_team

      def index
        workflow_states = @team.workflow_states.order(:position)
        render json: {
          workflow_states: WorkflowStateSerializer.render_as_hash(workflow_states)
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
