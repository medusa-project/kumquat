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
                     ingest_mode: args[:mode],
                     options:     { extract_metadata: false }).perform_in_foreground
  end

  desc 'Update items from a TSV file'
  task :update_from_tsv, [:pathname] => :environment do |task, args|
    UpdateItemsFromTsvJob.new(tsv_pathname: args[:pathname]).perform_in_foreground
  end

end