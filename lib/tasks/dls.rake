namespace :dls do

  desc 'Check access to AWS resources'
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

  namespace :collections do

    desc 'Delete orphaned indexed collection documents'
    task :delete_orphaned_documents => :environment do |task, args|
      Collection.delete_orphaned_documents
    end

    desc 'Email lists of newly published items to watchers'
    task :email_new_items => :environment do |task, args|
      Watch.send_new_item_emails
    end

    desc "Temp report"
    task :report => :environment do
      collections = Collection.where(repository_id: %w[eb857cd0-2f31-0133-a7e0-0050569601ca-7 ddaad430-1d95-0137-6b83-02d0d7bfd6e4-f 4dbfbe30-d29c-0133-1d21-0050569601ca-0 ac5aca50-e635-0138-74a4-02d0d7bfd6e4-a e663a020-353d-0133-a7ec-0050569601ca-b b1659f20-5103-0134-1dbe-0050569601ca-d 87e36180-aaf0-013a-c3a0-02d0d7bfd6e4-d 4dc64260-c7d3-0135-4aa0-0050569601ca-e 94dc3370-ecd3-0139-7a60-02d0d7bfd6e4-0 5d342ab0-eccc-0139-7a60-02d0d7bfd6e4-8 ddaad430-1d95-0137-6b83-02d0d7bfd6e4-f f7d09f70-f003-013a-c632-02d0d7bfd6e4-4 32eeb600-0081-0136-4c0b-0050569601ca-a de294740-a17f-0131-4a3f-0050569601ca-9 e4141ba0-bd17-0137-6ee6-02d0d7bfd6e4-5 63a302f0-15de-0132-f530-0050569601ca-9 e70510c0-e73c-0139-7a45-02d0d7bfd6e4-e 942a7970-5262-0137-6cad-02d0d7bfd6e4-8 cad6b590-6722-0134-1de2-0050569601ca-5 3af03940-b6bb-0135-49e7-0050569601ca-6 69f64850-8d97-0134-200b-0050569601ca-4 3d687ae0-e227-0132-182a-0050569601ca-f 1d989110-3cc1-0139-769d-02d0d7bfd6e4-0 3a9a00c0-1d99-0137-6b83-02d0d7bfd6e4-3 78a65140-e4e7-0135-4b25-0050569601ca-1 8f013ff0-dec5-013a-c5c0-02d0d7bfd6e4-5 5a7e77c0-98be-0131-1105-0050569601ca-d 309d0840-e21e-0132-182a-0050569601ca-4 36e1e030-c5b7-0134-237b-0050569601ca-0 e0c73760-e456-013a-c606-02d0d7bfd6e4-7 43108a60-9471-0138-72f9-02d0d7bfd6e4-0 bb53d620-d726-0137-6fb5-02d0d7bfd6e4-d 38ec6eb0-18c3-0135-242c-0050569601ca-1 5b0bb380-6df0-0138-7298-02d0d7bfd6e4-4 25dbe080-ad9b-0137-6e3d-02d0d7bfd6e4-c b2423a60-f001-013a-c632-02d0d7bfd6e4-c 2beaea30-4b0d-0136-4f6d-0050569601ca-5 0975a980-efe4-0131-d9cb-0050569601ca-c ffdd8730-218a-013b-c7cf-02d0d7bfd6e4-a 712d65c0-2c60-0136-4dae-0050569601ca-8 0f7a8470-1c10-0137-6b79-02d0d7bfd6e4-4 cdc57b70-9b1e-0131-1105-0050569601ca-e 098beeb0-42fb-0139-76ce-02d0d7bfd6e4-1 0189ac20-2189-013b-c7cf-02d0d7bfd6e4-9 1151e180-79b5-0137-6d43-02d0d7bfd6e4-c da1aaa60-0a9a-0136-4c9b-0050569601ca-4 3f8823a0-bded-0137-6ef9-02d0d7bfd6e4-7 1aab1d90-e05e-0136-5352-0050569601ca-1 b14d0060-3ac5-0132-3324-0050569601ca-6 420cd180-979c-0138-7304-02d0d7bfd6e4-f bb6e7500-6090-0138-7261-02d0d7bfd6e4-d b9f2d780-f464-0138-7528-02d0d7bfd6e4-8 be1c1d10-c853-0138-73db-02d0d7bfd6e4-d 1038ade0-6df6-0138-7298-02d0d7bfd6e4-c 9e579560-1e41-013a-7baf-02d0d7bfd6e4-4 b1512df0-13f8-013a-7b57-02d0d7bfd6e4-9 97705f60-7c56-0134-1e98-0050569601ca-4 4106bc40-bdf3-0137-6f04-02d0d7bfd6e4-6 c5babd80-a24d-0131-4a3f-0050569601ca-f edaca8a0-f004-013a-c632-02d0d7bfd6e4-a fb30d7d0-58e0-0134-1dc8-0050569601ca-7 0e381890-caf0-0134-2382-0050569601ca-5 3fadba30-571c-0138-7234-02d0d7bfd6e4-8 8a02d470-9299-0131-1105-0050569601ca-8 77915810-608a-0138-7261-02d0d7bfd6e4-8 aca344d0-1f7d-0138-70d2-02d0d7bfd6e4-f 9789e640-a0a0-0131-4a3f-0050569601ca-c b6321bd0-1338-013a-7b4e-02d0d7bfd6e4-4 97fd70a0-3b64-0132-3325-0050569601ca-a 4243aa30-2bb6-013a-7c18-02d0d7bfd6e4-b 01eb6f70-912a-013b-44b6-02d0d7bfd6e4-7 07367e40-c719-0139-7993-02d0d7bfd6e4-7 f00244a0-a7be-0131-4a42-0050569601ca-1 7edcc720-7fa2-0131-1102-0050569601ca-a d2b4f700-ad4f-0131-4a45-0050569601ca-b 6cd79a00-e44f-013a-c5fa-02d0d7bfd6e4-6 8d420900-c5b7-0134-237b-0050569601ca-2 43108a60-9471-0138-72f9-02d0d7bfd6e4-0 d753f420-a248-0131-4a3f-0050569601ca-e bb53d620-d726-0137-6fb5-02d0d7bfd6e4-d cd535a80-4852-0133-a7fd-0050569601ca-3 ec6fb9f0-718a-0136-5120-0050569601ca-9 d8b4eb70-4000-013a-7c8c-02d0d7bfd6e4-f 8e81a5e0-371d-0138-7161-02d0d7bfd6e4-6 313dc3a0-98e3-0131-1105-0050569601ca-1 5d7df610-c939-0138-73e5-02d0d7bfd6e4-d 17681000-f2b5-0138-7521-02d0d7bfd6e4-1 7ccd1cd0-f2f8-0139-7a76-02d0d7bfd6e4-3 cbaca0b0-2ad2-013b-c827-02d0d7bfd6e4-f ea63df90-912b-013b-44b6-02d0d7bfd6e4-4 590c3b10-97bd-0138-7304-02d0d7bfd6e4-7 2b25dab0-c135-0133-1d0f-0050569601ca-f 11aada80-b128-0131-4a46-0050569601ca-6 e72a6f50-e174-0138-7491-02d0d7bfd6e4-f 9b5d80d0-9473-0138-72f9-02d0d7bfd6e4-5 61586270-10a6-0138-70a3-02d0d7bfd6e4-8 7b8b24a0-f468-0138-7528-02d0d7bfd6e4-2 3f743710-af42-0138-7361-02d0d7bfd6e4-c 3c95cb00-906a-0132-fd37-0050569601ca-8 8b820bc0-9733-0131-1105-0050569601ca-0 e65c44b0-5248-0137-6cad-02d0d7bfd6e4-7 ce7942e0-36c5-0137-6c0e-02d0d7bfd6e4-e 4db796f0-3b65-0132-3325-0050569601ca-e 8dfd2160-ad91-0138-7357-02d0d7bfd6e4-e 43f0c070-317e-0138-714f-02d0d7bfd6e4-4 2fe8b300-3533-0132-331e-0050569601ca-b c1083450-3570-0133-a7f3-0050569601ca-7 55451950-793e-0135-0163-0050569601ca-5 103d52d0-7f28-0137-6d60-02d0d7bfd6e4-3 3d044cd0-ffe1-013a-c696-02d0d7bfd6e4-6 03644430-d73e-0137-6fb5-02d0d7bfd6e4-0 6049b8c0-f46d-0138-7528-02d0d7bfd6e4-4 3e4b7f10-3543-0133-a7ec-0050569601ca-f dd4dc6e0-c5b7-0134-237b-0050569601ca-3 2a554be0-ffdf-013a-c696-02d0d7bfd6e4-b 1eaa5260-5d05-013a-c231-02d0d7bfd6e4-6 a58511f0-6148-0132-333a-0050569601ca-3 ed931980-a87e-0131-4a42-0050569601ca-7 b5b9c910-ecbe-0139-7a60-02d0d7bfd6e4-f 14d5e390-f472-0138-7528-02d0d7bfd6e4-2 9dbfd350-a156-0131-4a3f-0050569601ca-d 9c3332f0-7b8a-0139-7802-02d0d7bfd6e4-b b846a650-cff7-0132-180b-0050569601ca-1 7a2b6350-298d-0138-7106-02d0d7bfd6e4-2 52603890-9737-0131-1105-0050569601ca-a 8ec7a2a0-a0a1-0131-4a3f-0050569601ca-3 c2a52750-f463-0138-7528-02d0d7bfd6e4-5 97905640-97ae-0138-7304-02d0d7bfd6e4-d f81928e0-2bb3-013a-7c18-02d0d7bfd6e4-0 07264bb0-9b2b-0131-1105-0050569601ca-3 629ca700-3b8a-0132-3325-0050569601ca-9 593ea720-7dc3-0134-1e9d-0050569601ca-d 79742770-a24b-0131-4a3f-0050569601ca-7 85c5efe0-bda4-0131-4a4b-0050569601ca-c aa18f550-4808-0137-6c7d-02d0d7bfd6e4-2 22270f00-9793-0138-7302-02d0d7bfd6e4-9 6e640b10-3b66-0132-3325-0050569601ca-f 0bd577a0-ae24-0131-4a45-0050569601ca-6 91ee58d0-15c6-0132-f530-0050569601ca-1 974c9b30-9062-0132-fd37-0050569601ca-4 e75c4a30-8ee7-0138-72e0-02d0d7bfd6e4-5 b866b880-cb81-0138-73f5-02d0d7bfd6e4-0 964d47e0-6d72-0139-77b0-02d0d7bfd6e4-3 ec7eff60-a7d4-0131-4a42-0050569601ca-e 91ac1250-ad9c-0137-6e3d-02d0d7bfd6e4-8 4fef9a30-a157-0131-4a3f-0050569601ca-0 58d60350-0cfc-013b-c725-02d0d7bfd6e4-e 11b19110-c018-0136-52ca-0050569601ca-d 58b5a7b0-a7d5-0131-4a42-0050569601ca-d c9b58580-c5b5-0134-237b-0050569601ca-6 f844fd60-3b66-0132-3325-0050569601ca-c 00180630-f2c9-0138-7521-02d0d7bfd6e4-d 3913b250-3551-0133-a7f0-0050569601ca-b f8871290-3b89-0132-3325-0050569601ca-b aeda0ed0-c5b6-0134-237b-0050569601ca-f d85d1900-b0ba-0137-6e46-02d0d7bfd6e4-8 6c399aa0-cff7-0132-180b-0050569601ca-b e4634110-97b9-0138-7304-02d0d7bfd6e4-2 99e1b490-bdea-0137-6ef9-02d0d7bfd6e4-2 3cfde400-a87d-0131-4a42-0050569601ca-1 a4902620-f80e-0137-7066-02d0d7bfd6e4-7 6e75f750-9739-0131-1105-0050569601ca-b 8350bab0-c527-0138-73cf-02d0d7bfd6e4-9 8f4d53b0-ef99-0138-7501-02d0d7bfd6e4-d 8a8e23e0-a253-0131-4a3f-0050569601ca-f ac541610-a0a4-0131-4a3f-0050569601ca-6 95fe1290-7620-0139-77de-02d0d7bfd6e4-2 bbcd8640-9727-0131-1105-0050569601ca-6 1c3a59a0-9e57-0131-4a3e-0050569601ca-5 d6ebf930-abb8-0131-4a44-0050569601ca-6 ee2609a0-270a-0137-6ba6-02d0d7bfd6e4-a bfac8630-e17a-0138-7493-02d0d7bfd6e4-7 12647930-d482-0131-267f-0050569601ca-6 e6b046c0-cde5-0138-7406-02d0d7bfd6e4-a 7909da60-b89b-0137-6ea6-02d0d7bfd6e4-e af8b4410-a870-013a-c38e-02d0d7bfd6e4-3 55fc9980-912c-013b-44b6-02d0d7bfd6e4-b 54435270-9036-013b-44a7-02d0d7bfd6e4-c 1fa085b0-3b89-0132-3325-0050569601ca-8 595fb2c0-a7a2-0131-4a42-0050569601ca-d 64d32c10-97b4-0138-7304-02d0d7bfd6e4-9 887c5ae0-97bc-0138-7304-02d0d7bfd6e4-4 64706780-d481-0131-267f-0050569601ca-7 e729dbb0-3cbf-0139-769d-02d0d7bfd6e4-6 f3d2f800-3cae-0139-769d-02d0d7bfd6e4-3 7aa5c1c0-d9f9-0135-4ad6-0050569601ca-5 3075c7f0-cddd-0138-7406-02d0d7bfd6e4-e 13641e60-abb7-0131-4a44-0050569601ca-3 bf9ad9d0-ec95-0138-74f1-02d0d7bfd6e4-6 a2998620-f252-0139-7a6d-02d0d7bfd6e4-a 94e92120-d3d0-0131-267f-0050569601ca-f 9c1f90d0-abb7-0131-4a44-0050569601ca-4 78905e80-42b0-0133-a7f6-0050569601ca-6 c58a4b40-4f28-0137-6c9b-02d0d7bfd6e4-1 34d204d0-05d1-0130-c5bb-0019b9e633c5-e 07535160-475d-0132-332d-0050569601ca-b f90ae330-3575-0133-a7f3-0050569601ca-e 018d06c0-36c3-0137-6c0e-02d0d7bfd6e4-e 438df210-9a45-0134-20c7-0050569601ca-c a8d65120-34b0-0133-a7ec-0050569601ca-5 3fa03bd0-b331-0133-1d05-0050569601ca-8 8838a520-2b19-0132-3314-0050569601ca-7 b69f8320-4ab9-0134-1da6-0050569601ca-d ca9796b0-2f19-0133-a7e0-0050569601ca-4 5ad6e230-d740-0137-6fb5-02d0d7bfd6e4-7 7ae174d0-7618-0139-77de-02d0d7bfd6e4-7 1af3abe0-e723-0138-74c1-02d0d7bfd6e4-a 3d847e50-bddf-0137-6ef9-02d0d7bfd6e4-a 42b16220-b62c-0137-6e78-02d0d7bfd6e4-a ce364100-9128-013b-44b6-02d0d7bfd6e4-0 53985780-7622-0139-77de-02d0d7bfd6e4-b ca0812e0-7a71-013b-43ff-02d0d7bfd6e4-d b49c6c00-34a9-0133-a7ec-0050569601ca-c 3fcbf740-f469-0138-7528-02d0d7bfd6e4-b 99ff22a0-c017-0136-52ca-0050569601ca-2 cb26f8a0-7400-013b-43d4-02d0d7bfd6e4-6 c914a1b0-4cc8-0137-6c8d-02d0d7bfd6e4-d f8c35610-5900-0139-7746-02d0d7bfd6e4-2 a1da12f0-c5b3-0134-237b-0050569601ca-6 e3602520-912c-013b-44b6-02d0d7bfd6e4-e 115a3b90-3534-0132-331e-0050569601ca-a 7504abe0-e17f-0138-7493-02d0d7bfd6e4-9 ad220080-6594-0139-779d-02d0d7bfd6e4-6 0a8c7970-a6da-0131-4a42-0050569601ca-b c9c0e720-6dec-0138-7298-02d0d7bfd6e4-f 5b0bb380-6df0-0138-7298-02d0d7bfd6e4-4 36e2f640-ac93-0131-4a44-0050569601ca-4 1c2866c0-cb8e-0138-73f5-02d0d7bfd6e4-c ff462820-2709-0137-6ba6-02d0d7bfd6e4-f 3de72b50-efb1-0138-7509-02d0d7bfd6e4-f ca947e30-3b87-0132-3325-0050569601ca-b ae27c1f0-aaee-013a-c3a0-02d0d7bfd6e4-7 67e8d080-7621-0139-77de-02d0d7bfd6e4-5 9fd03cd0-a157-0131-4a3f-0050569601ca-3 5cda26a0-a6fd-0131-4a42-0050569601ca-2 d4c24d00-e5be-013a-c613-02d0d7bfd6e4-e dcb0d580-b0a7-0137-6e46-02d0d7bfd6e4-2 8ef0b960-0668-0130-c5bb-0019b9e633c5-d e3de7000-ac89-0131-4a44-0050569601ca-3 4c5b8da0-a874-013a-c38e-02d0d7bfd6e4-a 2a99ff50-a613-0134-2339-0050569601ca-4 e93ae280-35ca-0136-4e19-0050569601ca-b d1fade30-1730-0135-242b-0050569601ca-e a5c3b4a0-f46b-0138-7528-02d0d7bfd6e4-a a5c3b4a0-f46b-0138-7528-02d0d7bfd6e4-a d36dc440-f465-0138-7531-02d0d7bfd6e4-c 8495e120-912b-013b-44b6-02d0d7bfd6e4-3 1d7da8f0-bdea-0137-6ef9-02d0d7bfd6e4-2 85f90710-a6e2-0131-4a42-0050569601ca-f 44cef6f0-c5b6-0134-237b-0050569601ca-3 80ceb570-9fcf-0139-7898-02d0d7bfd6e4-1 53e2b6e0-af03-0132-fd68-0050569601ca-7 54585fd0-ac81-0131-4a44-0050569601ca-5 259e2e70-3ed0-0138-717e-02d0d7bfd6e4-3 3632d3b0-a6f5-0131-4a42-0050569601ca-7 9c1b1540-9c04-0131-4a32-0050569601ca-8 9a910b40-270b-0137-6ba8-02d0d7bfd6e4-5 3fb3ccb0-3cd4-0139-769d-02d0d7bfd6e4-8 3f51f780-a0a4-0131-4a3f-0050569601ca-6 75949a80-bdb9-013a-c452-02d0d7bfd6e4-8 0c1f26b0-36c2-0137-6c0e-02d0d7bfd6e4-b 87fa16d0-9790-0138-7302-02d0d7bfd6e4-0 994d6a50-3b88-0132-3325-0050569601ca-6 de244f40-eff9-013a-c632-02d0d7bfd6e4-8 de244f40-eff9-013a-c632-02d0d7bfd6e4-8 3247cfa0-2630-0136-4d8c-0050569601ca-2 759e1cd0-9498-0138-72f9-02d0d7bfd6e4-f c56d9590-bdf2-0137-6ef9-02d0d7bfd6e4-7 25dbe080-ad9b-0137-6e3d-02d0d7bfd6e4-c cad6b590-6722-0134-1de2-0050569601ca-5 28fb2520-2631-0136-4d8c-0050569601ca-7 a84d7f60-88ec-0139-7830-02d0d7bfd6e4-2 b0d79040-3cb0-0139-769d-02d0d7bfd6e4-2 396fed80-e5b8-013a-c613-02d0d7bfd6e4-2 887d6010-3cb8-0139-769d-02d0d7bfd6e4-2 8e4bd350-5d1b-013a-c232-02d0d7bfd6e4-a c5fe8d80-ac92-0131-4a44-0050569601ca-9 1e6b81c0-a0a0-0131-4a3f-0050569601ca-b d0cb0ae0-cb9a-0138-73f5-02d0d7bfd6e4-b 181ccf50-7262-013b-43c1-02d0d7bfd6e4-6 e2fa2940-aee0-0131-4a46-0050569601ca-e f9dfeda0-c91b-0138-73e5-02d0d7bfd6e4-8 ea8866c0-2637-013a-7bf1-02d0d7bfd6e4-9 7bfaf980-0727-0130-c5bb-0019b9e633c5-e cc662490-3b8b-0132-3325-0050569601ca-1 cc662490-3b8b-0132-3325-0050569601ca-1 3f626c80-e1bb-0139-7a1b-02d0d7bfd6e4-a 6158e730-646e-0133-a820-0050569601ca-c f46121d0-3acd-0132-3324-0050569601ca-7 8d54edb0-a4ec-0132-fd59-0050569601ca-a f722e3a0-3b8a-0132-3325-0050569601ca-c cd0dbc30-c925-0138-73ea-02d0d7bfd6e4-1 f66dc380-42b9-0133-a7f6-0050569601ca-8 0218e8d0-efb4-0138-7509-02d0d7bfd6e4-f b2423a60-f001-013a-c632-02d0d7bfd6e4-c c1e17230-f9d9-0138-7560-02d0d7bfd6e4-0 2beaea30-4b0d-0136-4f6d-0050569601ca-5 a5ec5380-4b07-0136-4f6d-0050569601ca-6 b06388f0-918a-0139-7860-02d0d7bfd6e4-e 04a92f70-5b85-0135-3578-0050569601ca-3 4e686a00-d3b4-0131-267f-0050569601ca-e 4e686a00-d3b4-0131-267f-0050569601ca-e d8e12160-a0a3-0131-4a3f-0050569601ca-e 3ceb7850-a156-0131-4a3f-0050569601ca-5 2b94b480-3228-0132-331a-0050569601ca-b 4a1839b0-a08d-0131-4a3f-0050569601ca-7 0171fa40-7b94-0139-7802-02d0d7bfd6e4-5 b48376e0-af8f-0136-528d-0050569601ca-3 a2771d00-7262-013b-43c1-02d0d7bfd6e4-3 16dd95e0-3b8c-0132-3325-0050569601ca-3 4e793f60-ac8b-0131-4a44-0050569601ca-1 55aa1f60-1d9a-0137-6b83-02d0d7bfd6e4-f c3b86ba0-946b-0138-72f5-02d0d7bfd6e4-e ca7bda10-6ac0-0137-6d02-02d0d7bfd6e4-a 427d71a0-9da5-0131-4a3e-0050569601ca-d 01cfde80-be04-0137-6f0a-02d0d7bfd6e4-f 69253c10-95a7-0131-1105-0050569601ca-1 5ebd8db0-7e8b-0134-1ea4-0050569601ca-c 981231c0-ac67-0131-4a44-0050569601ca-f 9558c460-d73a-0137-6fb5-02d0d7bfd6e4-8 81b277f0-e93a-0133-1d3c-0050569601ca-9 5a7e77c0-98be-0131-1105-0050569601ca-d 9d781b10-6149-0132-333b-0050569601ca-2 8e2d3b60-a83d-0133-1cf9-0050569601ca-0 0a9ee620-f250-0139-7a6d-02d0d7bfd6e4-7 7952e790-9e58-0131-4a3e-0050569601ca-e db741d40-bb2d-0139-7937-02d0d7bfd6e4-6 0eb19e60-11fc-0133-a7ce-0050569601ca-5 1250c620-97b3-0138-7304-02d0d7bfd6e4-4 f56efda0-a543-0139-78b3-02d0d7bfd6e4-c 2ec23de0-efb9-0138-7509-02d0d7bfd6e4-b aa9ebb40-d135-0139-79d5-02d0d7bfd6e4-b 49755900-262f-0136-4d8f-0050569601ca-c 9c3d5d20-3cb1-0139-769d-02d0d7bfd6e4-1 aa9ebb40-d135-0139-79d5-02d0d7bfd6e4-b c1294130-3549-0133-a7ec-0050569601ca-8 fd5d4a20-a156-0131-4a3f-0050569601ca-e cfa6e5a0-3d21-0133-a7f6-0050569601ca-f 31b6d1d0-8050-0135-01ae-0050569601ca-5 39a50b00-3447-013a-7c48-02d0d7bfd6e4-e 26217450-a185-0131-4a3f-0050569601ca-c 9ff98a90-e4e4-0135-4b25-0050569601ca-0 65e1de80-a6fe-0131-4a42-0050569601ca-6 9acfac40-a70d-0131-4a42-0050569601ca-7 e996a760-9eca-0134-2329-0050569601ca-d 9b410620-d3cc-0131-267f-0050569601ca-b 92f21fe0-97a1-0138-7304-02d0d7bfd6e4-f a6d769d0-317f-0138-714f-02d0d7bfd6e4-7 7456c940-a892-013a-c38e-02d0d7bfd6e4-f 8b11e130-9cc0-0136-5226-0050569601ca-7 068bceb0-aee2-0131-4a46-0050569601ca-a 3b157350-c5b4-0134-237b-0050569601ca-f 24243800-219a-013b-c7cf-02d0d7bfd6e4-0 0c4c6820-d72f-0137-6fb5-02d0d7bfd6e4-3 24135980-ba13-0132-17ed-0050569601ca-9 f5ffae60-3b63-0132-3325-0050569601ca-a daef1280-9731-0131-1105-0050569601ca-6 11913760-a08f-0131-4a3f-0050569601ca-a c6de5e50-608e-0138-7261-02d0d7bfd6e4-e 721d9f50-cb86-0138-73f5-02d0d7bfd6e4-4 f17ac9b0-d739-0137-6fb5-02d0d7bfd6e4-6 bb181dc0-e62d-012f-c5b7-0019b9e633c5-0 4fe01460-e960-0138-74c9-02d0d7bfd6e4-0 98c7e3d0-912a-013b-44b9-02d0d7bfd6e4-e 5032fd00-8c38-013a-c2f1-02d0d7bfd6e4-5 48a25b20-df31-0134-23b3-0050569601ca-a])
      puts collections.map{ |c| "#{c.repository_id}  #{c.title}" }.join("\n")
    end

    desc "Export borked collections to TSV"
    task :export_borked => :environment do
      Dir.mktmpdir do |tmpdir|
        # Write each collection's TSV to a separate file within the temp
        # directory.
        collections = Collection.where(repository_id: %w[eb857cd0-2f31-0133-a7e0-0050569601ca-7 ddaad430-1d95-0137-6b83-02d0d7bfd6e4-f 4dbfbe30-d29c-0133-1d21-0050569601ca-0 ac5aca50-e635-0138-74a4-02d0d7bfd6e4-a e663a020-353d-0133-a7ec-0050569601ca-b b1659f20-5103-0134-1dbe-0050569601ca-d 87e36180-aaf0-013a-c3a0-02d0d7bfd6e4-d 4dc64260-c7d3-0135-4aa0-0050569601ca-e 94dc3370-ecd3-0139-7a60-02d0d7bfd6e4-0 5d342ab0-eccc-0139-7a60-02d0d7bfd6e4-8 ddaad430-1d95-0137-6b83-02d0d7bfd6e4-f f7d09f70-f003-013a-c632-02d0d7bfd6e4-4 32eeb600-0081-0136-4c0b-0050569601ca-a de294740-a17f-0131-4a3f-0050569601ca-9 e4141ba0-bd17-0137-6ee6-02d0d7bfd6e4-5 63a302f0-15de-0132-f530-0050569601ca-9 e70510c0-e73c-0139-7a45-02d0d7bfd6e4-e 942a7970-5262-0137-6cad-02d0d7bfd6e4-8 cad6b590-6722-0134-1de2-0050569601ca-5 3af03940-b6bb-0135-49e7-0050569601ca-6 69f64850-8d97-0134-200b-0050569601ca-4 3d687ae0-e227-0132-182a-0050569601ca-f 1d989110-3cc1-0139-769d-02d0d7bfd6e4-0 3a9a00c0-1d99-0137-6b83-02d0d7bfd6e4-3 78a65140-e4e7-0135-4b25-0050569601ca-1 8f013ff0-dec5-013a-c5c0-02d0d7bfd6e4-5 5a7e77c0-98be-0131-1105-0050569601ca-d 309d0840-e21e-0132-182a-0050569601ca-4 36e1e030-c5b7-0134-237b-0050569601ca-0 e0c73760-e456-013a-c606-02d0d7bfd6e4-7 43108a60-9471-0138-72f9-02d0d7bfd6e4-0 bb53d620-d726-0137-6fb5-02d0d7bfd6e4-d 38ec6eb0-18c3-0135-242c-0050569601ca-1 5b0bb380-6df0-0138-7298-02d0d7bfd6e4-4 25dbe080-ad9b-0137-6e3d-02d0d7bfd6e4-c b2423a60-f001-013a-c632-02d0d7bfd6e4-c 2beaea30-4b0d-0136-4f6d-0050569601ca-5 0975a980-efe4-0131-d9cb-0050569601ca-c ffdd8730-218a-013b-c7cf-02d0d7bfd6e4-a 712d65c0-2c60-0136-4dae-0050569601ca-8 0f7a8470-1c10-0137-6b79-02d0d7bfd6e4-4 cdc57b70-9b1e-0131-1105-0050569601ca-e 098beeb0-42fb-0139-76ce-02d0d7bfd6e4-1 0189ac20-2189-013b-c7cf-02d0d7bfd6e4-9 1151e180-79b5-0137-6d43-02d0d7bfd6e4-c da1aaa60-0a9a-0136-4c9b-0050569601ca-4 3f8823a0-bded-0137-6ef9-02d0d7bfd6e4-7 1aab1d90-e05e-0136-5352-0050569601ca-1 b14d0060-3ac5-0132-3324-0050569601ca-6 420cd180-979c-0138-7304-02d0d7bfd6e4-f bb6e7500-6090-0138-7261-02d0d7bfd6e4-d b9f2d780-f464-0138-7528-02d0d7bfd6e4-8 be1c1d10-c853-0138-73db-02d0d7bfd6e4-d 1038ade0-6df6-0138-7298-02d0d7bfd6e4-c 9e579560-1e41-013a-7baf-02d0d7bfd6e4-4 b1512df0-13f8-013a-7b57-02d0d7bfd6e4-9 97705f60-7c56-0134-1e98-0050569601ca-4 4106bc40-bdf3-0137-6f04-02d0d7bfd6e4-6 c5babd80-a24d-0131-4a3f-0050569601ca-f edaca8a0-f004-013a-c632-02d0d7bfd6e4-a fb30d7d0-58e0-0134-1dc8-0050569601ca-7 0e381890-caf0-0134-2382-0050569601ca-5 3fadba30-571c-0138-7234-02d0d7bfd6e4-8 8a02d470-9299-0131-1105-0050569601ca-8 77915810-608a-0138-7261-02d0d7bfd6e4-8 aca344d0-1f7d-0138-70d2-02d0d7bfd6e4-f 9789e640-a0a0-0131-4a3f-0050569601ca-c b6321bd0-1338-013a-7b4e-02d0d7bfd6e4-4 97fd70a0-3b64-0132-3325-0050569601ca-a 4243aa30-2bb6-013a-7c18-02d0d7bfd6e4-b 01eb6f70-912a-013b-44b6-02d0d7bfd6e4-7 07367e40-c719-0139-7993-02d0d7bfd6e4-7 f00244a0-a7be-0131-4a42-0050569601ca-1 7edcc720-7fa2-0131-1102-0050569601ca-a d2b4f700-ad4f-0131-4a45-0050569601ca-b 6cd79a00-e44f-013a-c5fa-02d0d7bfd6e4-6 8d420900-c5b7-0134-237b-0050569601ca-2 43108a60-9471-0138-72f9-02d0d7bfd6e4-0 d753f420-a248-0131-4a3f-0050569601ca-e bb53d620-d726-0137-6fb5-02d0d7bfd6e4-d cd535a80-4852-0133-a7fd-0050569601ca-3 ec6fb9f0-718a-0136-5120-0050569601ca-9 d8b4eb70-4000-013a-7c8c-02d0d7bfd6e4-f 8e81a5e0-371d-0138-7161-02d0d7bfd6e4-6 313dc3a0-98e3-0131-1105-0050569601ca-1 5d7df610-c939-0138-73e5-02d0d7bfd6e4-d 17681000-f2b5-0138-7521-02d0d7bfd6e4-1 7ccd1cd0-f2f8-0139-7a76-02d0d7bfd6e4-3 cbaca0b0-2ad2-013b-c827-02d0d7bfd6e4-f ea63df90-912b-013b-44b6-02d0d7bfd6e4-4 590c3b10-97bd-0138-7304-02d0d7bfd6e4-7 2b25dab0-c135-0133-1d0f-0050569601ca-f 11aada80-b128-0131-4a46-0050569601ca-6 e72a6f50-e174-0138-7491-02d0d7bfd6e4-f 9b5d80d0-9473-0138-72f9-02d0d7bfd6e4-5 61586270-10a6-0138-70a3-02d0d7bfd6e4-8 7b8b24a0-f468-0138-7528-02d0d7bfd6e4-2 3f743710-af42-0138-7361-02d0d7bfd6e4-c 3c95cb00-906a-0132-fd37-0050569601ca-8 8b820bc0-9733-0131-1105-0050569601ca-0 e65c44b0-5248-0137-6cad-02d0d7bfd6e4-7 ce7942e0-36c5-0137-6c0e-02d0d7bfd6e4-e 4db796f0-3b65-0132-3325-0050569601ca-e 8dfd2160-ad91-0138-7357-02d0d7bfd6e4-e 43f0c070-317e-0138-714f-02d0d7bfd6e4-4 2fe8b300-3533-0132-331e-0050569601ca-b c1083450-3570-0133-a7f3-0050569601ca-7 55451950-793e-0135-0163-0050569601ca-5 103d52d0-7f28-0137-6d60-02d0d7bfd6e4-3 3d044cd0-ffe1-013a-c696-02d0d7bfd6e4-6 03644430-d73e-0137-6fb5-02d0d7bfd6e4-0 6049b8c0-f46d-0138-7528-02d0d7bfd6e4-4 3e4b7f10-3543-0133-a7ec-0050569601ca-f dd4dc6e0-c5b7-0134-237b-0050569601ca-3 2a554be0-ffdf-013a-c696-02d0d7bfd6e4-b 1eaa5260-5d05-013a-c231-02d0d7bfd6e4-6 a58511f0-6148-0132-333a-0050569601ca-3 ed931980-a87e-0131-4a42-0050569601ca-7 b5b9c910-ecbe-0139-7a60-02d0d7bfd6e4-f 14d5e390-f472-0138-7528-02d0d7bfd6e4-2 9dbfd350-a156-0131-4a3f-0050569601ca-d 9c3332f0-7b8a-0139-7802-02d0d7bfd6e4-b b846a650-cff7-0132-180b-0050569601ca-1 7a2b6350-298d-0138-7106-02d0d7bfd6e4-2 52603890-9737-0131-1105-0050569601ca-a 8ec7a2a0-a0a1-0131-4a3f-0050569601ca-3 c2a52750-f463-0138-7528-02d0d7bfd6e4-5 97905640-97ae-0138-7304-02d0d7bfd6e4-d f81928e0-2bb3-013a-7c18-02d0d7bfd6e4-0 07264bb0-9b2b-0131-1105-0050569601ca-3 629ca700-3b8a-0132-3325-0050569601ca-9 593ea720-7dc3-0134-1e9d-0050569601ca-d 79742770-a24b-0131-4a3f-0050569601ca-7 85c5efe0-bda4-0131-4a4b-0050569601ca-c aa18f550-4808-0137-6c7d-02d0d7bfd6e4-2 22270f00-9793-0138-7302-02d0d7bfd6e4-9 6e640b10-3b66-0132-3325-0050569601ca-f 0bd577a0-ae24-0131-4a45-0050569601ca-6 91ee58d0-15c6-0132-f530-0050569601ca-1 974c9b30-9062-0132-fd37-0050569601ca-4 e75c4a30-8ee7-0138-72e0-02d0d7bfd6e4-5 b866b880-cb81-0138-73f5-02d0d7bfd6e4-0 964d47e0-6d72-0139-77b0-02d0d7bfd6e4-3 ec7eff60-a7d4-0131-4a42-0050569601ca-e 91ac1250-ad9c-0137-6e3d-02d0d7bfd6e4-8 4fef9a30-a157-0131-4a3f-0050569601ca-0 58d60350-0cfc-013b-c725-02d0d7bfd6e4-e 11b19110-c018-0136-52ca-0050569601ca-d 58b5a7b0-a7d5-0131-4a42-0050569601ca-d c9b58580-c5b5-0134-237b-0050569601ca-6 f844fd60-3b66-0132-3325-0050569601ca-c 00180630-f2c9-0138-7521-02d0d7bfd6e4-d 3913b250-3551-0133-a7f0-0050569601ca-b f8871290-3b89-0132-3325-0050569601ca-b aeda0ed0-c5b6-0134-237b-0050569601ca-f d85d1900-b0ba-0137-6e46-02d0d7bfd6e4-8 6c399aa0-cff7-0132-180b-0050569601ca-b e4634110-97b9-0138-7304-02d0d7bfd6e4-2 99e1b490-bdea-0137-6ef9-02d0d7bfd6e4-2 3cfde400-a87d-0131-4a42-0050569601ca-1 a4902620-f80e-0137-7066-02d0d7bfd6e4-7 6e75f750-9739-0131-1105-0050569601ca-b 8350bab0-c527-0138-73cf-02d0d7bfd6e4-9 8f4d53b0-ef99-0138-7501-02d0d7bfd6e4-d 8a8e23e0-a253-0131-4a3f-0050569601ca-f ac541610-a0a4-0131-4a3f-0050569601ca-6 95fe1290-7620-0139-77de-02d0d7bfd6e4-2 bbcd8640-9727-0131-1105-0050569601ca-6 1c3a59a0-9e57-0131-4a3e-0050569601ca-5 d6ebf930-abb8-0131-4a44-0050569601ca-6 ee2609a0-270a-0137-6ba6-02d0d7bfd6e4-a bfac8630-e17a-0138-7493-02d0d7bfd6e4-7 12647930-d482-0131-267f-0050569601ca-6 e6b046c0-cde5-0138-7406-02d0d7bfd6e4-a 7909da60-b89b-0137-6ea6-02d0d7bfd6e4-e af8b4410-a870-013a-c38e-02d0d7bfd6e4-3 55fc9980-912c-013b-44b6-02d0d7bfd6e4-b 54435270-9036-013b-44a7-02d0d7bfd6e4-c 1fa085b0-3b89-0132-3325-0050569601ca-8 595fb2c0-a7a2-0131-4a42-0050569601ca-d 64d32c10-97b4-0138-7304-02d0d7bfd6e4-9 887c5ae0-97bc-0138-7304-02d0d7bfd6e4-4 64706780-d481-0131-267f-0050569601ca-7 e729dbb0-3cbf-0139-769d-02d0d7bfd6e4-6 f3d2f800-3cae-0139-769d-02d0d7bfd6e4-3 7aa5c1c0-d9f9-0135-4ad6-0050569601ca-5 3075c7f0-cddd-0138-7406-02d0d7bfd6e4-e 13641e60-abb7-0131-4a44-0050569601ca-3 bf9ad9d0-ec95-0138-74f1-02d0d7bfd6e4-6 a2998620-f252-0139-7a6d-02d0d7bfd6e4-a 94e92120-d3d0-0131-267f-0050569601ca-f 9c1f90d0-abb7-0131-4a44-0050569601ca-4 78905e80-42b0-0133-a7f6-0050569601ca-6 c58a4b40-4f28-0137-6c9b-02d0d7bfd6e4-1 34d204d0-05d1-0130-c5bb-0019b9e633c5-e 07535160-475d-0132-332d-0050569601ca-b f90ae330-3575-0133-a7f3-0050569601ca-e 018d06c0-36c3-0137-6c0e-02d0d7bfd6e4-e 438df210-9a45-0134-20c7-0050569601ca-c a8d65120-34b0-0133-a7ec-0050569601ca-5 3fa03bd0-b331-0133-1d05-0050569601ca-8 8838a520-2b19-0132-3314-0050569601ca-7 b69f8320-4ab9-0134-1da6-0050569601ca-d ca9796b0-2f19-0133-a7e0-0050569601ca-4 5ad6e230-d740-0137-6fb5-02d0d7bfd6e4-7 7ae174d0-7618-0139-77de-02d0d7bfd6e4-7 1af3abe0-e723-0138-74c1-02d0d7bfd6e4-a 3d847e50-bddf-0137-6ef9-02d0d7bfd6e4-a 42b16220-b62c-0137-6e78-02d0d7bfd6e4-a ce364100-9128-013b-44b6-02d0d7bfd6e4-0 53985780-7622-0139-77de-02d0d7bfd6e4-b ca0812e0-7a71-013b-43ff-02d0d7bfd6e4-d b49c6c00-34a9-0133-a7ec-0050569601ca-c 3fcbf740-f469-0138-7528-02d0d7bfd6e4-b 99ff22a0-c017-0136-52ca-0050569601ca-2 cb26f8a0-7400-013b-43d4-02d0d7bfd6e4-6 c914a1b0-4cc8-0137-6c8d-02d0d7bfd6e4-d f8c35610-5900-0139-7746-02d0d7bfd6e4-2 a1da12f0-c5b3-0134-237b-0050569601ca-6 e3602520-912c-013b-44b6-02d0d7bfd6e4-e 115a3b90-3534-0132-331e-0050569601ca-a 7504abe0-e17f-0138-7493-02d0d7bfd6e4-9 ad220080-6594-0139-779d-02d0d7bfd6e4-6 0a8c7970-a6da-0131-4a42-0050569601ca-b c9c0e720-6dec-0138-7298-02d0d7bfd6e4-f 5b0bb380-6df0-0138-7298-02d0d7bfd6e4-4 36e2f640-ac93-0131-4a44-0050569601ca-4 1c2866c0-cb8e-0138-73f5-02d0d7bfd6e4-c ff462820-2709-0137-6ba6-02d0d7bfd6e4-f 3de72b50-efb1-0138-7509-02d0d7bfd6e4-f ca947e30-3b87-0132-3325-0050569601ca-b ae27c1f0-aaee-013a-c3a0-02d0d7bfd6e4-7 67e8d080-7621-0139-77de-02d0d7bfd6e4-5 9fd03cd0-a157-0131-4a3f-0050569601ca-3 5cda26a0-a6fd-0131-4a42-0050569601ca-2 d4c24d00-e5be-013a-c613-02d0d7bfd6e4-e dcb0d580-b0a7-0137-6e46-02d0d7bfd6e4-2 8ef0b960-0668-0130-c5bb-0019b9e633c5-d e3de7000-ac89-0131-4a44-0050569601ca-3 4c5b8da0-a874-013a-c38e-02d0d7bfd6e4-a 2a99ff50-a613-0134-2339-0050569601ca-4 e93ae280-35ca-0136-4e19-0050569601ca-b d1fade30-1730-0135-242b-0050569601ca-e a5c3b4a0-f46b-0138-7528-02d0d7bfd6e4-a a5c3b4a0-f46b-0138-7528-02d0d7bfd6e4-a d36dc440-f465-0138-7531-02d0d7bfd6e4-c 8495e120-912b-013b-44b6-02d0d7bfd6e4-3 1d7da8f0-bdea-0137-6ef9-02d0d7bfd6e4-2 85f90710-a6e2-0131-4a42-0050569601ca-f 44cef6f0-c5b6-0134-237b-0050569601ca-3 80ceb570-9fcf-0139-7898-02d0d7bfd6e4-1 53e2b6e0-af03-0132-fd68-0050569601ca-7 54585fd0-ac81-0131-4a44-0050569601ca-5 259e2e70-3ed0-0138-717e-02d0d7bfd6e4-3 3632d3b0-a6f5-0131-4a42-0050569601ca-7 9c1b1540-9c04-0131-4a32-0050569601ca-8 9a910b40-270b-0137-6ba8-02d0d7bfd6e4-5 3fb3ccb0-3cd4-0139-769d-02d0d7bfd6e4-8 3f51f780-a0a4-0131-4a3f-0050569601ca-6 75949a80-bdb9-013a-c452-02d0d7bfd6e4-8 0c1f26b0-36c2-0137-6c0e-02d0d7bfd6e4-b 87fa16d0-9790-0138-7302-02d0d7bfd6e4-0 994d6a50-3b88-0132-3325-0050569601ca-6 de244f40-eff9-013a-c632-02d0d7bfd6e4-8 de244f40-eff9-013a-c632-02d0d7bfd6e4-8 3247cfa0-2630-0136-4d8c-0050569601ca-2 759e1cd0-9498-0138-72f9-02d0d7bfd6e4-f c56d9590-bdf2-0137-6ef9-02d0d7bfd6e4-7 25dbe080-ad9b-0137-6e3d-02d0d7bfd6e4-c cad6b590-6722-0134-1de2-0050569601ca-5 28fb2520-2631-0136-4d8c-0050569601ca-7 a84d7f60-88ec-0139-7830-02d0d7bfd6e4-2 b0d79040-3cb0-0139-769d-02d0d7bfd6e4-2 396fed80-e5b8-013a-c613-02d0d7bfd6e4-2 887d6010-3cb8-0139-769d-02d0d7bfd6e4-2 8e4bd350-5d1b-013a-c232-02d0d7bfd6e4-a c5fe8d80-ac92-0131-4a44-0050569601ca-9 1e6b81c0-a0a0-0131-4a3f-0050569601ca-b d0cb0ae0-cb9a-0138-73f5-02d0d7bfd6e4-b 181ccf50-7262-013b-43c1-02d0d7bfd6e4-6 e2fa2940-aee0-0131-4a46-0050569601ca-e f9dfeda0-c91b-0138-73e5-02d0d7bfd6e4-8 ea8866c0-2637-013a-7bf1-02d0d7bfd6e4-9 7bfaf980-0727-0130-c5bb-0019b9e633c5-e cc662490-3b8b-0132-3325-0050569601ca-1 cc662490-3b8b-0132-3325-0050569601ca-1 3f626c80-e1bb-0139-7a1b-02d0d7bfd6e4-a 6158e730-646e-0133-a820-0050569601ca-c f46121d0-3acd-0132-3324-0050569601ca-7 8d54edb0-a4ec-0132-fd59-0050569601ca-a f722e3a0-3b8a-0132-3325-0050569601ca-c cd0dbc30-c925-0138-73ea-02d0d7bfd6e4-1 f66dc380-42b9-0133-a7f6-0050569601ca-8 0218e8d0-efb4-0138-7509-02d0d7bfd6e4-f b2423a60-f001-013a-c632-02d0d7bfd6e4-c c1e17230-f9d9-0138-7560-02d0d7bfd6e4-0 2beaea30-4b0d-0136-4f6d-0050569601ca-5 a5ec5380-4b07-0136-4f6d-0050569601ca-6 b06388f0-918a-0139-7860-02d0d7bfd6e4-e 04a92f70-5b85-0135-3578-0050569601ca-3 4e686a00-d3b4-0131-267f-0050569601ca-e 4e686a00-d3b4-0131-267f-0050569601ca-e d8e12160-a0a3-0131-4a3f-0050569601ca-e 3ceb7850-a156-0131-4a3f-0050569601ca-5 2b94b480-3228-0132-331a-0050569601ca-b 4a1839b0-a08d-0131-4a3f-0050569601ca-7 0171fa40-7b94-0139-7802-02d0d7bfd6e4-5 b48376e0-af8f-0136-528d-0050569601ca-3 a2771d00-7262-013b-43c1-02d0d7bfd6e4-3 16dd95e0-3b8c-0132-3325-0050569601ca-3 4e793f60-ac8b-0131-4a44-0050569601ca-1 55aa1f60-1d9a-0137-6b83-02d0d7bfd6e4-f c3b86ba0-946b-0138-72f5-02d0d7bfd6e4-e ca7bda10-6ac0-0137-6d02-02d0d7bfd6e4-a 427d71a0-9da5-0131-4a3e-0050569601ca-d 01cfde80-be04-0137-6f0a-02d0d7bfd6e4-f 69253c10-95a7-0131-1105-0050569601ca-1 5ebd8db0-7e8b-0134-1ea4-0050569601ca-c 981231c0-ac67-0131-4a44-0050569601ca-f 9558c460-d73a-0137-6fb5-02d0d7bfd6e4-8 81b277f0-e93a-0133-1d3c-0050569601ca-9 5a7e77c0-98be-0131-1105-0050569601ca-d 9d781b10-6149-0132-333b-0050569601ca-2 8e2d3b60-a83d-0133-1cf9-0050569601ca-0 0a9ee620-f250-0139-7a6d-02d0d7bfd6e4-7 7952e790-9e58-0131-4a3e-0050569601ca-e db741d40-bb2d-0139-7937-02d0d7bfd6e4-6 0eb19e60-11fc-0133-a7ce-0050569601ca-5 1250c620-97b3-0138-7304-02d0d7bfd6e4-4 f56efda0-a543-0139-78b3-02d0d7bfd6e4-c 2ec23de0-efb9-0138-7509-02d0d7bfd6e4-b aa9ebb40-d135-0139-79d5-02d0d7bfd6e4-b 49755900-262f-0136-4d8f-0050569601ca-c 9c3d5d20-3cb1-0139-769d-02d0d7bfd6e4-1 aa9ebb40-d135-0139-79d5-02d0d7bfd6e4-b c1294130-3549-0133-a7ec-0050569601ca-8 fd5d4a20-a156-0131-4a3f-0050569601ca-e cfa6e5a0-3d21-0133-a7f6-0050569601ca-f 31b6d1d0-8050-0135-01ae-0050569601ca-5 39a50b00-3447-013a-7c48-02d0d7bfd6e4-e 26217450-a185-0131-4a3f-0050569601ca-c 9ff98a90-e4e4-0135-4b25-0050569601ca-0 65e1de80-a6fe-0131-4a42-0050569601ca-6 9acfac40-a70d-0131-4a42-0050569601ca-7 e996a760-9eca-0134-2329-0050569601ca-d 9b410620-d3cc-0131-267f-0050569601ca-b 92f21fe0-97a1-0138-7304-02d0d7bfd6e4-f a6d769d0-317f-0138-714f-02d0d7bfd6e4-7 7456c940-a892-013a-c38e-02d0d7bfd6e4-f 8b11e130-9cc0-0136-5226-0050569601ca-7 068bceb0-aee2-0131-4a46-0050569601ca-a 3b157350-c5b4-0134-237b-0050569601ca-f 24243800-219a-013b-c7cf-02d0d7bfd6e4-0 0c4c6820-d72f-0137-6fb5-02d0d7bfd6e4-3 24135980-ba13-0132-17ed-0050569601ca-9 f5ffae60-3b63-0132-3325-0050569601ca-a daef1280-9731-0131-1105-0050569601ca-6 11913760-a08f-0131-4a3f-0050569601ca-a c6de5e50-608e-0138-7261-02d0d7bfd6e4-e 721d9f50-cb86-0138-73f5-02d0d7bfd6e4-4 f17ac9b0-d739-0137-6fb5-02d0d7bfd6e4-6 bb181dc0-e62d-012f-c5b7-0019b9e633c5-0 4fe01460-e960-0138-74c9-02d0d7bfd6e4-0 98c7e3d0-912a-013b-44b9-02d0d7bfd6e4-e 5032fd00-8c38-013a-c2f1-02d0d7bfd6e4-5 48a25b20-df31-0134-23b3-0050569601ca-a])
        collections.each_with_index do |col, index|
          tsv_filename = "#{col.repository_id}.tsv"
          tsv_pathname = File.join(tmpdir, tsv_filename)
          File.open(tsv_pathname, 'w') do |file|
            file.write(ItemTsvExporter.new.items_in_collection(col))
          end
          puts index
        end

        # Create the zip file within the temp directory.
        zip_filename = "borked_collections_tsv-#{Time.now.to_formatted_s(:number)}.zip"
        zip_pathname = File.join(tmpdir, zip_filename)

        # -j: don't record directory names
        # -r: recurse into directories
        `zip -jr "#{zip_pathname}" "#{tmpdir}"`

        `cp #{zip_pathname} ~/NoBackup`
      end
    end

    desc "Import borked collections from TSV"
    task :import_borked, [:pathname] => :environment do |task, args|
      pathname = File.expand_path(args[:pathname])
      i = 0
      Dir.glob(pathname + "/*") do |file|
        ActiveRecord::Base.transaction do
          filename = File.basename(file)
          puts "#{i}: #{filename}"
          uuid       = filename.chomp(".tsv")
          collection = Collection.find_by_repository_id(uuid)

          MedusaIngester.new.sync_items(collection, :create_only,
                                        { extract_metadata: false })
          ItemUpdater.new.update_from_tsv(file, File.basename(file))
          i += 1
        end
      end
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

  namespace :downloads do

    desc 'Clean up old downloads'
    task :cleanup => :environment do
      Download.cleanup(60 * 60 * 24) # max 1 day old
    end

    desc 'Expire all downloads'
    task :expire => :environment do
      Download.where(expired: false).each(&:expire)
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

  namespace :jobs do

    desc 'Clear all jobs'
    task :clear => :environment do
      ActiveRecord::Base.connection.execute("DELETE FROM good_jobs;")
    end

    desc 'Run a test job'
    task :test => :environment do
      SleepJob.perform_later(interval: 30)
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
      SleepJob.new(interval: 15).perform_in_foreground
    end

  end

  def reindex_items(index = nil)
    Item.reindex_all(es_index: index)
  end

end
