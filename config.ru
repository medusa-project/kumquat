# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)

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
          bs = item.access_master_bytestream
          if bs
            file = File.open(bs.absolute_local_pathname, 'rb')
            crc32 = ZipTricks::StreamCRC32.from_io(file)
            file.rewind
            filename = "#{item.repository_id}#{File.extname(bs.absolute_local_pathname)}"
            begin
              zip.add_stored_entry(filename: filename, size: file.size, crc32: crc32)
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

map '/items/download' do
  run ZipDownloader.new
end

run Rails.application
