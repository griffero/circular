# frozen_string_literal: true

module Api
  module V1
    class EmojisController < BaseController
      # GET /api/v1/emojis
      # Returns a hash of emoji names to their URLs
      def index
        emojis = SlackEmoji.all_as_hash

        render json: { emojis: emojis }
      end
    end
  end
end
