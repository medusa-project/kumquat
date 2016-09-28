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
        variant: self.variant,
        full_text: self.full_text,
        parent: self.parent ? item_url(self.parent) : nil,
        representative_item: self.representative_item ?
            item_url(self.representative_item) : nil,
        elements: [],
        bytestreams: BytestreamDecorator.decorate_collection(self.bytestreams),
        children: []
    }

    # Populate the elements array
    self.elements.each do |element|
      profile_element = self.collection.metadata_profile.elements.
          select{ |ed| ed.name == element.name }.first
      struct[:elements] << {
          name: element.name,
          vocabulary: element.vocabulary&.name,
          value: element.value.present? ? element.value : nil,
          uri: element.uri.present? ? element.uri : nil,
          mappings: {
              dc: profile_element&.dc_map.present? ? profile_element.dc_map : nil,
              dcterms: profile_element&.dcterms_map.present? ? profile_element.dcterms_map : nil
          }
      }
    end

    # Populate the subitems array
    self.items.each do |subitem|
      struct[:subitems] << {
          id: subitem.repository_id,
          url: item_url(subitem)
      }
    end
    struct
  end

end
