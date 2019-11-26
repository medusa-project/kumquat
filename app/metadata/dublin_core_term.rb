class DublinCoreTerm

  @@elements = YAML::load_file(File.join(__dir__, 'dublin_core_terms.yml'))

  attr_accessor :label
  attr_accessor :name

  def self.all
    elements = []
    @@elements.each do |name, props|
      e = DublinCoreTerm.new
      e.name = name
      e.label = props['label']
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
