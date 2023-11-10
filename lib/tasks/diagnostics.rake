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
    results               = ActiveRecord::Base.connection.exec_query(sql)
    repaired_parent_items = []
    repaired_child_items  = []
    unable_to_repair      = []
    results.each do |row|
      item = Item.find_by_repository_id(row['repository_id'])
      if item.parent_repository_id.present?
        master_binary =
          item.binaries.find{ |b| b.master_type == Binary::MasterType::PRESERVATION } ||
          item.binaries.find{ |b| b.master_type == Binary::MasterType::ACCESS }
        if master_binary
          repaired_child_items << item
          key   = master_binary.object_key
          title = File.basename(key, File.extname(key)) # filename without extension
          e = item.elements.build(name:       "title",
                                  value:      title,
                                  vocabulary: Vocabulary.uncontrolled)
          e.save!
        end
      else
        repaired_parent_items << item
        e = item.elements.build(name:       "title",
                                value:      item.repository_id,
                                vocabulary: Vocabulary.uncontrolled)
        e.save!
      end
    end
    puts "Parent items that are missing titles:"
    puts "Collection Title\tItem ID\tNew Title"
    repaired_parent_items.sort_by{ |i| i.collection.title }.each do |item|
      puts "#{item.collection.title}\t#{item.repository_id}\t#{item.title}"
    end
    puts ""
    puts "Child items that are missing titles:"
    puts "Collection Title\tParent Item ID\tItem ID\tNew Title"
    repaired_child_items.sort_by{ |i| [i.collection.title, i.parent_repository_id] }.each do |item|
      puts "#{item.collection.title}\t#{item.parent_repository_id}\t#{item.repository_id}\t#{item.title}"
    end
    puts ""
    puts "Unable to repair (items have no binaries):"
    puts "Collection Title\tItem ID"
    unable_to_repair.sort_by{ |i| i.collection.title }.each do |item|
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
