module ApplicationHelper

  def bootstrap_class_for(flash_type)
    case flash_type.to_sym
      when :success
        'alert-success'
      when :error
        'alert-danger'
      when :alert
        'alert-block'
      when :notice
        'alert-info'
      else
        flash_type.to_s
    end
  end

  ##
  # Formats a boolean for display.
  #
  # @param boolean [Boolean]
  # @return [String]
  #
  def boolean(boolean)
    raw(boolean ? '<span class="text-success">&check;</span>' :
            '<span class="text-danger">&times;</span>')
  end

  ##
  # @param options [Hash]
  # @option options [Collection] :collection
  # @option options [ItemsController::BrowseContext] :context
  # @option options [String] :context_url
  # @option options [Item] :item
  # @return [String]
  #
  def breadcrumb(options = {})
    case controller_name
      when 'collections'
        case action_name
          when 'index'
            return collections_view_breadcrumb
          when 'show'
            return collection_view_breadcrumb(options[:collection])
        end
      when 'items'
        case action_name
          when 'index'
            return results_breadcrumb(options[:collection], options[:context])
          when 'show'
            return item_view_breadcrumb(options[:item], options[:context],
                                        options[:context_url])
        end
    end
    nil
  end

  ##
  # @param entity [Entity]
  # @return [String] HTML <i> tag
  #
  def icon_for(entity)
    icon = 'fa-cube'
    if entity.kind_of?(Item)
      if entity.is_audio?
        icon = 'fa-volume-up'
      elsif entity.is_image?
        icon = 'fa-picture-o'
      elsif entity.is_pdf? or entity.is_text?
        icon = 'fa-file-text-o'
      elsif entity.is_video?
        icon = 'fa-film'
      elsif entity.children.any?
        icon = 'fa-cubes'
      end
    elsif entity.kind_of?(Collection) or entity == Collection
      icon = 'fa-folder-open-o'
    end
    raw("<i title=\"#{type_of(entity)}\" class=\"fa #{icon} pt-icon\"></i>")
  end

  ##
  # @param string [String]
  # @return [String] Base64-encoded string
  #
  def qr_code(string)
    require 'barby'
    require 'barby/barcode'
    require 'barby/barcode/qr_code'
    require 'barby/outputter/png_outputter'

    barcode = Barby::QrCode.new(string, level: :q, size: 5)
    base64_output = Base64.encode64(barcode.to_png({ xdim: 5 }))
    "data:image/png;base64,#{base64_output}"
  end

  ##
  # @param entity [Entity]
  # @return [String] Text description of the entity's type
  #
  def type_of(entity)
    type = 'Item'
    if entity.kind_of?(Item)
      if entity.is_audio?
        type = 'Audio'
      elsif entity.is_image?
        type = 'Image'
      elsif entity.is_pdf? or entity.is_text?
        type = 'Text'
      elsif entity.is_video?
        type = 'Video'
      elsif entity.children.any?
        type = 'Multi-Page Item'
      end
    elsif entity.kind_of?(Collection) or entity == Collection
      type = 'Collection'
    end
    type
  end

  private

  def collection_view_breadcrumb(collection)
    html = "<ol class=\"breadcrumb\">"\
      "<li>#{link_to 'Home', root_path}</li>"\
      "<li>#{link_to 'Collections', collections_path}</li>"\
      "<li class=\"active\">#{truncate(collection.title, length: 50)}</li>"\
    "</ol>"
    raw(html)
  end

  def collections_view_breadcrumb
    nil # no breadcrumb in this view
  end

  def item_view_breadcrumb(item, context, context_url)
    case context
      when ItemsController::BrowseContext::SEARCHING
        html = "<ol class=\"breadcrumb\">"\
          "<li>#{link_to 'Home', root_path}</li>"\
          "<li>#{link_to 'Search', context_url}</li>"
        if item.parent_id
          html += "<li>#{link_to item.parent.title, item.parent}</li>"
        end
        html += "<li class=\"active\">#{truncate(item.title, length: 50)}</li>"\
          "</ol>"
      when ItemsController::BrowseContext::BROWSING_COLLECTION
        html = "<ol class=\"breadcrumb\">"\
          "<li>#{link_to 'Home', root_path}</li>"\
          "<li>#{link_to 'Collections', collections_path}</li>"\
          "<li>#{link_to item.collection.title, item.collection}</li>"\
          "<li>#{link_to 'Items', collection_items_path(item.collection)}</li>"
        if item.parent
          html += "<li>#{link_to item.parent.title, item.parent}</li>"
        end
        html += "<li class=\"active\">#{truncate(item.title, length: 50)}</li>"\
          "</ol>"
      when ItemsController::BrowseContext::BROWSING_ALL_ITEMS
        html = "<ol class=\"breadcrumb\">"\
          "<li>#{link_to 'Home', root_path}</li>"\
          "<li>#{link_to 'All Items', items_path}</li>"
        if item.parent
          html += "<li>#{link_to item.parent.title, item.parent}</li>"
        end
        html += "<li class=\"active\">#{truncate(item.title, length: 50)}</li>"\
          "</ol>"
      when ItemsController::BrowseContext::FAVORITES
        html = "<ol class=\"breadcrumb\">"\
          "<li>#{link_to 'Home', root_path}</li>"\
          "<li>#{link_to 'Favorites', favorites_path}</li>"
        if item.parent
          html += "<li>#{link_to item.parent.title, item.parent}</li>"
        end
        html += "<li class=\"active\">#{truncate(item.title, length: 50)}</li>"\
          "</ol>"
      else
        html = "<ol class=\"breadcrumb\">"\
          "<li>#{link_to 'Home', root_path}</li>"\
          "<li>#{link_to 'Collections', collections_path}</li>"\
          "<li>#{link_to item.collection.title, item.collection}</li>"
        if item.parent
          html += "<li>#{link_to item.parent.title, item.parent}</li>"
        end
        html += "<li class=\"active\">#{truncate(item.title, length: 50)}</li>"\
          "</ol>"
    end
    raw(html)
  end

  def results_breadcrumb(collection, context)
    if context == ItemsController::BrowseContext::BROWSING_COLLECTION
      html = "<ol class=\"breadcrumb\">"\
                "<li>#{link_to('Home', root_path)}</li>"\
                "<li>#{link_to('Collections', collections_path)}</li>"\
                "<li>#{link_to(truncate(collection.title, length: 50), collection)}</li>"\
                "<li class=\"active\">Items</li>"\
              "</ol>"
      return raw(html)
    end
  end

end
