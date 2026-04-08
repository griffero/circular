# frozen_string_literal: true

class ProjectPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    return true if record.public?

    # Private project - must be admin or project member
    admin? || project_member?
  end

  def create?
    true
  end

  def update?
    native_record? && (admin? || project_lead?)
  end

  def destroy?
    native_record? && admin?
  end

  class Scope < Scope
    def resolve
      # Public projects + private projects user is member of
      scope.where(privacy: "public")
           .or(scope.where(id: user.projects.pluck(:id)))
    end
  end

  private

  def project_member?
    record.members.include?(user)
  end

  def project_lead?
    record.lead_id == user.id
  end
end
