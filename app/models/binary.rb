##
# Represents a file.
#
# Binaries are attached to Items. An Item may have zero or more Binaries. A
# binary can only belong to one item. When an item is deleted, all of its
# binaries are deleted along with it.
#
# Binaries are analogous to "CFS files" in Medusa, and can be constructed by
# MedusaCfsFile.to_binary().
#
# A binary may have a master type of access or preservation. Preservation
# masters are typically in a preservation-optimized format/encoding, and access
# masters are typically a derivation of the preservation master that may be
# smaller or more compatible with viewer software etc.
#
# A binary has a media (MIME) type, which may be different from the Medusa
# CFS file's media type (which is often vague). When they differ, the Binary's
# media type is usually more specific.
#
# A binary may also reside in a media category (see the inner enum-like
# MediaCategory class), which helps to differentiate binaries that have the
# same media type but different uses. This especially comes into play in
# collections that use the Mixed Media package profile. Selecting the right
# binary to use in a given context generally means querying the item's
# binaries.
#
# # Attributes
#
# * byte_size:      Size of the binary's contents in bytes.
# * cfs_file_uuid:  UUID of the binary's corresponding file in Medusa.
# * created_at:     Managed by ActiveRecord.
# * duration:       Duration of audio/video, in seconds.
# * height:         Native pixel height of a raster binary (image or video).
# * item_id:        Database ID of the binary's owning item.
# * master_type:    One of the Binary::MasterType constant values; see its
#                   class documentation.
# * media_category: One of the Binary::MediaCategory constant values; see its
#                   class documentation.
# * media_type:     Best-fit IANA media (MIME) type.
# * repository_relative_pathname: Pathname of the binary relative to the
#                                 repository root directory.
# * updated_at:     Managed by ActiveRecord.
# * width:          Native pixel width of a raster binary (image or video).
#
class Binary < ApplicationRecord

  ##
  # Must be kept in sync with the return value of human_readable_master_type().
  #
  class MasterType
    ACCESS = 1
    PRESERVATION = 0
  end

  ##
  # Broad category in which a binary can be considered to reside. This may be
  # different from the one in `media_type`; for example, the main image and a
  # 3D model texture may both be JPEGs, but be in different categories, and
  # when displaying an image viewer, we want to select the main image.
  #
  class MediaCategory
    AUDIO = 3
    BINARY = 5
    IMAGE = 0
    DOCUMENT = 1
    TEXT = 6
    THREE_D = 4
    VIDEO = 2

    ##
    # @param media_type [String]
    # @return [Integer, nil] MediaCategory constant value best fitting the
    #                   given media type; or nil.
    #
    def self.media_category_for_media_type(media_type)
      case media_type
        when 'text/plain'
          return TEXT
      end
      # TODO: this code finds the first but not necessarily best match, which
      # is the reason for the override above. Pretty sloppy
      formats = Binary.class_variable_get(:'@@formats')
      formats = formats.select{ |f| f['media_types'].include?(media_type) }
      formats.any? ? formats.first['media_category'] : nil
    end
  end

  # touch: true means when the instance is saved, the owning item's updated_at
  # property will be updated.
  belongs_to :item, inverse_of: :binaries, touch: true

  validates :byte_size, numericality: { only_integer: true,
                                        greater_than_or_equal_to: 0 },
            allow_blank: false

  @@formats = YAML::load(File.read("#{Rails.root}/lib/formats.yml"))

  ##
  # @return [Integer] Total byte size of all binaries in the system.
  #
  def self.total_byte_size
    sql = 'SELECT SUM(byte_size) AS sum FROM binaries'
    result = Binary.connection.exec_query(sql, 'SQL', [])
    result[0]['sum'].to_i
  end

  ##
  # @return [String, nil]
  #
  def absolute_local_pathname
    if self.repository_relative_pathname.present?
      return Configuration.instance.repository_pathname +
          self.repository_relative_pathname
    end
    nil
  end

  ##
  # @return [String]
  # @see http://dublincore.org/documents/dcmi-type-vocabulary/#H7
  #
  def dc_type
    type = nil
    if self.is_3d?
      type = 'PhysicalObject'
    elsif self.is_image?
      type = 'StillImage'
    elsif self.is_video?
      type = 'MovingImage'
    elsif self.is_audio?
      type = 'Sound'
    elsif self.is_pdf? or self.is_text?
      type = 'Text'
    end
    type
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
  def human_readable_media_category
    case self.media_category
      when MediaCategory::AUDIO
        return 'Audio'
      when MediaCategory::BINARY
        return 'Binary'
      when MediaCategory::IMAGE
        return 'Image'
      when MediaCategory::DOCUMENT
        return 'Document'
      when MediaCategory::TEXT
        return 'Text'
      when MediaCategory::THREE_D
        return '3D'
      when MediaCategory::VIDEO
        return 'Video'
    end
    nil
  end

  ##
  # @return [String]
  #
  def human_readable_master_type
    case self.master_type
      when MasterType::ACCESS
        return 'Access Master'
      when MasterType::PRESERVATION
        return 'Preservation Master'
    end
    nil
  end

  ##
  # @return [String]
  #
  def human_readable_name
    formats = @@formats.select{ |f| f['media_types'].include?(self.media_type) }
    formats.any? ? formats.first['label'] : self.media_type
  end

  ##
  # @return [String] IIIF Image API identifier of the instance.
  #
  def iiif_image_identifier
    self.cfs_file_uuid
  end

  ##
  # @return [String] IIIF Image API URL of the instance, regardless of whether
  #                  it is compatible with an image server.
  # @see iiif_safe?()
  #
  def iiif_image_url
    Configuration.instance.iiif_url + '/' +
        CGI.escape(self.iiif_image_identifier)
  end

  ##
  # @return [String] IIIF Image API info.json URL.
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
        self.byte_size and self.byte_size > max_tiff_size
    true
  end

  def infer_media_type
    case File.extname(self.repository_relative_pathname).downcase
      when '.mtl'
        self.media_type = 'text/plain'
      when '.obj'
        self.media_type = 'text/plain'
      else
        # TODO: the mime-types gem only reads the extension, not the header,
        # and only recognizes a limited number of extensions.
        self.media_type = MIME::Types.of(self.absolute_local_pathname).first.to_s
    end
  end

  def is_3d?
    (self.media_category == MediaCategory::THREE_D)
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
  # @return [String, nil] URL of the binary's equivalent Medusa CFS file.
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
  # @return [void]
  #
  def read_characteristics
    read_size
    read_dimensions
    read_duration
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
  # Populates the width and height properties by reading the dimensions from
  # the source image or video.
  #
  # @return [void]
  # @raises [Errno::ENOENT] If the file does not exist.
  #
  def read_duration
    raise Errno::ENOENT unless self.exists?
    if is_audio? or is_video?
      # Redirect ffprobe stderr output to stdout.
      output = `ffprobe "#{self.absolute_local_pathname.gsub('"', '\\"')}" 2>&1`
      result = output.match(/[0-9][0-9]:[0-5][0-9]:[0-5][0-9]/)
      if result and result.length > 0
        begin
          self.duration = TimeUtil.hms_to_seconds(result[0])
        rescue ArgumentError => e
          CustomLogger.instance.warn("Binary.read_duration(): #{e}")
        end
      end
    end
  end

  ##
  # @return [Integer]
  #
  def read_size
    self.byte_size = File.size(self.absolute_local_pathname)
  end

  def to_param
    cfs_file_uuid
  end

  ##
  # @return [String] The instance's repository-relative pathname, or its CFS
  #                  file UUID, or the return value of super -- whichever is
  #                  present first.
  #
  def to_s
    str = self.repository_relative_pathname
    str = self.cfs_file_uuid if str.blank?
    str = super if str.blank?
    str
  end

  private

  ##
  # Reads metadata from the file using exiftool.
  #
  # @raises [IOError] If the file does not exist or is not readable.
  #
  def read_metadata
    @metadata = []

    return unless self.is_image?

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
