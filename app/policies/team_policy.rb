# frozen_string_literal: true

class TeamPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    admin?
  end

  def update?
    native_record? && (admin? || team_lead?)
  end

  def destroy?
    native_record? && admin?
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end

  private

  def team_lead?
    record.team_memberships.exists?(user: user, role: "lead")
  end
end
