##
# Converts images using the IIIF image server.
#
class IiifImageConverter

  @@logger = CustomLogger.instance

  ##
  # @param binary [Binary]
  # @param directory [String] Directory pathname in which to create the new
  #                           image.
  # @param format [Symbol] IIIF image format extension.
  # @return [String] Pathname of the converted image.
  #
  def convert_binary(binary, directory, format)
    format = format.to_s
    if binary.media_type == 'image/jpeg'
      # The binary is already a JPEG, so just copy it over.
      new_pathname = directory + binary.repository_relative_pathname
      @@logger.debug("ImageConverter.convert_binary(): copying "\
          "#{binary.absolute_local_pathname} to #{new_pathname}")
      FileUtils.mkdir_p(File.dirname(new_pathname))
      FileUtils.cp(binary.absolute_local_pathname, new_pathname)
      return new_pathname
    elsif binary.is_image?
      format.gsub!('.', '')
      new_pathname = directory +
          binary.repository_relative_pathname.split('.')[0...-1].join('.') +
          '.' + format

      if binary.iiif_safe?
        url = binary.iiif_image_url + '/full/full/0/default.' + format

        @@logger.debug("Creating #{new_pathname}")
        FileUtils.mkdir_p(File.dirname(new_pathname))

        File.open(new_pathname, 'wb') do |file|
          @@logger.info("Downloading #{url} to #{new_pathname}")
          ImageServer.instance.client.get_content(url) do |chunk|
            file.write(chunk)
          end
        end
        return new_pathname
      else
        @@logger.info("ImageConverter.convert_binary(): #{binary} will bog "\
            "down the image server; skipping.")
      end
    else
      @@logger.debug("ImageConverter.convert_binary(): #{binary} is not an "\
          "image; skipping.")
    end
  end

  ##
  # @param item [Item]
  # @param directory [String] Directory pathname in which to create the new
  #                           images.
  # @param format [Symbol] IIIF image format extension.
  #
  def convert_images(item, directory, format)
    if item.variant == Item::Variants::DIRECTORY
      item.all_files.each do |file|
        file.binaries.each do |bin|
          convert_binary(bin, directory, format)
        end
      end
    elsif item.items.any?
      item.items.each do |subitem|
        subitem.binaries.where(master_type: Binary::MasterType::ACCESS,
                               media_category: Binary::MediaCategory::IMAGE).each do |bin|
          convert_binary(bin, directory, format)
        end
      end
    else
      item.binaries.where(master_type: Binary::MasterType::ACCESS,
                          media_category: Binary::MediaCategory::IMAGE).each do |bin|
        convert_binary(bin, directory, format)
      end
    end
  end

end