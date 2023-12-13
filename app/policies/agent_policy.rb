# frozen_string_literal: true

class AgentPolicy < ApplicationPolicy

  def initialize(request_context, agent)
    @request_context = request_context
    @agent           = agent
  end

  def items?
    true
  end

  def show?
    true
  end

end