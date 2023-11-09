namespace :diagnostics do

  # Workaround for https://github.com/medusa-project/digital-library-issues/issues/78
  desc 'Add titles to items with no titles'
  task add_titles: :environment do
    sql = "SELECT i.repository_id AS repository_id
        FROM items i
        WHERE NOT EXISTS (
            SELECT value
            FROM entity_elements e
            WHERE e.item_id = i.id
                AND e.name = 'title'
        );"
    results   = ActiveRecord::Base.connection.exec_query(sql)
    num_added = 0
    parents_missing_titles = []
    results.each do |row|
      item = Item.find_by_repository_id(row['repository_id'])
      if item.parent_repository_id.present?
        pres_master = item.binaries.find{ |b| b.master_type == Binary::MasterType::PRESERVATION }
        if pres_master
          key   = pres_master.object_key
          title = File.basename(key, File.extname(key))
          item.elements.build(name:       "title",
                              value:      title,
                              vocabulary: Vocabulary.uncontrolled).save!
          num_added += 1
        end
      else
        parents_missing_titles << item
        item.elements.build(name:       "title",
                            value:      item.repository_id,
                            vocabulary: Vocabulary.uncontrolled).save!
      end
    end
    puts "Added #{num_added} titles"
    puts "Parents missing titles:"
    parents_missing_titles.sort_by{ |i| i.collection.title }.each do |item|
      puts "#{item.collection.title}\t#{item.repository_id}"
    end
  end

  desc "Return a count of title-less items"
  task count_titleless: :environment do
    sql = "SELECT COUNT(i.id) AS count
      FROM items i
      WHERE NOT EXISTS (
          SELECT value
          FROM entity_elements e
          WHERE e.item_id = i.id
            AND e.name = 'title'
      );"
    results = ActiveRecord::Base.connection.exec_query(sql)
    if results[0]['count'] > 0
      KumquatMailer.error("#{results[0]['count']} items have no title").deliver_now
    end
  end

end
