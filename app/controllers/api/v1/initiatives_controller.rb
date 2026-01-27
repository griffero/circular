# frozen_string_literal: true

module Api
  module V1
    class InitiativesController < BaseController
      def index
        initiatives = Initiative.includes(:owner, :projects).ordered

        # Filter by status if provided
        if params[:status].present?
          initiatives = initiatives.by_status(params[:status])
        end

        render json: {
          initiatives: InitiativeSerializer.render_as_hash(initiatives, view: :with_projects)
        }
      end

      def show
        initiative = Initiative.includes(:owner, :projects).find_by!(slug: params[:id])
        render json: {
          initiative: InitiativeSerializer.render_as_hash(initiative, view: :with_projects)
        }
      rescue ActiveRecord::RecordNotFound
        # Try to find by ID instead
        initiative = Initiative.includes(:owner, :projects).find(params[:id])
        render json: {
          initiative: InitiativeSerializer.render_as_hash(initiative, view: :with_projects)
        }
      end
    end
  end
end
