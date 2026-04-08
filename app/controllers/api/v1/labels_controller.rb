# frozen_string_literal: true

module Api
  module V1
    class LabelsController < BaseController
      before_action :set_label, only: %i[show update destroy]
      before_action :require_admin!, only: %i[create update destroy]

      def index
        labels = Label.ordered

        # Filter by team (includes global labels)
        labels = labels.for_team(params[:team_id]) if params[:team_id].present?

        render json: {
          labels: LabelSerializer.render_as_hash(labels)
        }
      end

      def show
        render json: {
          label: LabelSerializer.render_as_hash(@label)
        }
      end

      def create
        label = Label.new(label_params)

        if label.save
          render json: {
            label: LabelSerializer.render_as_hash(label)
          }, status: :created
        else
          render json: { error: label.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        return if reject_linear_record!(@label)

        if @label.update(label_params)
          render json: {
            label: LabelSerializer.render_as_hash(@label)
          }
        else
          render json: { error: @label.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        return if reject_linear_record!(@label)

        @label.destroy!
        head :no_content
      end

      private

      def set_label
        @label = Label.find(params[:id])
      end

      def label_params
        params.require(:label).permit(:name, :color, :description, :team_id)
      end
    end
  end
end
