namespace :dls do

  desc 'Check access to AWS resources (temporary task to assist jmtroy)'
  task :aws_check => :environment do |task, args|
    print "Checking access to RDS... "
    Binary.all.limit(1).first
    print "OK\n"

    print "Checking read access to #{MedusaS3Client::BUCKET} bucket... "
    MedusaS3Client.instance.head_object(
      bucket: MedusaS3Client::BUCKET,
      key: "162/2204/6713580/access/6713580_02.jp2")
    print "OK\n"

    print "Checking access to Elasticsearch... "
    ElasticsearchClient.instance.indexes
    print "OK\n"

    print "Checking access to Lambda... "
    Binary.where(media_type: "image/jpeg").first.detect_text
    print "OK\n"
  end

  namespace :agents do

    desc 'Delete orphaned indexed agent documents'
    task :delete_orphaned_documents => :environment do |task, args|
      Agent.delete_orphaned_documents
    end

    desc 'Reindex all agents'
    task :reindex, [:index_name] => :environment do |task, args|
      Agent.reindex_all(es_index: args[:index_name])
    end

  end

  namespace :binaries do

    desc 'Run OCR on a binary'
    task :ocr, [:id] => :environment do |task, args|
      OcrBinaryJob.new(args[:id]).perform_in_foreground
    end

    desc 'Recreate binaries in all collections'
    task :recreate => :environment do
      ActiveRecord::Base.transaction do
        Collection.all.each do |collection|
          next if collection.items.count == 0
          puts collection.title
          MedusaIngester.new.recreate_binaries(collection)
        end
      end
    end

    desc 'Recreate binaries in a collection'
    task :recreate_in_collection, [:uuid] => :environment do |task, args|
      collection = Collection.find_by_repository_id(args[:uuid])
      ActiveRecord::Base.transaction do
        MedusaIngester.new.recreate_binaries(collection)
      end
    end

    desc 'Populate the byte sizes of all binaries'
    task :populate_byte_sizes => :environment do
      Binary.uncached do
        binaries = Binary.where(byte_size: nil).where('object_key IS NOT NULL')
        count = binaries.count
        puts "#{count} binaries to update"

        binaries.find_each.with_index do |binary, index|
          puts "(#{((index / count.to_f) * 100).round(2)}%) #{binary.object_key}"

          begin
            binary.read_size
            binary.save!
          rescue => e
            puts e
          end
        end
      end
    end

    desc 'Populate the durations of all binaries'
    task :populate_durations => :environment do
      Binary.uncached do
        binaries = Binary.where(duration: nil).
            where('media_type LIKE \'audio/%\' OR media_type LIKE \'video/%\'').
            where('object_key IS NOT NULL')
        count = binaries.count
        puts "#{count} binaries to update"

        binaries.find_each.with_index do |binary, index|
          puts "(#{((index / count.to_f) * 100).round(2)}%) #{binary.object_key}"

          begin
            binary.read_duration
            binary.save!
          rescue => e
            puts e
          end
        end
      end
    end

    desc 'Populate the media category of all binaries'
    task :populate_media_categories => :environment do
      Binary.uncached do
        binaries = Binary.where(media_category: nil).
            where('media_type IS NOT NULL')
        count = binaries.count
        puts "#{count} binaries to update"

        binaries.find_each.with_index do |binary, index|
          puts "(#{((index / count.to_f) * 100).round(2)}%) #{binary.object_key}"

          binary.media_category =
              Binary::MediaCategory::media_category_for_media_type(binary.media_type)
          binary.save!
        end
      end
    end

    desc 'Populate the metadata of all binaries'
    task :populate_metadata => :environment do
      Binary.uncached do
        binaries = Binary.where('metadata_json IS NULL OR width IS NULL OR height IS NULL').
          where('media_type LIKE \'image/%\' OR media_type = \'application/pdf\'').
          where('object_key IS NOT NULL')
        count = binaries.count
        puts "#{count} binaries to update"

        binaries.find_each.with_index do |binary, index|
          puts "(#{((index / count.to_f) * 100).round(2)}%) #{binary.object_key}"
          begin
            binary.read_metadata
            binary.save!
          rescue => e
            puts e
          end
        end
      end
    end

  end

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
      language = args[:language] || 'eng'
      OcrCollectionJob.new(args[:uuid], language, true).perform_in_foreground
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

  namespace :downloads do

    desc 'Clean up old downloads'
    task :cleanup => :environment do
      Download.cleanup(60 * 60 * 24) # max 1 day old
    end

    desc 'Expire all downloads'
    task :expire => :environment do
      Download.all.each(&:expire)
    end

  end

  namespace :images do

    desc 'Purge all images from the image server cache'
    task :purge_all => :environment do
      ImageServer.instance.purge_all_images_from_cache
    end

    desc 'Purge all images associated with an item from the image server cache'
    task :purge_item, [:uuid] => :environment do |task, args|
      item = Item.find_by_repository_id(args[:uuid])
      ImageServer.instance.purge_item_images_from_cache(item)
    end

    desc 'Purge all images associated with any item in a collection from the image server cache'
    task :purge_collection, [:uuid] => :environment do |task, args|
      col = Collection.find_by_repository_id(args[:uuid])
      ImageServer.instance.purge_collection_item_images_from_cache(col)
    end

  end

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
      OcrItemJob.new(args[:uuid]).perform_in_foreground
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
        reindex_items(args[:index_name])
      end
    end

    desc 'Reindex items in a collection'
    task :reindex_collection, [:uuid] => :environment do |task, args|
      col = Collection.find_by_repository_id(args[:uuid])
      col.reindex_items
    end

    desc 'Sync items from Medusa (modes: create_only, recreate_binaries, delete_missing)'
    task :sync, [:collection_uuid, :mode] => :environment do |task, args|
      SyncItemsJob.new(args[:collection_uuid], args[:mode],
                       extract_metadata: false).perform_in_foreground
    end

    desc 'Update items from a TSV file'
    task :update_from_tsv, [:pathname] => :environment do |task, args|
      UpdateItemsFromTsvJob.new(args[:pathname]).perform_in_foreground
    end

  end

  namespace :tasks do

    desc 'Clear all tasks'
    task :clear => :environment do
      Task.destroy_all
    end

    desc 'Clear running tasks'
    task :clear_running => :environment do
      Task.where(status: Task::Status::RUNNING).destroy_all
    end

    desc 'Clear waiting tasks'
    task :clear_waiting => :environment do
      Task.where(status: Task::Status::WAITING).destroy_all
    end

    desc 'Fail running tasks'
    task :fail_running => :environment do
      Task.where(status: Task::Status::RUNNING).each(&:fail)
    end

    desc 'Run a test task'
    task :test => :environment do
      SleepJob.new(15).perform_in_foreground
    end

  end

  def reindex_items(index = nil)
    Item.reindex_all(es_index: index)
  end

end
