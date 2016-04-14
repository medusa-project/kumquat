class Bytestream < ActiveRecord::Base

  class Type
    ACCESS_MASTER = 1
    PRESERVATION_MASTER = 0
  end

  belongs_to :item, inverse_of: :bytestreams

  ##
  # @return [String, nil] Absolute local pathname, or nil if the instance is a
  #                       "URL" bytestream (in which case the `url` getter
  #                       would be more relevant).
  #
  def absolute_local_pathname
    self.item.collection.medusa_file_group.cfs_directory.pathname +
        self.file_group_relative_pathname
  end

  ##
  # Reads the byte size of the bytestream from disk.
  #
  # @return [Integer, nil]
  #
  def byte_size
    pathname = self.absolute_local_pathname
    pathname and File.exist?(pathname) ? File.size(pathname) : nil
  end

  ##
  # @return [Hash]
  #
  def exif
    exif = {}
    pathname = self.absolute_local_pathname
    if File.exist?(pathname) and File.readable?(pathname)
      case MIME::Types.of(pathname).first.to_s
        when 'image/jpeg'
          exif = EXIFR::JPEG.new(pathname).to_hash
        when 'image/tiff'
          exif = EXIFR::TIFF.new(pathname).to_hash
      end
    end
    exif.select{ |k,v| v.present? }
  end

  ##
  # @return [Boolean] If the bytestream is a file and the file exists, returns
  #                   true. Always returns true for URLs.
  #
  def exists?
    p = absolute_local_pathname
    self.url or (p and File.exist?(p))
  end

  def human_readable_name
    formats = YAML::load(File.read("#{Rails.root}/lib/formats.yml"))
    formats = formats.select{ |f| f['media_types'].include?(self.media_type) }
    formats.any? ? formats.first['label'] : self.media_type
  end

  def is_audio?
    self.media_type and self.media_type.start_with?('audio/')
  end

  def is_image?
    self.media_type and self.media_type.start_with?('image/')
  end

  def is_pdf?
    self.media_type and self.media_type == 'application/pdf'
  end

  def is_text?
    self.media_type and self.media_type.start_with?('text/plain')
  end

  def is_video?
    self.media_type and self.media_type.start_with?('video/')
  end

  def repository_relative_pathname
    self.item.collection.medusa_file_group.cfs_directory.repository_relative_pathname +
        self.file_group_relative_pathname
  end

  def serializable_hash(opts)
    {
        type: self.bytestream_type == Type::ACCESS_MASTER ? 'access' : 'presentation',
        media_type: self.media_type,
        width: self.width,
        height: self.height
    }
  end

end
