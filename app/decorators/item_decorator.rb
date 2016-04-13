##
# Assists in creating an optimized JSON serialization.
#
class ItemDecorator < Draper::Decorator
  delegate_all
  include Draper::LazyHelpers

  # Define presentation-specific methods here. Helpers are accessed through
  # `helpers` (aka `h`). You can override attributes, for example:
  #
  #   def created_at
  #     helpers.content_tag :span, class: 'time' do
  #       object.created_at.strftime("%a %m/%d/%y")
  #     end
  #   end

  def serializable_hash(opts)
    struct = {
        id: self.repository_id,
        collection: self.collection ? collection_url(self.collection) : nil,
        page_number: self.page_number,
        subpage_number: self.subpage_number,
        subclass: self.subclass,
        full_text: self.full_text,
        parent: self.parent ? item_url(self.parent) : nil,
        representative_item: self.representative_item ?
            item_url(self.representative_item) : nil,
        elements: self.elements,
        bytestreams: BytestreamDecorator.decorate_collection(self.bytestreams),
        subitems: []
    }
    self.items.each do |subitem|
      struct[:subitems] << {
          id: subitem.repository_id,
          url: item_url(subitem)
      }
    end
    struct
  end

end
