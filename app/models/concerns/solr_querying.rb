##
# Defines finder methods on [Entity].
#
module SolrQuerying

  def self.included(mod)
    mod.extend ClassMethods
  end

  module ClassMethods

    ##
    # @return [Relation]
    #
    def all
      Relation.new(self)
    end

    ##
    # @param id [String] Repository node URI
    # @return [Entity]
    # @raise [RuntimeError] If no matching entity is found
    #
    def find(id)
      result = self.find_by_id(id)
      raise ActiveRecord::RecordNotFound,
            "Unable to find entity with ID #{id}" unless result
      result
    end

    ##
    # @param id [String]
    # @return [Entity]
    #
    def find_by_id(id)
      self.where(PearTree::Application.peartree_config[:solr_id_field] => id).
          limit(1).first
    end

    alias_method :find_by_uri, :find_by_id

    def method_missing(name, *args, &block)
      name_s = name.to_s
      # handle Relation-like calls
      if [:count, :first, :limit, :order, :start, :where].include?(name.to_sym)
        return Relation.new(self).send(name, *args, &block)
      elsif name_s.start_with?('find_by_')
        # handle find_by_x calls
        return self.where(name_s.gsub(/find_by_/, '') => args[0]).facet(false).first
      end
      super
    end

    ##
    # @return [Relation] An empty Relation.
    #
    def none
      Relation.new
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name_s = method_name.to_s
      if %w(count first limit order start where).include?(method_name_s)
        return true
      elsif method_name_s.start_with?('find_by_') and
          self.properties.select{ |p| p.class == self and
              p.name.to_s == method_name_s.gsub(/find_by_/, '') }.any?
        return true
      end
      super
    end

  end

end
