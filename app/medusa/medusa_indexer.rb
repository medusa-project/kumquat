class MedusaIndexer

  def index_collections(task = nil)
    config = PearTree::Application.peartree_config
    url = sprintf('%s/collections.json', config[:medusa_url].chomp('/'))

    Rails.logger.info('MedusaIndexer.index_collections(): retrieving collection list')
    response = Medusa.client.get(url, follow_redirect: true)
    struct = JSON.parse(response.body)
    struct.each_with_index do |st, index|
      col = Collection.find_or_create_by(repository_id: st['uuid'])
      col.update_from_medusa
      col.save!

      if task and index % 10 == 0
        task.percent_complete = index / struct.length.to_f
        task.save
      end
    end
  end

end
