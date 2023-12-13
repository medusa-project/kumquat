# frozen_string_literal: true

class CollectionPolicy < ApplicationPolicy

  def initialize(request_context, collection)
    @request_context = request_context
    @collection      = collection
  end

  def iiif_presentation?
    show?
  end

  def iiif_presentation_list?
    true
  end

  def index?
    true
  end

  def show?
    # TODO: "You are not authorized to access this collection." / "This collection is unpublished."
    if @request_context.user&.medusa_admin?
      return true
    elsif @collection.restricted || !@collection.publicly_accessible?
      return false
    elsif !@collection.authorized_by_any_host_groups?(@request_context.client_host_groups)
      return false
    end
    true
  end

  def show_contentdm?
    true
  end

end
