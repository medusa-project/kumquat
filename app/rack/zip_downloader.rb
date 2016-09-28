##
# Rack application to handle streaming zip downloads.
#
# For the most part, this the same URL query parameters as
# ItemsController.index() are accepted, but cross-collection requests (i.e.
# requests without a collection_id parameter) are not accepted due to the
# huge amount of content they could retrieve. (But, perhaps it would be better
# to limit the total number of items instead.)
#
class ZipDownloader

  BATCH_SIZE = 100

  def call(env)
    params = Rack::Utils.parse_nested_query(env['QUERY_STRING']).symbolize_keys

    if params[:collection_id].blank?
      return [400, {}, 'To spare computing resources, zip file '\
        'generation across collection contexts is disabled.']
    end

    finder = ItemFinder.new.
        client_hostname(env['HTTP_HOST'].split(':').first).
        client_ip(env['REMOTE_ADDR']).
        #client_user(current_user). TODO: fix
        collection_id(params[:collection_id]).
        query(params[:q]).
        facet_queries(params[:fq]).
        include_children(true).
        order(Item::SolrFields::ID).
        start(params[:start]).
        limit(BATCH_SIZE)

    begin
      items = finder.to_a
      if items.length > 0
        instance_id = Random.rand(10000000)
        Rails.logger.info("ZipDownloader-#{instance_id}: "\
            "processing request for: #{finder.to_s.split("\n").join('; ')}")

        body = ZipTricks::RackBody.new do |zip|
          items.each_with_index do |item, index|
            Rails.logger.debug("ZipDownloader-#{instance_id}: "\
                "adding item #{index + 1} of #{items.length} (#{item.repository_id})")

            # Include the item's JSON metadata in the zip.
            json = JSON.pretty_generate(item.decorate(context: { web: false }).as_json)
            json_io = StringIO.new(json)

            crc32 = ZipTricks::StreamCRC32.from_io(json_io)
            json_io.rewind
            filename = "#{item.repository_id}/metadata.json"
            zip.add_stored_entry(filename: filename, size: json_io.size,
                                 crc32: crc32)
            IO.copy_stream(json_io, zip)

            # If the item has an access master bytestream, include it in the
            # zip also.
            bs = item.access_master_bytestream
            if bs
              file = File.open(bs.absolute_local_pathname, 'rb')
              crc32 = ZipTricks::StreamCRC32.from_io(file)
              file.rewind
              filename = "#{item.repository_id}/access#{File.extname(bs.absolute_local_pathname)}"
              begin
                zip.add_stored_entry(filename: filename, size: file.size,
                                     crc32: crc32)
                IO.copy_stream(file, zip)
              ensure
                file.close
              end
            end
          end
        end
        return [200, { 'Content-Disposition': 'attachment; filename=items.zip' }, body]
      else
        return [204, {}, nil]
      end
    rescue ActiveRecord::RecordNotFound => e
      return [404, {}, "#{e}"]
    end
  end

end
