class DublinCoreTerm

  ALL_ELEMENTS = YAML.unsafe_load_file(File.join(__dir__, 'dublin_core_terms.yml'))

  attr_accessor :label, :name

  def self.all
    elements = []
    ALL_ELEMENTS.each do |name, props|
      e         = DublinCoreTerm.new
      e.name    = name
      e.label   = props['label']
      elements << e
    end
    elements
  end

  ##
  # @return [DublinCoreTerm]
  #
  def self.label_for(element_name)
    self.all.find{ |e| e.name == element_name }&.label
  end

end
