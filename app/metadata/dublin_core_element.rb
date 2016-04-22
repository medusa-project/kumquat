class DublinCoreElement

  @@elements = YAML::load_file(File.join(__dir__, 'dublin_core_elements.yml'))

  attr_accessor :label
  attr_accessor :name

  def self.all
    elements = []
    @@elements.each do |name, props|
      e = DublinCoreElement.new
      e.name = name
      e.label = props['label']
      elements << e
    end
    elements
  end

  def self.label_for(element_name)
    self.all.select{ |e| e.name == element_name }.first&.label
  end

end
