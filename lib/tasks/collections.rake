namespace :collections do

  desc 'Delete orphaned indexed collection documents'
  task :delete_orphaned_documents => :environment do |task, args|
    Collection.delete_orphaned_documents
  end

  desc 'Email lists of newly published items to watchers'
  task :email_new_items => :environment do |task, args|
    Watch.send_new_item_emails
  end

  desc 'Run OCR on all items in a collection'
  task :ocr, [:uuid, :language] => :environment do |task, args|
    collection = Collection.find_by_repository_id(args[:uuid])
    language   = args[:language] || 'eng'
    OcrCollectionJob.new(collection:            collection,
                         language_code:         language,
                         include_already_ocred: true).perform_in_foreground
  end

  desc 'Publish a collection'
  task :publish, [:uuid] => :environment do |task, args|
    Collection.find_by_repository_id(args[:uuid]).
      update!(public_in_medusa: true, published_in_dls: true)
  end

  desc 'Reindex all collections'
  task :reindex, [:index_name] => :environment do |task, args|
    Collection.reindex_all(es_index: args[:index_name])
  end

  desc 'Sync collections from Medusa'
  task :sync => :environment do
    SyncCollectionsJob.new.perform_in_foreground
  end

end