class MedusaIndexer

  def index_collections(task = nil)
    config = PearTree::Application.peartree_config
    url = sprintf('%s/collections.json', config[:medusa_url].chomp('/'))
    response = Medusa.client.get(url)
    struct = JSON.parse(response.body)
    struct.each_with_index do |st, index|
      MedusaCollection.from_medusa(st).save
      if task and index % 10 == 0
        task.percent_complete = index / struct.length.to_f
        task.save
      end
    end
  end

end
