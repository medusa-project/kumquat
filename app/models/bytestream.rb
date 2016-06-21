class Bytestream < ActiveRecord::Base

  class Type
    ACCESS_MASTER = 1
    PRESERVATION_MASTER = 0
  end

  belongs_to :item, inverse_of: :bytestreams

  ##
  # @return [String, nil]
  #
  def absolute_local_pathname
    PearTree::Application.peartree_config[:repository_pathname] +
        self.repository_relative_pathname
  end

  ##
  # Reads the byte size of the bytestream from disk.
  #
  # @return [Integer, nil]
  #
  def byte_size
    pathname = self.absolute_local_pathname
    pathname and File.exist?(pathname) and File.file?(pathname) ?
        File.size(pathname) : nil
  end

  ##
  # @return [Hash]
  #
  def exif
    load_metadata unless @metadata_loaded
    @metadata.select{ |k,v| !%w(iptc xmp).include?(k.to_s) and v.present? }
  end

  ##
  # @return [Boolean] If the bytestream is a file and the file exists, returns
  #                   true.
  #
  def exists?
    p = absolute_local_pathname
    p and File.exist?(p) and File.file?(p)
  end

  def human_readable_name
    formats = YAML::load(File.read("#{Rails.root}/lib/formats.yml"))
    formats = formats.select{ |f| f['media_types'].include?(self.media_type) }
    formats.any? ? formats.first['label'] : self.media_type
  end

  def infer_media_type
    self.media_type = MIME::Types.of(self.absolute_local_pathname).first.to_s
  end

  ##
  # @return [String]
  #
  def iptc
    load_metadata unless @metadata_loaded
    @metadata[:iptc] ? @metadata[:iptc].join("\n").strip : nil
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

  def serializable_hash(opts)
    {
        type: self.bytestream_type == Type::ACCESS_MASTER ? 'access' : 'presentation',
        media_type: self.media_type,
        width: self.width,
        height: self.height
    }
  end

  ##
  # @return [String]
  #
  def xmp
    load_metadata unless @metadata_loaded
    @metadata[:xmp] ? @metadata[:xmp].strip : nil
  end

  private

  def load_metadata
    @metadata = {}
    pathname = self.absolute_local_pathname
    if File.exist?(pathname) and File.readable?(pathname)
      case MIME::Types.of(pathname).first.to_s
        when 'image/jpeg'
          @metadata = EXIFR::JPEG.new(pathname).to_hash
        when 'image/tiff'
          @metadata = EXIFR::TIFF.new(pathname).to_hash
      end
    end
    @metadata_loaded = true
  end

end
