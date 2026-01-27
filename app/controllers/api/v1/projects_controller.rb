# frozen_string_literal: true

module Api
  module V1
    class ProjectsController < BaseController
      before_action :set_project, only: %i[show update destroy]
      before_action :authorize_project_access!, only: %i[show]
      before_action :require_admin!, only: %i[create update destroy]

      def index
        projects = Project.includes(:lead, :members).ordered

        # Filter by status if provided
        projects = projects.where(status: params[:status]) if params[:status].present?

        render json: {
          projects: ProjectSerializer.render_as_hash(projects, view: :with_lead)
        }
      end

      def create
        project = Project.new(project_params)
        project.lead = current_user if project.lead_id.nil?

        if project.save
          # Add lead as project member
          ProjectMembership.create!(user: project.lead, project: project, role: "lead") if project.lead

          render json: {
            project: ProjectSerializer.render_as_hash(project, view: :with_lead)
          }, status: :created
        else
          render json: { error: project.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def show
        render json: {
          project: ProjectSerializer.render_as_hash(@project, view: :detailed)
        }
      end

      def update
        if @project.update(project_params)
          render json: {
            project: ProjectSerializer.render_as_hash(@project, view: :with_lead)
          }
        else
          render json: { error: @project.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @project.destroy!
        head :no_content
      end

      private

      def set_project
        @project = Project.includes(:lead, :members, :teams).find_by!(slug: params[:slug])
      end

      def authorize_project_access!
        return unless @project.private?
        return if current_user.admin?
        return if @project.members.include?(current_user)

        render json: { error: "Access denied" }, status: :forbidden
      end

      def project_params
        params.require(:project).permit(:name, :slug, :description, :icon, :color,
                                        :lead_id, :privacy, :status, :start_date, :target_date)
      end
    end
  end
end
