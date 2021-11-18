##
# Module included by models that can be represented by other objects.
#
# In some public contexts, an image or [Item] is needed to represent a model
# instance. For example, on the show-collection page, it may be desired to
# display an archetypal or notable [Item]. There are three ways of doing this:
#
# 1. Assign an [Item]'s repository ID to the {representative_item_id}
#    attribute. The item's own representative image will be used as the
#    model's representative image. This will also enable some of its metadata
#    (e.g. title) to be displayed nearby.
# 2. Assign a Medusa file's UUID to the {representative_medusa_file_id}
#    attribute. This works similarly to the above except since there is no item
#    information, there can be no metadata displayed alongside the title, nor
#    can the image be hyperlinked to anything itself.
# 3. Upload an image to the application S3 bucket and use that as the
#    representative image. This works similarly to the above, with the same
#    caveats, except it allows more control over the image (cropping, for
#    example) without having to ingest it into Medusa.
#
# The effective representation type (i.e. which one of these strategies is in
# effect) can be accessed via {representation_type}. But the [Representable]
# methods provide a relatively convenient way of accessing the "effective"
# representative item or image.
#
# Representable models must have the following attributes:
#
# * `representative_image`          Filename of a representative image within
#                                   the application S3 bucket. See note about
#                                   representations above.
# * `representative_item_id`        Repository ID of an [Item] designated to
#                                   represent the model. For example, using a
#                                   different item to provide a thumbnail image
#                                   for an item that is not very "photogenic."
# * `representative_medusa_file_id` UUID of an alternative Medusa file
#                                   designated to stand in as a representation
#                                   of the model.
#
module Representable

  ##
  # @return [Representation] Instance of type
  #                          {Representation::Type::LOCAL_FILE} or
  #                          {Representation::Type::MEDUSA_FILE}.
  #
  def effective_file_representation
    raise "Implementations must override #{__method__}"
  end

  ##
  # @return [Representation]
  #
  def effective_representation
    raise "Implementations must override #{__method__}()"
  end

  ##
  # @return [String, nil] Full key of the representative image within the
  #                       application S3 bucket, if one exists; `nil` otherwise.
  #
  def representative_image_key
    representative_image.present? ?
      representative_image_key_prefix + representative_image : nil
  end

  def representative_image_key_prefix
    raise "Implementations must override #{__method__}()"
  end

  ##
  # @return [Item, nil] Item assigned to represent the instance.
  #
  def representative_item
    self.representative_item_id.present? ?
      Item.find_by_repository_id(self.representative_item_id) : nil
  end

  ##
  # @return [Medusa::File, nil] Instance corresponding to
  #                             {representative_medusa_file_id}.
  #
  def representative_medusa_file
    self.representative_medusa_file_id.present? ?
      Medusa::File.with_uuid(self.representative_medusa_file_id) : nil
  end

  ##
  # Writes the given stream to the application S3 bucket under the
  # representative images key prefix, updates the {representative_image}
  # attribute with its new filename, and saves the instance.
  #
  # @param io [IO]           Stream to read.
  # @param filename [String] Uploaded filename. Only the extension will be
  #                          preserved.
  #
  def upload_representative_image(io:, filename:)
    ext = filename.split(".").last.downcase
    unless Representation::SUPPORTED_IMAGE_FORMATS.include?(ext)
      raise ArgumentError, "Unsupported file extension: .#{ext}"
    end

    client = KumquatS3Client.instance
    bucket = KumquatS3Client::BUCKET
    prefix = representative_image_key_prefix

    # Delete any existing objects under the representative image key prefix.
    client.delete_objects(prefix: prefix)

    # Upload the new representative image.
    filename = "#{SecureRandom.hex}.#{ext}"
    client.put_object(bucket: bucket,
                      key:    prefix + filename,
                      body:   io)
    self.update!(representative_image: filename)
  end

end
