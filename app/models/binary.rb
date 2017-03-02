class Binary < ActiveRecord::Base

  ##
  # Must be kept in sync with the return value of human_readable_type().
  #
  class Type
    ACCESS_MASTER = 1
    COMPOSITE = 3
    PRESERVATION_MASTER = 0
    SUPPLEMENTARY = 2
  end

  # touch: true means when the instance is saved, the owning item's updated_at
  # property will be updated.
  belongs_to :item, inverse_of: :binaries, touch: true

  @@formats = YAML::load(File.read("#{Rails.root}/lib/formats.yml"))

  ##
  # @return [String, nil]
  #
  def absolute_local_pathname
    Configuration.instance.repository_pathname +
        self.repository_relative_pathname
  end

  def as_json(options = {})
    struct = super(options).stringify_keys # TODO: why is this almost empty?
    struct['binary_type'] = self.human_readable_type
    struct['repository_relative_pathname'] = self.repository_relative_pathname
    struct['cfs_file_uuid'] = self.cfs_file_uuid
    struct['byte_size'] = self.byte_size
    struct['width'] = self.width
    struct['height'] = self.height
    struct.except('type')
  end

  ##
  # @return [Boolean] If the binary is a file and the file exists, returns
  #                   true.
  #
  def exists?
    p = absolute_local_pathname
    p and File.exist?(p) and File.file?(p)
  end

  ##
  # @return [String, nil]
  #
  def filename
    self.repository_relative_pathname.present? ?
        File.basename(self.repository_relative_pathname) : nil
  end

  ##
  # @return [String]
  #
  def human_readable_name
    formats = @@formats.select{ |f| f['media_types'].include?(self.media_type) }
    formats.any? ? formats.first['label'] : self.media_type
  end

  ##
  # @return [String]
  #
  def human_readable_type
    case self.binary_type
      when Type::ACCESS_MASTER
        return 'Access Master'
      when Type::COMPOSITE
        return 'Composite'
      when Type::PRESERVATION_MASTER
        return 'Preservation Master'
      when Type::SUPPLEMENTARY
        return 'Supplementary'
    end
    nil
  end

  ##
  # @return [String] IIIF Image API identifier of the binary, regardless of
  #                  whether it is compatible with an image server.
  #
  def iiif_image_identifier
    self.cfs_file_uuid
  end

  ##
  # @return [String] IIIF Image API URL of the binary, regardless of whether it
  #                  is compatible with an image server.
  #
  def iiif_image_url
    Configuration.instance.iiif_url + '/' +
        CGI.escape(self.iiif_image_identifier)
  end

  ##
  # @return [String] IIIF info.json URL.
  #
  def iiif_info_url
    self.iiif_image_url + '/info.json'
  end

  ##
  # @return [Boolean] Whether the instance is presumed safe to feed to an
  #                   image server (won't bog it down too much).
  #
  def iiif_safe?
    max_tiff_size = 30000000 # arbitrary
    return false if self.repository_relative_pathname.blank?
    return false unless self.is_image? or self.is_pdf? or self.is_video?
    # Large TIFF preservation masters are probably neither tiled nor
    # multiresolution, so are going to be very inefficient to read.
    return false if self.media_type == 'image/tiff' and
        self.byte_size > max_tiff_size
    true
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

  ##
  # @return [Boolean] Whether the binary is of a still or moving raster image
  #                   (video) with pixel dimensions.
  #
  def is_raster?
    is_image? or is_video?
  end

  def is_text?
    self.media_type and self.media_type.start_with?('text/plain')
  end

  def is_video?
    self.media_type and self.media_type.start_with?('video/')
  end

  ##
  # @return [String, nil]
  #
  def medusa_url
    url = nil
    if self.cfs_file_uuid.present?
      url = Configuration.instance.medusa_url.chomp('/') + '/uuids/' +
          self.cfs_file_uuid
    end
    url
  end

  ##
  # Returns metadata for human consumption that is not guaranteed to be in any
  # particular format.
  #
  # @return [Enumerable<Hash<Symbol,String>>] Array of hashes with :label,
  #                                          :category, and :value keys.
  #
  def metadata
    read_metadata unless @metadata_read
    @metadata
  end

  ##
  # Populates the width and height properties by reading the dimensions from
  # the source image or video.
  #
  # @return [void]
  #
  def read_dimensions
    if is_image?
      # Redirect stderr to /dev/null as there is apparently no other way to
      # suppress "no exif data found in the file" messages.
      output = `exiv2 "#{self.absolute_local_pathname.gsub('"', '\\"')}" 2> /dev/null`
      output.encode('UTF-8', invalid: :replace).split("\n").each do |row|
        if row.downcase.start_with?('image size')
          columns = row.split(':')
          if columns.length > 1
            dimensions = columns[1].split('x')
            if dimensions.length == 2
              self.width = dimensions[0].strip.to_i
              self.height = dimensions[1].strip.to_i
            end
          end
        end
      end
    elsif is_video?
      # TODO: write this
    end
  end

  ##
  # @return [Integer]
  #
  def read_size
    self.byte_size = File.size(self.absolute_local_pathname)
  end

  def serializable_hash(opts)
    {
        type: self.human_readable_type,
        media_type: self.media_type
    }
  end

  def to_param
    cfs_file_uuid
  end

  private

  ##
  # Reads metadata from the file using exiftool.
  #
  # @raises [IOError] If the file does not exist or is not readable.
  #
  def read_metadata
    @metadata = []
    pathname = self.absolute_local_pathname

    raise IOError, "Does not exist: #{pathname}" unless File.exist?(pathname)
    raise IOError, "Not readable: #{pathname}" unless File.readable?(pathname)

    # exiftool's output is more comprehensive, but as of 2016-09-01, it appears
    # to cause my local machine's condo NFS mount to unmount itself. OTRS ticket
    # filed, but don't want to wait on it. OTOH, exiv2 is faster. --AAD
    #read_metadata_using_exiftool(pathname)
    read_metadata_using_exiv2(pathname)

    @metadata_read = true
  end

  ##
  # @param pathname [String]
  #
  def read_metadata_using_exiftool(pathname)
    json = `exiftool -json -l -G "#{pathname.gsub('"', '\\"')}"`
    begin
      struct = JSON.parse(json)
      struct.first.each do |k, v|
        next if k.include?('ExifToolVersion')
        next if k.include?('Directory') and Rails.env.production?
        next if k.include?('FileAccessDate')
        next if k.include?('FilePermissions')
        next if k.include?('FileTypeExtension')
        next if k.include?('CurrentIPTCDigest')

        if v['val']&.kind_of?(String)
          # Skip binary values
          next if v['val']&.include?('use -b option to extract')
        end

        if v['desc'].present? and v['val'].present?
          parts = k.split(':')
          category = parts.length > 1 ? parts[0] : nil
          category = category.upcase if category.include?('Jpeg')
          category.gsub!('_', ' ')
          value = v['val'].kind_of?(String) ? v['val'].strip : v['val']
          @metadata << { label: v['desc'], category: category, value: value }
        end
      end
    rescue JSON::ParserError => e
      CustomLogger.instance.warn("Binary.read_metadata(): #{e}")
    end
  end

  ##
  # @param pathname [String]
  #
  def read_metadata_using_exiv2(pathname)
    output = `exiv2 -Pklt "#{pathname.gsub('"', '\\"')}"`
    output.encode('UTF-8', invalid: :replace).split("\n").each do |row|
      next if row.length < 10

      first_space = row.index(' ')
      col_2_start = first_space
      begin
        row[first_space..row.length - 1].split('').each_with_index do |char, index|
          if char != ' '
            col_2_start += index
            break
          end
        end
      rescue ArgumentError => e
        next if "#{e}".include?('bad value for range')
      end
      key = row[0..first_space - 1]

      next if key.start_with?('Exif.Thumbnail')
      next if key.start_with?('Xmp.xmpMM.DerivedFrom')
      next if key.start_with?('Xmp.xmpMM.History')

      cols = [key] + row[col_2_start..row.length - 1].gsub('  ', "\t").
          squeeze("\t").split("\t")

      value = cols[2]&.strip
      if value.present?
        label = cols[1].strip
        category = key.split('.').first.upcase
        
        md = @metadata.select{ |m| m[:category] == category and m[:label] == label }
        if md.any?
          unless md.first[:value].respond_to?(:each)
            md.first[:value] = [ md.first[:value] ]
          end
          md.first[:value] << value
        else
          @metadata << { label: label, category: category, value: value }
        end
      end
    end
  end

end
