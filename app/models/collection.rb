class Collection < Entity

  def self.from_solr(doc)
    col = Collection.new
    col.id = doc[Solr::Fields::ID]
    col.published = doc[Solr::Fields::PUBLISHED]
    col.title = doc[Solr::Fields::TITLE]
    col.web_id = doc[Solr::Fields::WEB_ID]

    %w(dc dcterms).each do |element_set|
      doc.keys.select{ |k| k.start_with?("#{element_set}_") }.each do |key|
        col.metadata[element_set] = {} unless col.metadata[element_set]
        element = key.gsub(/#{element_set}_/, '').chomp('_txtim')
        col.metadata[element_set][element] = doc[key]
      end
    end

    col.instance_variable_set('@persisted', true)
    col
  end

  def num_items
    @num_items = Item.where(Solr::Fields::COLLECTION => self.id).
        where("-#{Solr::Fields::PARENT_ITEM}:[* TO *]").count unless @num_items
    @num_items
  end

end
