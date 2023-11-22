# frozen_string_literal: true

class BinaryPolicy < ApplicationPolicy

  def initialize(request_context, binary)
    @request_context = request_context
    @binary          = binary
  end

  def object?
    show?
  end

  def show?
    return false unless @binary.public? || @request_context.user&.medusa_user?
    item = @binary.item
    if item
      return false unless ItemPolicy.new(@request_context, item).show?
      collection = item.collection
      if collection
        return false unless CollectionPolicy.new(@request_context, collection).show?
      end
    end
    true
  end

  def stream?
    object?
  end

end
