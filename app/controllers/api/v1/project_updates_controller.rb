# frozen_string_literal: true

module Api
  module V1
    class ProjectUpdatesController < BaseController
      def index
        updates = ProjectUpdate.includes(:project, :user)
                               .recent
                               .limit(params[:limit] || 50)

        # Filter by time period if requested
        if params[:since].present?
          updates = updates.where("created_at >= ?", Time.parse(params[:since]))
        end

        render json: {
          project_updates: ProjectUpdateSerializer.render_as_hash(updates)
        }
      end

      def show
        update = ProjectUpdate.find(params[:id])
        render json: {
          project_update: ProjectUpdateSerializer.render_as_hash(update)
        }
      end
    end
  end
end
