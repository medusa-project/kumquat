##
# Rack application to handle streaming zip downloads. Requires an "items" query
# string key pointing to a comma-delimited list of item database IDs.
#
class ZipDownloader

  def call(env)
    parts = env['QUERY_STRING'].split('=')
    if parts.length > 1 and parts.first == 'items'
      ids = parts[1].split(',').map(&:to_i)
      items = Item.where('id IN (?)', ids)

      body = ZipTricks::RackBody.new do |zip|
        items.each do |item|
          # Include the item's JSON metadata in the zip.
          json = JSON.pretty_generate(item.decorate(context: { web: false }).as_json)
          json_io = StringIO.new(json)

          crc32 = ZipTricks::StreamCRC32.from_io(json_io)
          json_io.rewind
          filename = "#{item.repository_id}/metadata.json"
          zip.add_stored_entry(filename: filename, size: json_io.size,
                               crc32: crc32)
          IO.copy_stream(json_io, zip)

          # If the item has an access master, include it in the zip also.
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
    end
    [400, {}, 'Bad Request']
  end

end
