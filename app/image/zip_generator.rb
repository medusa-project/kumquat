##
# Generates zip files for [Item]s.
#
class ZipGenerator

  LOGGER = CustomLogger.new(ZipGenerator)

  ##
  # Generates a zip file for an [Item]. The file consists of all of an item's
  # images converted to JPEGs.
  #
  # @param items [ActiveRecord::Relation<Item>]
  # @param include_private_binaries [Boolean]
  # @param task [Task] Optional.
  # @return [String] Pathname of the generated zip file.
  #
  def generate_zip(items:, include_private_binaries: false, task: nil)
    converter = IiifImageConverter.new

    Dir.mktmpdir do |tmpdir|
      Item.uncached do
        items.find_each do |item|
          converter.convert_images(item:                     item,
                                   directory:                tmpdir,
                                   format:                   :jpg,
                                   include_private_binaries: include_private_binaries,
                                   task:                     task)
        end
      end

      zip_filename = "item-#{Time.now.to_formatted_s(:number)}.zip"
      zip_tmpdir   = Dir.mktmpdir
      zip_pathname = File.join(zip_tmpdir, zip_filename)

      # -j: don't record directory names
      # -r: recurse into directories
      LOGGER.debug("Generating #{zip_pathname}")
      `zip -jr "#{zip_pathname}" #{tmpdir}`

      zip_pathname
    end
  end


  private

  ##
  # @return [String] Pathname of the generated PDF.
  #
  def temp_dir
    unless @temp_dir && Dir.exist?(@temp_dir)
      @temp_dir = Dir.mktmpdir
    end
    @temp_dir
  end

end
