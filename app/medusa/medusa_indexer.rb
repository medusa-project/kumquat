class MedusaIndexer

  def index_collections
    all_medusa_collections.each { |mc| mc.save }
    Solr.instance.commit
  end

  private

  def all_medusa_collections
    config = PearTree::Application.peartree_config
    url = sprintf('%s/collections.json', config[:medusa_url].chomp('/'))
    response = Medusa.client.get(url)
    struct = JSON.parse(response.body)
    struct.map{ |s| MedusaCollection.from_medusa(s) }
  end

end
