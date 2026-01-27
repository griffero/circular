# frozen_string_literal: true

module Api
  module V1
    class InitiativesController < BaseController
      def index
        # Handle case where table doesn't exist yet
        unless table_exists?
          render json: { initiatives: [] }
          return
        end

        initiatives = Initiative.includes(:owner, projects: :teams).ordered

        # Filter by status if provided
        if params[:status].present?
          initiatives = initiatives.by_status(params[:status])
        end

        render json: {
          initiatives: InitiativeSerializer.render_as_hash(initiatives, view: :with_projects)
        }
      end

      def show
        unless table_exists?
          render json: { error: "Initiatives not available yet" }, status: :service_unavailable
          return
        end

        initiative = Initiative.includes(:owner, projects: :teams).find_by!(slug: params[:id])
        render json: {
          initiative: InitiativeSerializer.render_as_hash(initiative, view: :with_projects)
        }
      rescue ActiveRecord::RecordNotFound
        # Try to find by ID instead
        initiative = Initiative.includes(:owner, projects: :teams).find(params[:id])
        render json: {
          initiative: InitiativeSerializer.render_as_hash(initiative, view: :with_projects)
        }
      end

      private

      def table_exists?
        Initiative.table_exists?
      rescue StandardError
        false
      end
    end
  end
end
