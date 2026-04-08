# frozen_string_literal: true

class LabelPolicy < ApplicationPolicy
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
    native_record? && admin?
  end

  def destroy?
    native_record? && admin?
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
