# frozen_string_literal: true

class ApplicationController < ActionController::API
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection
  include Pundit::Authorization
  include Pagy::Backend

  protect_from_forgery with: :null_session

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity

  before_action :set_csrf_cookie

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def authenticate_user!
    render json: { error: "Unauthorized" }, status: :unauthorized unless current_user
  end

  def user_not_authorized
    render json: { error: "You are not authorized to perform this action" }, status: :forbidden
  end

  def not_found
    render json: { error: "Resource not found" }, status: :not_found
  end

  def unprocessable_entity(exception)
    render json: { error: exception.record.errors.full_messages }, status: :unprocessable_entity
  end

  def set_csrf_cookie
    cookies["CSRF-TOKEN"] = {
      value: form_authenticity_token,
      same_site: :lax,
      secure: Rails.env.production?
    }
  end

  def pagy_metadata(pagy)
    {
      page: pagy.page,
      items: pagy.items,
      count: pagy.count,
      pages: pagy.pages
    }
  end
end
