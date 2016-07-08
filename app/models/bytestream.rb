class Bytestream < ActiveRecord::Base

  ##
  # Must be kept in sync with the return value of human_readable_type().
  #
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
  # @return [Boolean] If the bytestream is a file and the file exists, returns
  #                   true.
  #
  def exists?
    p = absolute_local_pathname
    p and File.exist?(p) and File.file?(p)
  end

  ##
  # @return [String]
  #
  def human_readable_name
    formats = YAML::load(File.read("#{Rails.root}/lib/formats.yml"))
    formats = formats.select{ |f| f['media_types'].include?(self.media_type) }
    formats.any? ? formats.first['label'] : self.media_type
  end

  ##
  # @return [String]
  #
  def human_readable_type
    case self.bytestream_type
      when Bytestream::Type::ACCESS_MASTER
        return 'Access Master'
      when Bytestream::Type::PRESERVATION_MASTER
        return 'Preservation Master'
    end
    nil
  end

  def infer_media_type
    self.media_type = MIME::Types.of(self.absolute_local_pathname).first.to_s
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
  # @return [Array<Hash<Symbol,String>>] Array of hashes with :label,
  #                                      :category, and :value keys.
  #
  def metadata
    load_metadata unless @metadata_loaded
    @metadata
  end

  def serializable_hash(opts)
    {
        type: self.bytestream_type == Type::ACCESS_MASTER ? 'access' : 'presentation',
        media_type: self.media_type
    }
  end

  private

  ##
  # Reads metadata from the file using exiftool.
  #
  def load_metadata
    @metadata = []
    pathname = self.absolute_local_pathname
    if File.exist?(pathname) and File.readable?(pathname)
      json = `exiftool -json -l -G #{pathname}`
      struct = JSON.parse(json)
      struct.first.each do |k, v|
        next if k.include?('ExifToolVersion')
        # show this one in development
        next if k.include?('Directory') and Rails.env.production?
        next if k.include?('FileAccessDate')
        next if k.include?('FilePermissions')
        next if k.include?('FileTypeExtension')
        next if k.include?('CurrentIPTCDigest')

        if v['val']&.kind_of?(String)
          next if v['val']&.include?('use -b option to extract')
        end

        if v['desc'].present? and v['val'].present?
          parts = k.split(':')
          category = parts.length > 1 ? parts[0] : nil
          category = category.upcase if category.include?('Jpeg')
          category.gsub!('ICC_Profile', 'ICC Profile')
          value = v['val'].kind_of?(String) ? v['val'].strip : v['val']
          @metadata << { label: v['desc'], category: category, value: value }
        end
      end
    end
    @metadata_loaded = true
  end

end
