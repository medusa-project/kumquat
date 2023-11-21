# frozen_string_literal: true

module Admin

  class VocabularyPolicy < ApplicationPolicy

    def initialize(user, vocabulary)
      @user       = user
      @vocabulary = vocabulary
    end

    def create?
      @user.medusa_admin?
    end

    def delete_vocabulary_terms?
      update?
    end

    def destroy?
      update?
    end

    def edit?
      update?
    end

    def import?
      @user.medusa_admin?
    end

    def index?
      show?
    end

    def new?
      show?
    end

    def show?
      @user.medusa_admin?
    end

    def update?
      @user.medusa_admin? && !@vocabulary.readonly?
    end

  end

end
