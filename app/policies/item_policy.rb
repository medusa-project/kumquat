# frozen_string_literal: true

class ItemPolicy < ApplicationPolicy

  def initialize(request_context, item)
    @request_context = request_context
    @item            = item
  end

  def binary?
    show?
  end

  def iiif_annotation_list?
    show?
  end

  def iiif_canvas?
    show?
  end

  def iiif_image_resource?
    show?
  end

  def iiif_layer?
    show?
  end

  def iiif_manifest?
    show?
  end

  def iiif_media_sequence?
    show?
  end

  def iiif_range?
    show?
  end

  def iiif_search?
    show?
  end

  def iiif_sequence?
    show?
  end

  def index?
    true
  end

  def item_tree_node?
    show?
  end

  def show?
    if @request_context.user&.medusa_admin?
      return true
    elsif @item.restricted # DLD-337
      username = @request_context.user&.username
      struct   = @item.allowed_netids&.find{ |h| h['netid'] == username }
      return username.present? && struct &&
        Time.now < Time.at(struct['expires'].to_i)
    elsif !@item.authorized_by_any_host_groups?(@request_context.client_host_groups)
      return false
    elsif !@item.publicly_accessible?
      return false
    end
    true
  end

  def tree?
    index?
  end

  def tree_data?
    tree?
  end

end
