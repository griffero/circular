# frozen_string_literal: true

class GraphqlController < ApplicationController
  def execute
    variables = prepare_variables(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]

    context = {
      current_user: current_user_from_token
    }

    result = LinearCloneSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?

    handle_error_in_development(e)
  end

  private

  def current_user_from_token
    # Try session first (for web clients)
    return User.find_by(id: session[:user_id]) if session[:user_id]

    # Try API token (for external clients)
    auth_header = request.headers["Authorization"]
    return unless auth_header&.start_with?("Bearer ")

    token = auth_header.split(" ").last
    api_token = ApiToken.find_by_token(token)
    api_token&.user
  end

  def prepare_variables(variables_param)
    case variables_param
    when String
      if variables_param.present?
        JSON.parse(variables_param) || {}
      else
        {}
      end
    when Hash
      variables_param
    when ActionController::Parameters
      variables_param.to_unsafe_hash
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end

  def handle_error_in_development(error)
    logger.error error.message
    logger.error error.backtrace.join("\n")

    render json: { errors: [{ message: error.message, backtrace: error.backtrace[0..10] }], data: {} },
           status: :internal_server_error
  end
end
