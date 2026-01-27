# frozen_string_literal: true

module Cacheable
  extend ActiveSupport::Concern

  # Cache duration for different types of data
  CACHE_DURATIONS = {
    workflow_states: 5.minutes,
    labels: 5.minutes,
    teams: 5.minutes,
    cycles: 1.minute
  }.freeze

  class_methods do
    def cache_action(*actions, expires_in: 5.minutes, key_prefix: nil)
      actions.each do |action|
        around_action only: action do |_controller, block|
          cache_key = [
            key_prefix || action,
            current_user&.id,
            params.to_unsafe_h.except(:controller, :action).to_query
          ].compact.join("/")

          result = Rails.cache.fetch(cache_key, expires_in: expires_in) do
            response.body = nil
            block.call
            response.body
          end

          self.response_body = result unless response_body
        end
      end
    end
  end

  private

  def cached_teams
    Rails.cache.fetch("teams/all", expires_in: CACHE_DURATIONS[:teams]) do
      Team.includes(:members, :workflow_states).ordered.to_a
    end
  end

  def cached_workflow_states(team_id)
    Rails.cache.fetch("workflow_states/team/#{team_id}", expires_in: CACHE_DURATIONS[:workflow_states]) do
      WorkflowState.where(team_id: team_id).order(:position).to_a
    end
  end

  def cached_labels(team_id = nil)
    cache_key = team_id ? "labels/team/#{team_id}" : "labels/global"
    Rails.cache.fetch(cache_key, expires_in: CACHE_DURATIONS[:labels]) do
      scope = team_id ? Label.where(team_id: team_id) : Label.where(team_id: nil)
      scope.order(:name).to_a
    end
  end

  def invalidate_team_cache(team_id)
    Rails.cache.delete("workflow_states/team/#{team_id}")
    Rails.cache.delete("labels/team/#{team_id}")
    Rails.cache.delete("teams/all")
  end
end
