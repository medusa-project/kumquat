class DublinCoreElement

  ALL_ELEMENTS = YAML.unsafe_load_file(File.join(__dir__, 'dublin_core_elements.yml'))

  # @!attribute label
  #   @return [String] Human-readable label.
  attr_accessor :label

  # @!attribute name
  #   @return [String] Element name.
  attr_accessor :name

  def self.all
    elements = []
    ALL_ELEMENTS.each do |name, props|
      e = DublinCoreElement.new
      e.name = name
      e.label = props['label']
      elements << e
    end
    elements
  end

  ##
  # @return [DublinCoreElement]
  #
  def self.label_for(element_name)
    self.all.find{ |e| e.name == element_name }&.label
  end

end
