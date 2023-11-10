namespace :binaries do

  desc 'Run OCR on a binary'
  task :ocr, [:id] => :environment do |task, args|
    binary = Binary.find(args[:id])
    OcrBinaryJob.new(binary: binary).perform_in_foreground
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
