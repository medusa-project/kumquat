class Bytestream

  class Shape
    ORIGINAL = :original
    SQUARE = :square
  end

  class Type
    ACCESS_MASTER = :access_master
    PRESERVATION_MASTER = :preservation_master
  end

  # @!attribute file_group
  #   @return [MedusaFileGroup]
  attr_accessor :file_group

  # @!attribute file_group_relative_pathname
  #   @return [String] Pathname of the bytestream relative to its file group
  #                    root.
  attr_accessor :file_group_relative_pathname

  # @!attribute height
  #   @return [Integer]
  attr_accessor :height

  # @!attribute media_type
  #   @return [String]
  attr_accessor :media_type

  # @!attribute type
  #   @return [Bytestream::Type]
  attr_accessor :type

  # @!attribute url
  #   @return [String]
  attr_accessor :url

  # @!attribute width
  #   @return [Integer]
  attr_accessor :width

  def initialize(file_group)
    raise 'File group is nil' unless file_group
    self.file_group = file_group
  end

  ##
  # @return [String, nil] Absolute local pathname, or nil if the instance is a
  # "URL" bytestream (in which case the `url` getter would be more relevant).
  #
  def absolute_local_pathname
    self.file_group.cfs_directory.pathname + self.file_group_relative_pathname
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
  # Attempts to detect the media type and assigns it to the instance.
  #
  # @raise [RuntimeError] if neither pathname nor url are set
  # @return [void]
  #
  def detect_media_type
    p = absolute_local_pathname
    if p and File.exist?(p)
      self.media_type = MIME::Types.of(p).first.to_s
    elsif self.url
      self.media_type = MIME::Types.of(p).first.to_s
    else
      raise 'Pathname not set'
    end
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
  # true. Always returns true for URLs.
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
    self.file_group.cfs_directory.repository_relative_pathname +
        self.file_group_relative_pathname
  end

end
