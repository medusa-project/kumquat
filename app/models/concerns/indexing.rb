module Indexing

  def index_in_solr
    # TODO: write this
    Solr.client.add(self.to_solr)
  end

end
