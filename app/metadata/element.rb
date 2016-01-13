class Element

  class Type
    DESCRIPTIVE = 0
    TECHNICAL = 1
  end

  @@element_defs = YAML::load_file(File.join(__dir__, 'metadata.yml'))

  attr_accessor :name
  attr_accessor :type
  attr_accessor :value

  def self.all
    all_elements = []
    @@element_defs.each do |name, defs|
      e = Element.new
      e.name = name
      e.type = (defs['type'] == 'descriptive') ? Type::DESCRIPTIVE : Type::TECHNICAL
      all_elements << e
    end
    all_elements
  end

  def self.named(name)
    all.select{ |e| e.name == name }.first
  end

  def self.solr_facet_suffix
    '_facet'
  end

  def self.solr_prefix
    'metadata_'
  end

  def self.solr_suffix
    '_txtim'
  end

  def solr_facet_name
    "#{self.name}#{Element.solr_suffix}#{Element.solr_facet_suffix}"
  end

  def solr_name
    "#{Element.solr_prefix}#{self.name}#{Element.solr_suffix}"
  end

end