# frozen_string_literal: true

class CommentPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    true
  end

  def update?
    native_record? && record.user_id == user.id
  end

  def destroy?
    native_record? && (record.user_id == user.id || admin?)
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
