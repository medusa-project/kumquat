##
#
#
# @!attribute collection [Collection] Representative collection if the {type}
#                                     is {Representation::Type::COLLECTION}.
# @!attribute file [Medusa::File]     Representative file if the {type} is
#                                     {Representation::Type::MEDUSA_FILE}.
# @!attribute item [Item]             Representative item if the {type} is
#                                     {Representation::Type::ITEM}.
# @!attribute key [String]            S3 key of a representative file if the
#                                     {type} is
#                                     {Representation::Type::LOCAL_FILE}.
# @!attribute type [String]           One of the {Representation::Type}
#                                     constant values.
#
class Representation

  class Type
    COLLECTION  = "collection"
    ITEM        = "item"
    LOCAL_FILE  = "local_file"
    MEDUSA_FILE = "medusa_file"
    SELF        = "self"

    def self.all
      self.constants.map{ |c| self.const_get(c) }
    end
  end

  SUPPORTED_IMAGE_FORMATS = %w(jp2 jpeg jpg png)

  attr_accessor :collection, :file, :key, :item, :type

  ##
  # @return [String] The S3 URL of the {file Medusa file} or {key object key}
  #                  depending on the instance's {type}.
  #
  def url
    case type
    when Type::LOCAL_FILE
      return "s3://#{KumquatS3Client::BUCKET}/#{key}"
    when Type::MEDUSA_FILE
      return "s3://#{MedusaS3Client::BUCKET}/#{file}"
    else
      return nil
    end
  end

end
