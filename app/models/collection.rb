class Collection < Entity

  def self.from_solr(doc)
    col = Collection.new
    col.id = doc[Solr::Fields::ID]
    col.published = doc[Solr::Fields::PUBLISHED]
    col.subtitle = doc[Solr::Fields::SUBTITLE]
    col.title = doc[Solr::Fields::TITLE]
    col.web_id = doc[Solr::Fields::WEB_ID]
    col.instance_variable_set('@persisted', true)
    col
  end

  def num_items
    @num_items = Item.where(Solr::Fields::COLLECTION => self.id).
        where("-#{Solr::Fields::PARENT_ITEM}:[* TO *]").count unless @num_items
    @num_items
  end

end
