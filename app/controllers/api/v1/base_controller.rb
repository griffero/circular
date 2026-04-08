# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_user!
      before_action :set_current_user

      private

      def set_current_user
        Current.user = current_user
      end

      def require_admin!
        return if current_user&.admin?

        render json: { error: "Admin access required" }, status: :forbidden
      end

      def require_owner!
        return if current_user&.owner?

        render json: { error: "Owner access required" }, status: :forbidden
      end

      def reject_linear_record!(record)
        return false unless record.from_linear?

        render json: { error: "Cannot modify Linear-synced records" }, status: :forbidden
        true
      end
    end
  end
end
