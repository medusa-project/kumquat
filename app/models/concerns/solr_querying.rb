module SolrQuerying

  def self.included(mod)
    mod.extend ClassMethods
  end

  module ClassMethods

    ##
    # @return [Relation]
    #
    def solr
      Relation.new(self)
    end

  end

end
