class Bytestream

  class Shape
    ORIGINAL = :original
    SQUARE = :square
  end

  class Type
    ACCESS_MASTER = :access_master
    PRESERVATION_MASTER = :preservation_master
  end

  # @!attribute height
  #   @return [Integer]
  attr_accessor :height

  # @!attribute media_type
  #   @return [String]
  attr_accessor :media_type

  # @!attribute repository_relative_pathname
  #   @return [String] Pathname of the bytestream relative to the repository
  #                    root.
  attr_accessor :repository_relative_pathname

  # @!attribute type
  #   @return [Bytestream::Type]
  attr_accessor :type

  # @!attribute url
  #   @return [String]
  attr_accessor :url

  # @!attribute width
  #   @return [Integer]
  attr_accessor :width

  ##
  # Reads the byte size of the bytestream from disk.
  #
  # @return [Integer, nil]
  #
  def byte_size
    self.pathname and File.exist?(self.pathname) ? File.size(self.pathname) : nil
  end

  ##
  # Attempts to detect the media type and assigns it to the instance.
  #
  # @raise [RuntimeError] if neither pathname nor url are set
  # @return [void]
  #
  def detect_media_type
    if self.pathname and File.exist?(self.pathname)
      self.media_type = MIME::Types.of(self.pathname).first.to_s
    elsif self.url
      self.media_type = MIME::Types.of(self.url).first.to_s
    else
      raise 'Pathname not set'
    end
  end

  ##
  # @return [Boolean] If the bytestream is a file and the file exists, returns
  # true. Always returns true for URLs.
  #
  def exists?
    self.url or (self.pathname and File.exist?(self.pathname))
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

  ##
  # @return [String, nil] Absolute local pathname, or nil if the instance is a
  # "URL" bytestream (in which case the `url` getter would be more relevant).
  #
  def pathname
    rp = PearTree::Application.peartree_config[:repository_pathname]
    (rp and self.repository_relative_pathname) ?
        rp + self.repository_relative_pathname : nil
  end

  ##
  # Reads the width and height (if an image) and assigns them to the instance.
  #
  # @raise [RuntimeError] if pathname is not set
  # @return [void]
  #
  def read_dimensions
    raise 'Pathname is not set' unless self.pathname
    if self.is_image?
      glue = '|'
      # TODO: use ruby or IIIF instead
      output = `identify -format "%[fx:w]#{glue}%[fx:h]" #{self.pathname}`
      parts = output.split(glue)
      if parts.length == 2
        self.width = parts[0].strip.to_i
        self.height = parts[1].strip.to_i
      end
    end
  end

end
