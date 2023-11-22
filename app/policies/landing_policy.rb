# frozen_string_literal: true

class LandingPolicy < ApplicationPolicy

  def initialize(request_context, unused)
    @request_context = request_context
  end

  def index?
    true
  end

end
