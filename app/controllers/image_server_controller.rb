class ImageServerController < WebsiteController

  ##
  # Streams an image from the image server, overriding the Content-Disposition
  # response header to 'attachment'.
  #
  # Responds to GET /download-image/:identifier/:region/:scale/:rotation/:quality.:format
  #
  def download_image
    binary = Binary.find_by_cfs_file_uuid(params[:identifier])
    raise ActiveRecord::RecordNotFound unless binary

    region = params[:region].gsub(/[^a-z0-9,]/, '')
    size = params[:size].gsub(/[^a-z0-9,!]/, '')
    rotation = params[:rotation].gsub(/[^0-9,!]/, '')
    quality = params[:quality].gsub(/[^a-z]/, '')
    format = params[:format].gsub(/[^a-z]/, '')

    raise ArgumentError, 'Illegal region argument' if region != params[:region]
    raise ArgumentError, 'Illegal size argument' if size != params[:size]
    raise ArgumentError, 'Illegal rotation argument' if rotation != params[:rotation]
    raise ArgumentError, 'Illegal quality argument' if quality != params[:quality]
    raise ArgumentError, 'Illegal format argument' if format != params[:format]

    url = sprintf("%s/%s/%s/%s/%s/%s.%s",
                  ::Configuration.instance.iiif_url,
                  CGI::escape(params[:identifier]),
                  region, size, rotation, quality, format)

    filename = File.basename(binary.filename, File.extname(binary.filename)) +
        '.' + format
    client = ImageServer.instance.client

    send_data client.get(url), disposition: 'attachment', filename: filename
  end

end
