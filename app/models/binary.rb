##
# Represents a file.
#
# Binaries have a many-to-one relationship with {Item}s. When an item is
# deleted, so are all of its binaries.
#
# Binaries are analogous to "CFS files" in Medusa, and are commonly obtained
# via {MedusaCfsFile#to_binary}.
#
# Binary data is accessible via {data}, which returns a stream of data from the
# repository S3 bucket.
#
# A binary may have a {MasterType master type}. {MasterType::PRESERVATION
# Preservation masters} are typically in a preservation-optimized format/
# encoding, and {MasterType::ACCESS access masters} are typically a variant of
# the preservation master that may be smaller, more compatible with an image
# server or client viewer software, etc.
#
# A binary has a media (MIME) type, which may be different from the Medusa
# CFS file's media type (which tends to be vague). When the two differ, the
# Binary's media type is usually more specific.
#
# A binary may also reside in a {MediaCategory media category}, which helps to
# differentiate binaries that have the same media type but different uses.
# This is relevant in collections that use the
# {PackageProfile::MIXED_MEDIA_PROFILE Mixed Media package profile}, whose
# items may have a representative `image/jpeg` binary as well as an
# `image/jpeg` 3D model texture.
#
# # Attributes
#
# * `byte_size`      Size of the binary's contents in bytes.
# * `cfs_file_uuid`  UUID of the binary's corresponding file in Medusa.
# * `created_at`     Managed by ActiveRecord.
# * `duration`       Duration of audio/video, in seconds.
# * `height`         Native pixel height of a raster binary (image or video).
# * `item_id`        Database ID of the binary's owning item.
# * `master_type`    One of the {MasterType} constant values.
# * `media_category` One of the {MediaCategory} constant values.
# * `media_type`     Best-fit IANA media (MIME) type.
# * `object_key`     S3 object key.
# * `updated_at`     Managed by ActiveRecord.
# * `width`          Native pixel width of a raster binary (image or video).
#
class Binary < ApplicationRecord

  ##
  # Must be kept in sync with the return value of {Binary#human_readable_master_type()}.
  #
  class MasterType
    ACCESS       = 1
    PRESERVATION = 0
  end

  ##
  # Broad category in which a binary can be considered to reside. This may be
  # different from the one in `media_type`; for example, the main image and a
  # 3D model texture may both be JPEGs, but be in different categories, and
  # when displaying an image viewer, we want to select the main image, and not
  # a texture.
  #
  class MediaCategory
    AUDIO    = 3
    BINARY   = 5
    IMAGE    = 0
    DOCUMENT = 1
    TEXT     = 6
    THREE_D  = 4
    VIDEO    = 2

    ##
    # @param media_type [String]
    # @return [Integer, nil] MediaCategory constant value best fitting the
    #                        given media type; or nil.
    #
    def self.media_category_for_media_type(media_type)
      case media_type
        when 'image/vnd.adobe.photoshop'
          return IMAGE
        when 'text/plain'
          return TEXT
      end
      # TODO: this code finds the first but not necessarily best match, which is the reason for the override above. Pretty sloppy
      formats = Binary.class_variable_get(:'@@formats')
      formats = formats.select{ |f| f['media_types'].include?(media_type) }
      formats.any? ? formats.first['media_category'] : nil
    end
  end

  LOGGER = CustomLogger.new(Binary)
  DEFAULT_MEDIA_TYPE = 'unknown/unknown'

  # touch: true means when the instance is saved, the owning item's updated_at
  # property will be updated.
  belongs_to :item, inverse_of: :binaries, touch: true, optional: true

  validates :byte_size, numericality: { only_integer: true,
                                        greater_than_or_equal_to: 0 },
            allow_blank: false
  validates :object_key, length: { allow_blank: false }

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
  # @return [IO] Read-only stream of the instance's data.
  #
  def data
    client = MedusaS3Client.instance
    response = client.get_object(
        bucket: MedusaS3Client::BUCKET,
        key: self.object_key)
    response.body
  end

  ##
  # @return [String]
  # @see https://www.dublincore.org/specifications/dublin-core/dcmi-type-vocabulary/
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
  # @return [Boolean] True if the object to which `object_key` refers exists;
  #                   false otherwise.
  #
  def exists?
    MedusaS3Client.instance.head_object(bucket: MedusaS3Client::BUCKET,
                                        key: self.object_key)
    true
  rescue Aws::S3::Errors::NotFound
    false
  end

  ##
  # @return [String, nil] The filename portion of `object_key`.
  #
  def filename
    File.basename(self.object_key)
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
  def human_readable_name
    name = nil
    formats = @@formats.select{ |f| f['media_types'].include?(self.media_type) }
    if formats.any?
      name = formats.first['label']
    end
    if name.blank?
      name = self.media_type
    end
    if name.blank?
      name = 'Unknown Type'
    end
    name
  end

  ##
  # If the instance is attached to an Item that has an embed tag that refers
  # to a video in [UI MediaSpace](https://mediaspace.illinois.edu), parts of the
  # URL in its `src` attribute are extracted in order to construct an
  # identifier that the image server will recognize as an image it should serve
  # from there.
  #
  # Otherwise, the Medusa file UUID is returned.
  #
  # This is, of course, an ugly hack and we would be better off getting video
  # stills quickly out of an S3 bucket, if we could.
  #
  # @return [String] Image server identifier of the instance.
  #
  def iiif_image_identifier
    if is_media_space_video?
      matches = self.item.embed_tag.match(/src="(.*?)"/)
      if matches
        video_url = matches[0][5..matches[0].length - 2]
        bits = video_url.match(/\/p\/(\d+)\/sp\/(\d+)\/.*&entry_id=([A-Za-z0-9_]+)/).captures
        return (['v'] + bits[0..2]).join('/')
      end
    else
      self.cfs_file_uuid
    end
  end

  ##
  # @return [String] IIIF Image API URI of the instance, regardless of whether
  #                  it is compatible with an image server.
  # @see image_server_safe?
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
  # @return [Boolean] Whether the instance is presumed safe to feed through an
  #                   image server (won't bog it down too much).
  #
  def image_server_safe?
    if self.object_key.present?
      psd_types = %w(image/vnd.adobe.photoshop application/x-photoshop
          application/photoshop application/psd image/psd)
      if self.is_image? and !psd_types.include?(self.media_type)
        # Large TIFF files are probably neither tiled nor multiresolution, so
        # are going to bog down the image server in proportion to their size.
        max_tiff_size = 25000000
        if self.media_type == 'image/tiff' and
            self.byte_size and self.byte_size > max_tiff_size
          return false
        end
        return true
      elsif self.is_pdf? or self.is_media_space_video?
        return true
      end
    end
    false
  end

  ##
  # Tries to infer the media type of the instance. The first resort is to check
  # for a recognized extension in the object key, and the last resort (because
  # it is more expensive) is to read the first few bytes of the file and
  # attempt infer a media type from that.
  #
  # @raises [IOError] If the file doesn't exist or can't be read.
  #
  def infer_media_type
    ext = File.extname(self.object_key)
    if ext.present?
      # Add some workarounds for formats that require special handling.
      case ext.downcase
      when '.mp4', '.m4v'
        self.media_type = 'video/mp4'
      when '.mtl'
        self.media_type = 'text/plain'
      when '.obj'
        self.media_type = 'text/plain'
      end
    end
    if self.media_type.blank? or self.media_type == DEFAULT_MEDIA_TYPE
      # Try to infer the media type from the file header.
      begin
        # First, check the Content-Length response header in order to find the
        # end of the requestable range.
        client = MedusaS3Client.instance
        response = client.head_object(
            bucket: MedusaS3Client::BUCKET,
            key: self.object_key)
        end_pos = [20, response.content_length].min
        if end_pos > 2
          response = client.get_object(
              bucket: MedusaS3Client::BUCKET,
              key: self.object_key,
              range: "bytes=0-#{end_pos}")
          self.media_type = MimeMagic.by_magic(response.body)
        end
      rescue => e
        raise IOError, e
      end
      # If that failed, fall back to inferring it from the filename extension.
      if self.media_type.blank? or self.media_type == DEFAULT_MEDIA_TYPE
        self.media_type = MimeMagic.by_extension(ext)&.type
      end
    end
  end

  def is_3d?
    (self.media_category == MediaCategory::THREE_D)
  end

  def is_audio?
    self.media_type and self.media_type.start_with?('audio/')
  end

  def is_document?
    (self.media_category == MediaCategory::DOCUMENT)
  end

  def is_image?
    self.media_type and self.media_type.start_with?('image/')
  end

  ##
  # @return [Boolean] Whether the binary is a video and a version of it resides
  #                   in [UI MediaSpace](https://mediaspace.illinois.edu).
  def is_media_space_video?
    is_video? and self.item&.embed_tag&.include?('kaltura')
  end

  def is_pdf? # TODO: replace with is_document?()
    self.media_type and self.media_type == 'application/pdf'
  end

  ##
  # @return [Boolean] Whether the binary is of a still or moving raster image
  #                   (video) with pixel dimensions.
  #
  def is_raster?
    is_image? or is_video?
  end

  ##
  # @return [Boolean] Whether the binary is plain text.
  #
  def is_text?
    self.media_type and self.media_type.start_with?('text/plain')
  end

  def is_video?
    self.media_type and self.media_type.start_with?('video/')
  end

  ##
  # @return [String, nil] URI of the binary's equivalent Medusa file.
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
  # @return [Enumerable<Hash<Symbol,String>>] Array of hashes with `:label`,
  #                                           `:category`, and `:value` keys.
  # @raises [IOError] If the file is not found or can't be read.
  #
  def metadata
    read_metadata unless @metadata_read
    @metadata
  end

  ##
  # @return [void]
  # @raises [IOError] If the file does not exist.
  #
  def read_characteristics
    read_size
    read_dimensions
    read_duration
  end

  ##
  # Populates the `width` and `height` properties by reading the dimensions
  # from the source image or video.
  #
  # @return [void]
  # @raises [IOError] If the file does not exist.
  #
  def read_dimensions
    if is_image?
      begin
        # Download the image to a temp file.
        tempfile = Tempfile.new('image')
        download_to(tempfile.path, 1024 ** 2)

        # Redirect stderr to /dev/null as there is apparently no other way to
        # suppress "no exif data found in the file" messages.
        output = `exiv2 "#{tempfile.path.gsub('"', '\\"')}" 2> /dev/null`
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
      rescue => e
        raise IOError, e
      ensure
        tempfile.unlink
      end
    elsif is_video?
      # TODO: write this
    end
  end

  ##
  # Populates the duration property by reading it from the source audio or
  # video.
  #
  # This is very, very, VERY expensive as the entire source file has to be
  # downloaded from S3.
  #
  # @return [void]
  # @raises [IOError] If the file does not exist.
  #
  def read_duration
    if is_audio? or is_video?
      tempfile = nil
      begin
        # Download the image to a temp file.
        tempfile = Tempfile.new('image')
        download_to(tempfile.path)

        # Redirect ffprobe stderr output to stdout.
        output = `ffprobe "#{tempfile.path.gsub('"', '\\"')}" 2>&1`
        result = output.match(/Duration: [0-9][0-9]:[0-5][0-9]:[0-5][0-9]/)
        if result and result.length > 0
          begin
            self.duration = TimeUtil.hms_to_seconds(result[0].gsub('Duration: ', ''))
          rescue ArgumentError => e
            LOGGER.warn('read_duration(): %s', e)
          end
        end
      rescue => e
        raise IOError, e
      ensure
        tempfile&.unlink
      end
    end
  end

  ##
  # Reads the binary's embedded metadata.
  #
  # @raises [IOError] If the file does not exist.
  #
  def read_metadata
    @metadata = []

    return unless self.is_image?

    tempfile = nil
    begin
      tempfile = Tempfile.new('image')
      download_to(tempfile.path, 1024 ** 2) # download the first 1 MB

      # exiftool's output is more comprehensive, but as of 2016-09-01, it
      # appears to cause my local machine's condo NFS mount to unmount itself.
      # OTRS ticket filed, but don't want to wait on it. OTOH, exiv2 is faster.
      #
      # 2019 update: since we are no longer using NFS, we could switch back to
      # exiftool if desired. --alexd
      #read_metadata_using_exiftool(pathname)
      read_metadata_using_exiv2(tempfile.path)

      @metadata_read = true
    rescue => e
      raise IOError, e
    ensure
      tempfile&.unlink
    end
  end

  ##
  # Populates the byte_size property.
  #
  # @return [void]
  # @raises [IOError] If the file does not exist.
  #
  def read_size
    begin
      response = MedusaS3Client.instance.head_object(
          bucket: MedusaS3Client::BUCKET,
          key: self.object_key)
      self.byte_size = response.content_length
    rescue => e
      raise IOError, e
    end
  end

  def to_param
    cfs_file_uuid
  end

  ##
  # @return [String] The instance's object key, or its Medusa file UUID, or the
  #                  return value of super -- whichever is present first.
  #
  def to_s
    str = self.object_key
    str = self.cfs_file_uuid if str.blank?
    str = super if str.blank?
    str
  end

  ##
  # @return [String] The URI of the corresponding S3 object.
  #
  def uri
    "s3://#{Configuration.instance.medusa_s3_bucket}/#{self.object_key}"
  end

  private

  def download_to(pathname, length = 0)
    # Use the smaller of the actual length or the requested length.
    read_size if byte_size < 1
    length = [length, byte_size].min

    MedusaS3Client.instance.get_object(
        bucket:          MedusaS3Client::BUCKET,
        key:             self.object_key,
        response_target: pathname,
        range:           (length > 0) ? "bytes=#{0}-#{length}" : nil)
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
      LOGGER.warn('read_metadata(): %s', e)
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
