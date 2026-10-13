namespace :items do

  desc 'Delete orphaned indexed item documents'
  task :delete_orphaned_documents => :environment do |task, args|
    Item.delete_orphaned_documents
  end

  desc 'Export an item and all children as TSV'
  task :export_as_tsv, [:uuid] => :environment do |task, args|
    item = Item.find_by_repository_id(args[:uuid])
    raise ArgumentError, 'Item does not exist' unless item
    if item.collection.free_form?
      items = item.all_files
    else
      items = [item]
      items += item.all_children
    end
    puts ItemTsvExporter.new.items(items)
  end

  desc 'Export all items in a collection as TSV'
  task :export_collection_as_tsv, [:collection_uuid] => :environment do |task, args|
    col = Collection.find_by_repository_id(args[:collection_uuid])
    raise ArgumentError, 'Collection does not exist' unless col
    puts ItemTsvExporter.new.items_in_collection(col)
  end

  desc 'Generate a PDF of an item'
  task :generate_pdf, [:uuid, :path] => :environment do |task, args|
    item = Item.find_by_repository_id(args[:uuid])
    raise ArgumentError, 'Item does not exist' unless item
    pdf_path = PdfGenerator.new.generate_pdf(item: item,
                                             include_private_binaries: true)
    FileUtils.mv(pdf_path, File.expand_path(args[:path]))
  end

  desc 'Run OCR on an item and all children'
  task :ocr, [:uuid] => :environment do |task, args|
    item = Item.find_by_repository_id(args[:uuid])
    OcrItemJob.new(item: item).perform_in_foreground
  end

  desc 'Delete all items from a collection'
  task :purge_collection, [:uuid] => :environment do |task, args|
    Collection.find_by_repository_id(args[:uuid]).purge
  end

  desc 'Reindex an item and all of its children. Omit uuid to index all items'
  task :reindex, [:index_name, :uuid] => :environment do |task, args|
    if args[:uuid].present?
      item = Item.find_by_repository_id(args[:uuid])
      item.all_children.to_a.push(item).each do |it|
        it.reindex(args[:index_name])
      end
    else
      Item.reindex_all(es_index: args[:index_name])
    end
  end

  desc 'Reindex items in a collection'
  task :reindex_collection, [:uuid] => :environment do |task, args|
    col = Collection.find_by_repository_id(args[:uuid])
    col.reindex_items
  end

  desc 'Sync items from Medusa (modes: create_only, recreate_binaries, delete_missing)'
  task :sync, [:collection_uuid, :mode] => :environment do |task, args|
    collection = Collection.find_by_repository_id(args[:collection_uuid])
    SyncItemsJob.new(collection:  collection,
                     ingest_mode: args[:mode]).perform_in_foreground
  end

  desc 'Update items from a TSV file'
  task :update_from_tsv, [:pathname] => :environment do |task, args|
    UpdateItemsFromTsvJob.new(tsv_pathname: args[:pathname]).perform_in_foreground
  end

  desc 'Export repeated metadata values for items with bib IDs in a Medusa repository'
  task :audit_metadata_order, [:medusa_repository_id, :output_path, :batch_size] => :environment do |task, args|
    require 'csv'

    medusa_repository_id = Integer(args[:medusa_repository_id], 10)
    output_path = args[:output_path].presence
    batch_size = args[:batch_size].present? ? Integer(args[:batch_size], 10) : 200

    raise ArgumentError, 'Output path is required' unless output_path
    raise ArgumentError, 'Batch size must be greater than zero' unless batch_size > 0

    collections = Collection.where(medusa_repository_id: medusa_repository_id)
    collection_repository_ids = collections.pluck(:repository_id)
    raise ArgumentError, 'No collections found for Medusa repository' if collection_repository_ids.empty?

    profile_elements_by_collection = collections.includes(:metadata_profile).each_with_object({}) do |collection, profiles|
      profiles[collection.repository_id] =
        collection.metadata_profile&.elements&.index_by(&:name) || {}
    end

    items_with_bib_ids = ItemElement.
      where(name: 'bibId').
      where.not(value: [nil, '']).
      select(:item_id)
    eligible_item_ids = Item.
      where(collection_repository_id: collection_repository_ids).
      where(id: items_with_bib_ids).
      select(:id)

    output_path = File.expand_path(output_path)
    FileUtils.mkdir_p(File.dirname(output_path))

    processed_items = 0
    written_rows = 0
    headers = %w(collection_repository_id item_repository_id bib_id catalog_record_url
                 element_name element_label value_position vocabulary_id value)

    CSV.open(output_path, 'wb') do |csv|
      csv << headers

      Item.where(id: eligible_item_ids).preload(:elements).
        find_in_batches(batch_size: batch_size) do |items|
        items.each do |item|
          processed_items += 1
          item.elements.group_by(&:name).each do |name, elements|
            value_elements = elements.select { |element| element.value.present? }
            values = value_elements.map(&:value)
            next if values.uniq.length < 2

            profile_element = profile_elements_by_collection.
              dig(item.collection_repository_id, name)
            value_elements.each_with_index do |element, index|
              csv << [item.collection_repository_id,
                      item.repository_id,
                      item.bib_id,
                      item.catalog_record_url,
                      name,
                      profile_element&.label || name,
                      index + 1,
                      element.vocabulary_id,
                      element.value]
              written_rows += 1
            end
          end
        end
      end
    end

    puts "Processed #{processed_items} items; wrote #{written_rows} repeated-value rows to #{output_path}"
  end

  desc 'Report collections with repeated metadata values'
  task :report_repeated_metadata_by_collection, [:output_path, :batch_size, :medusa_repository_id] => :environment do |task, args|
    require 'csv'

    output_path = args[:output_path].presence
    batch_size = args[:batch_size].present? ? Integer(args[:batch_size], 10) : 200
    medusa_repository_id = args[:medusa_repository_id].present? ?
      Integer(args[:medusa_repository_id], 10) : nil

    raise ArgumentError, 'Output path is required' unless output_path
    raise ArgumentError, 'Batch size must be greater than zero' unless batch_size > 0

    collections = Collection.where.not(package_profile_id: nil)
    collections = collections.where(medusa_repository_id: medusa_repository_id) if medusa_repository_id

    collection_stats = collections.includes(:elements, :package_profile).
      each_with_object({}) do |collection, stats|
      stats[collection.repository_id] = {
        title: collection.title,
        medusa_repository_id: collection.medusa_repository_id,
        package_profile: collection.package_profile&.name,
        published_in_dls: collection.published_in_dls,
        public_in_medusa: collection.public_in_medusa,
        restricted: collection.restricted,
        item_count: 0,
        items_with_repeated_values: 0,
        repeated_value_groups: 0,
        repeated_element_names: {}
      }
    end

    raise ArgumentError, 'No collections found for the requested scope' if collection_stats.empty?

    processed_items = 0
    output_path = File.expand_path(output_path)
    FileUtils.mkdir_p(File.dirname(output_path))
    headers = %w(collection_repository_id collection_title medusa_repository_id
                 package_profile published_in_dls public_in_medusa restricted
                 item_count items_with_repeated_values repeated_value_groups
                 has_repeated_values repeated_element_names)

    Item.where(collection_repository_id: collection_stats.keys).
      preload(:elements).
      find_in_batches(batch_size: batch_size) do |items|
      items.each do |item|
        processed_items += 1
        stats = collection_stats[item.collection_repository_id]
        stats[:item_count] += 1
        item_has_repeated_values = false

        item.elements.group_by(&:name).each do |name, elements|
          values = elements.map(&:value).select(&:present?)
          next if values.uniq.length < 2

          item_has_repeated_values = true
          stats[:repeated_value_groups] += 1
          stats[:repeated_element_names][name] = true
        end

        stats[:items_with_repeated_values] += 1 if item_has_repeated_values
      end
    end

    written_rows = 0
    CSV.open(output_path, 'wb') do |csv|
      csv << headers
      collection_stats.sort_by { |_repository_id, stats| stats[:title].to_s.downcase }.
        each do |repository_id, stats|
        csv << [repository_id,
                stats[:title],
                stats[:medusa_repository_id],
                stats[:package_profile],
                stats[:published_in_dls],
                stats[:public_in_medusa],
                stats[:restricted],
                stats[:item_count],
                stats[:items_with_repeated_values],
                stats[:repeated_value_groups],
                stats[:repeated_value_groups] > 0,
                JSON.generate(stats[:repeated_element_names].keys.sort)]
        written_rows += 1
      end
    end

    puts "Processed #{processed_items} items across #{written_rows} collections; wrote report to #{output_path}"
  end

end