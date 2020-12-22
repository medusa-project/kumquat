##
# Converts images using the image server.
#
class IiifImageConverter

  LOGGER = CustomLogger.new(IiifImageConverter)

  ##
  # Converts a single image binary to the given format and writes it as a file
  # in the given directory.
  #
  # @param binary [Binary]
  # @param directory [String] Directory pathname in which to create the new
  #                           image.
  # @param format [Symbol] IIIF image format extension.
  # @return [String] Pathname of the converted image.
  #
  def convert_binary(binary, directory, format)
    format = format.to_s
    if binary.media_type == 'image/jpeg'
      # The binary is already a JPEG, so just download it.
      new_pathname = directory + '/' + binary.object_key

      LOGGER.debug('convert_binary(): downloading %s to %s',
                     binary.object_key, new_pathname)

      FileUtils.mkdir_p(File.dirname(new_pathname))

      MedusaS3Client.instance.get_object(
          bucket: MedusaS3Client::BUCKET,
          key: binary.object_key,
          response_target: new_pathname)
      return new_pathname
    elsif binary.is_image?
      format.gsub!('.', '')
      new_pathname = directory + '/' +
          binary.object_key.split('.')[0...-1].join('.') +
          '.' + format

      if binary.image_server_safe?
        # ?cache=false is supported by Cantaloupe to help reduce the cache size.
        url = binary.iiif_image_url + '/full/full/0/default.' + format +
            '?cache=false'

        LOGGER.debug('Creating %s', new_pathname)
        FileUtils.mkdir_p(File.dirname(new_pathname))

        File.open(new_pathname, 'wb') do |file|
          LOGGER.info('Downloading %s to %s', url, new_pathname)
          ImageServer.instance.client.get_content(url) do |chunk|
            file.write(chunk)
          end
        end
        return new_pathname
      else
        LOGGER.info('convert_binary(): %s will bog down the image server; skipping.',
                    binary)
      end
    else
      LOGGER.debug('convert_binary(): %s is not an image; skipping.', binary)
    end
  end

  ##
  # Converts all relevant image binaries associated with an item (or its
  # children, depending on what kind of item it is) to the given format and
  # writes them as files in the given directory.
  #
  # @param item [Item]
  # @param directory [String] Directory pathname in which to create the new
  #                           images.
  # @param format [Symbol] IIIF image format extension.
  # @param include_private_binaries [Boolean]
  # @param task [Task] Supply to receive progress updates.
  # @return [void]
  #
  def convert_images(item:,
                     directory:,
                     format:,
                     include_private_binaries: false,
                     task: nil)
    Item.uncached do
      # If the item is a directory variant, convert all of the files within it,
      # at any level in the tree.
      if item.variant == Item::Variants::DIRECTORY
        # Fetch results in batches to reduce memory consumption.
        offset  = 0
        limit   = 100
        results = nil
        while results.nil? || results.length > 0
          results = item.all_files(offset: offset, limit: limit)
          results.each do |file_item|
            binaries = file_item.binaries.where('media_type LIKE ?', 'image/%')
            binaries = binaries.where(public: true) unless include_private_binaries
            binaries.each do |bin| # there should only be one
              convert_binary(bin, directory, format)
            end
          end
          offset += limit
        end
      # If the item has any child items, convert those.
      elsif item.items.count > 0
        item.items.find_each do |subitem|
          binaries = subitem.binaries.where(
              master_type:    Binary::MasterType::ACCESS,
              media_category: Binary::MediaCategory::IMAGE)
          binaries = binaries.where(public: true) unless include_private_binaries
          count    = binaries.count
          binaries.each_with_index do |bin, index|
            task&.progress = index / count.to_f
            convert_binary(bin, directory, format)
          end
        end
      # The item has no child items, so it's likely either standalone or a file
      # variant.
      else
        binaries = item.binaries.where(
            master_type: Binary::MasterType::ACCESS,
            media_category: Binary::MediaCategory::IMAGE)
        binaries = binaries.where(public: true) unless include_private_binaries
        count    = binaries.length
        binaries.each_with_index do |bin, index|
          task&.progress = index / count.to_f
          convert_binary(bin, directory, format)
        end
      end
    end
    task&.succeeded
  end

end