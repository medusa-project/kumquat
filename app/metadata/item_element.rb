##
# Encapsulates a metadata element attached to an item. An element has a name
# matching any of the Element names.
#
class ItemElement < EntityElement

  belongs_to :item, inverse_of: :elements, touch: true

  ##
  # @return [Enumerable<ItemElement>]
  #
  def self.all_available
    Element.all.map { |e| ItemElement.new(name: e.name) }
  end

  ##
  # Parses a TSV value into a collection of elements.
  #
  # Example value:
  # string1&&<http://example.org/string1>||string2&&<http://example.org/string2>||lcsh:string3
  #
  # @param element_name [String] Element name
  # @param string [String] TSV string
  # @param vocabulary_override [Vocabulary] Optionally override any vocabularies
  #                                         specified in the string with this
  #                                         one.
  # @return [Enumerable<ItemElement>]
  # @raises [ArgumentError] If an element with the given name does not exist,
  #                         or an invalid vocabulary key is provided.
  #
  def self.elements_from_tsv_string(element_name, string,
      vocabulary_override = nil)
    unless Element.all.map(&:name).include?(element_name)
      raise ArgumentError, "Element does not exist: #{element_name}"
    end

    elements = []
    if string.present?
      # Strip out newlines and tabs.
      string = string.gsub("\r", '').gsub("\n", '').gsub("\t", '')

      string.split(Item::TSV_MULTI_VALUE_SEPARATOR).select(&:present?).each do |raw_value|
        e = ItemElement.named(element_name)
        # raw_value may be an arbitrary string; it may be a URI (enclosed
        # in angle brackets); or it may be both, joined with
        # Item::TSV_URI_VALUE_SEPARATOR.
        value_parts = raw_value.split(Item::TSV_URI_VALUE_SEPARATOR)
        value_parts.each do |part|
          if part.start_with?('<') and part.end_with?('>') and part.length > 2
            e.uri = part[1..part.length - 2]
          elsif part.present?
            # part may be prefixed with a vocabulary key.
            subparts = part.split(':')
            if subparts.length > 1 and Vocabulary.pluck(:key).include?(subparts[0])
              e.vocabulary = vocabulary_override || Vocabulary.find_by_key(subparts[0])
              e.value = subparts[1..subparts.length].join(':')
            else
              e.vocabulary = vocabulary_override || Vocabulary::uncontrolled
              e.value = part
            end
          end
        end
        elements << e
      end
    end
    elements
  end

  ##
  # @return [ItemElement, nil] ItemElement with the given name, or nil if the
  #                            given name is not an available element name.
  #
  def self.named(name)
    all_available.select{ |e| e.name == name }.first
  end

  def ==(obj)
    obj.kind_of?(ItemElement) and obj.name == self.name and
        obj.value == self.value and obj.uri == self.uri and
        obj.vocabulary_id == self.vocabulary_id
  end

end