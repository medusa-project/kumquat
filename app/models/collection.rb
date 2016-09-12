##
# Encapsulates a Medusa collection.
#
# Collections are identified by their repository ID (`repository_id`), which
# is a UUID matching a collection's Medusa UUID.
#
# Collections can "contain" zero or more items. (This is a weak relationship;
# the collections don't literally contain them, but items maintain a reference
# to their owning collection's repository ID.)
#
# Collections are associated with a metadata profile, which defines the list
# of elements that contained items are supposed to have, as well as a package
# profile, which defines how collection content is structured in Medusa in
# terms of its file/directory layout.
#
# Being an ActiveRecord entity, collections are searchable via ActiveRecord as
# well as via Solr. Instances are automatically indexed in Solr (see `to_solr`)
# in an after_commit callback, and the Solr search functionality is available
# via the `solr` class method.
#
class Collection < ActiveRecord::Base

  include SolrQuerying

  class SolrFields
    ACCESS_SYSTEMS = 'access_systems_sim'
    ACCESS_URL = 'access_url_si'
    CLASS = 'class_si'
    DESCRIPTION = 'description_txti'
    DESCRIPTION_HTML = 'description_html_txti'
    ID = 'id'
    LAST_INDEXED = 'last_indexed_dti'
    PUBLISHED = 'published_bi'
    PUBLISHED_IN_DLS = 'published_in_dls_bi'
    REPOSITORY_TITLE = 'repository_title_si'
    REPRESENTATIVE_IMAGE = 'representative_image_si'
    REPRESENTATIVE_ITEM = 'representative_item_si'
    RESOURCE_TYPES = 'resource_types_sim'
    SEARCH_ALL = 'searchall_txtim'
    TITLE = 'title_natsort_en_i'
  end

  UUID_REGEX = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

  serialize :access_systems
  serialize :resource_types

  belongs_to :metadata_profile, inverse_of: :collections
  has_many :element_defs, inverse_of: :collection

  validates_format_of :medusa_cfs_directory_id,
                      with: UUID_REGEX,
                      message: 'UUID is invalid',
                      allow_blank: true
  validates_format_of :medusa_file_group_id,
                      with: UUID_REGEX,
                      message: 'UUID is invalid',
                      allow_blank: true
  validates_format_of :repository_id,
                      with: UUID_REGEX,
                      message: 'UUID is invalid'

  before_validation :do_before_validation

  after_commit :index_in_solr, on: [:create, :update]
  after_commit :delete_from_solr, on: :destroy

  ##
  # @param id [Integer] Medusa collection ID
  # @return [Collection]
  #
  def self.from_medusa(id)
    col = Collection.new
    col.repository_id = id
    col.update_from_medusa
    col
  end

  ##
  # @return [Array<Hash>] Array of hashes with `:name` and `:label` keys
  #
  def self.solr_facet_fields
    # These should be defined in the order they should appear.
    [
        # IMET-283 says Access Systems should appear first.
        { name: SolrFields::ACCESS_SYSTEMS, label: 'Access Systems' },
        { name: SolrFields::RESOURCE_TYPES, label: 'Resource Type' },
        { name: SolrFields::REPOSITORY_TITLE, label: 'Repository' }
    ]
  end

  ##
  # @return [PackageProfile,nil]
  #
  def package_profile
    self.package_profile_id.present? ?
        PackageProfile.find(self.package_profile_id) : nil
  end

  ##
  # @param profile [PackageProfile]
  #
  def package_profile=(profile)
    self.package_profile_id = profile.kind_of?(PackageProfile) ?
        profile.id : nil
  end

  def delete_from_solr
    Solr.instance.delete(self.solr_id)
  end

  ##
  # The effective CFS directory of the instance -- either one that is directly
  # assigned, or the root CFS directory of the file group.
  #
  # @return [MedusaCfsDirectory, nil]
  # @see medusa_cfs_directory
  #
  def effective_medusa_cfs_directory
    self.medusa_cfs_directory || self.medusa_file_group&.cfs_directory
  end

  def effective_metadata_profile
    self.metadata_profile || MetadataProfile.default
  end

  def index_in_solr
    Solr.instance.add(self.to_solr)
  end

  ##
  # @return [ActiveRecord::Relation<Item>]
  #
  def items
    Item.where(collection_repository_id: self.repository_id)
  end

  ##
  # Requires PostgreSQL.
  #
  # @return [String] Full contents of the collection as a TSV string. Item
  #                  children are included. Ordering, limit, offset, etc. is
  #                  not customizable.
  #
  def items_as_tsv
    # N.B. The return value must remain synchronized with that of
    # Item.tsv_header().
    # We use a native PostgreSQL query because going through ActiveRecord is
    # just too slow.
=begin
SELECT items.repository_id,
  items.parent_repository_id,
  (SELECT repository_relative_pathname
    FROM bytestreams
    WHERE bytestreams.item_id = items.id
      AND bytestreams.bytestream_type = 0) AS pres_pathname,
  (SELECT repository_relative_pathname
    FROM bytestreams
    WHERE bytestreams.item_id = items.id
      AND bytestreams.bytestream_type = 1) AS access_pathname,
  items.variant,
  items.page_number,
  items.subpage_number,
  items.latitude,
  items.longitude,
  items.contentdm_alias,
  items.contentdm_pointer,
  array_to_string(
    array(
      SELECT replace(replace(coalesce(value, '') || '&&<' || coalesce(uri, '') || '>', '&&<>', ''), '||&&', '')
        FROM item_elements
        WHERE item_elements.item_id = items.id
          AND (item_elements.vocabulary_id IS NULL OR item_elements.vocabulary_id = 11)
          AND item_elements.name = 'subject'
          AND (value IS NOT NULL OR uri IS NOT NULL)
          AND (length(value) > 0 OR length(uri) > 0)
    ), '||') AS uncontrolled_subject,
  array_to_string(
    array(
      SELECT replace(replace(coalesce(value, '') || '&&<' || coalesce(uri, '') || '>', '&&<>', ''), '||&&', '')
        FROM item_elements
        WHERE item_elements.item_id = items.id
          AND (item_elements.vocabulary_id = XX)
          AND item_elements.name = 'subject'
          AND (value IS NOT NULL OR uri IS NOT NULL)
          AND (length(value) > 0 OR length(uri) > 0)
    ), '||') AS lcsh_subject
FROM items
WHERE items.collection_repository_id = '8132f520-e3fb-012f-c5b6-0019b9e633c5-f'
ORDER BY
  case
    when items.parent_repository_id IS NULL then
      items.repository_id
    else
      items.parent_repository_id
  end, items.page_number, items.subpage_number, pres_pathname NULLS FIRST
LIMIT 1000;
=end
    element_subselects = self.effective_metadata_profile.element_defs.map do |ed|
      subselects = []
      ed.vocabularies.sort{ |v| v.key <=> v.key }.each do |vocab|
        vocab_id = (vocab == Vocabulary.uncontrolled) ?
            "IS NULL OR item_elements.vocabulary_id = #{Vocabulary.uncontrolled.id}" : "= #{vocab.id}"
        subselects << "array_to_string(
            array(
              SELECT replace(replace(coalesce(value, '') || '#{Item::TSV_URI_VALUE_SEPARATOR}<' || coalesce(uri, '') || '>', '#{Item::TSV_URI_VALUE_SEPARATOR}<>', ''), '||#{Item::TSV_URI_VALUE_SEPARATOR}', '')
              FROM item_elements
              WHERE item_elements.item_id = items.id
                AND (item_elements.vocabulary_id #{vocab_id})
                AND item_elements.name = '#{ed.name}'
                AND (value IS NOT NULL OR uri IS NOT NULL)
                AND (length(value) > 0 OR length(uri) > 0)
            ), '#{Item::TSV_MULTI_VALUE_SEPARATOR}') AS #{vocab.key}_#{ed.name}"
      end
      subselects.join(",\n")
    end

    sql = "SELECT items.repository_id,
      items.parent_repository_id,
      (SELECT repository_relative_pathname
        FROM bytestreams
        WHERE bytestreams.item_id = items.id
          AND bytestreams.bytestream_type = #{Bytestream::Type::PRESERVATION_MASTER})
            AS pres_pathname,
      (SELECT repository_relative_pathname
        FROM bytestreams
        WHERE bytestreams.item_id = items.id
          AND bytestreams.bytestream_type = #{Bytestream::Type::ACCESS_MASTER})
            AS access_pathname,
      items.variant,
      items.page_number,
      items.subpage_number,
      items.latitude,
      items.longitude,
      items.contentdm_alias,
      items.contentdm_pointer,
      #{element_subselects.join(",\n")}
    FROM items
    WHERE items.collection_repository_id = $1
    ORDER BY
      case
        when items.parent_repository_id IS NULL then
          items.repository_id
        else
          items.parent_repository_id
      end, items.page_number, items.subpage_number, pres_pathname NULLS FIRST"

    values = [[ nil, self.repository_id ]]

    tsv = Item.tsv_header(self.effective_metadata_profile)
    ActiveRecord::Base.connection.exec_query(sql, 'SQL', values).each do |row|
      tsv += row.values.join("\t") + Item::TSV_LINE_BREAK
    end
    tsv
  end

  ##
  # The CFS directory in which content resides. This may be the same as the
  # root CFS directory of the file group, or deeper within it. This is used
  # as a refinement of medusa_file_group.
  #
  # @return [MedusaCfsDirectory, nil]
  # @see effective_medusa_cfs_directory
  #
  def medusa_cfs_directory
    unless @cfs_directory
      @cfs_directory = nil
      if self.medusa_cfs_directory_id.present?
        @cfs_directory = MedusaCfsDirectory.new
        @cfs_directory.uuid = self.medusa_cfs_directory_id
      end
    end
    @cfs_directory
  end

  ##
  # @return [MedusaFileGroup]
  #
  def medusa_file_group
   unless @file_group
     @file_group = nil
     if self.medusa_file_group_id
       @file_group = MedusaFileGroup.new
       @file_group.uuid = self.medusa_file_group_id
     end
   end
   @file_group
  end

  ##
  # @return [MedusaRepository]
  #
  def medusa_repository
    unless @medusa_repository
      @medusa_repository = nil
      if self.medusa_repository_id
        @medusa_repository = MedusaRepository.new
        @medusa_repository.id = self.medusa_repository_id
      end
    end
    @medusa_repository
  end

  ##
  # @param format [String] URL extension like `json`
  # @return [String] Absolute URI of the Medusa collection resource, or nil
  #                  if the instance does not have an ID.
  #
  def medusa_url(format = nil)
    format = format.present? ? ".#{format.to_s.gsub('.', '')}" : ''
    url = nil
    if self.repository_id
      url = sprintf('%s/uuids/%s%s',
                    PearTree::Application.peartree_config[:medusa_url].chomp('/'),
                    self.repository_id,
                    format)
    end
    url
  end

  ##
  # @param source_element [String] Element name
  # @param dest_element [String] Element name
  # @return [void]
  # @raises [ArgumentError]
  #
  def migrate_item_elements(source_element, dest_element)
    # Check that the destination element is present in the instance's
    # metadata profile.
    source_def = self.metadata_profile.element_defs.
        select{ |e| e.name == source_element }.first
    dest_def = self.metadata_profile.element_defs.
        select{ |e| e.name == dest_element }.first
    unless dest_def
      raise ArgumentError, "#{dest_element} element is not present in the "\
          "metadata profile."
    end

    # Check that the source and destination element have the same vocabularies.
    source_vocabs = source_def.vocabularies.map(&:key).uniq
    dest_vocabs = dest_def.vocabularies.map(&:key).uniq
    if source_vocabs != dest_vocabs
      raise ArgumentError, 'Source and destination elements have different '\
          'assigned vocabularies.'
    end

    ActiveRecord::Base.transaction do
      self.items.each do |item|
        item.migrate_elements(source_element, dest_element)
      end
    end
  end

  ##
  # @return [Integer]
  #
  def num_items
    @num_items = Item.solr.where(Item::SolrFields::COLLECTION => self.repository_id).count unless @num_items
    @num_items
  end

  ##
  # @return [Integer]
  #
  def num_top_items
    @num_top_items = Item.solr.where(Item::SolrFields::COLLECTION => self.repository_id).
        where(Item::SolrFields::PARENT_ITEM => :null).count unless @num_top_items
    @num_top_items
  end

  ##
  # @return [Bytestream,nil] Best representative image bytestream based on the
  #                          representative item set in Medusa, if available,
  #                          or the representative image, if not.
  #
  def representative_image_bytestream
    bs = nil
    if self.representative_item
      item = self.representative_item
      bs = item.access_master_bytestream || item.preservation_master_bytestream
    elsif self.representative_image.present?
      cfs_file = MedusaCfsFile.new
      cfs_file.uuid = self.representative_image
      bs = Bytestream.new
      bs.cfs_file_uuid = cfs_file.uuid
      bs.repository_relative_pathname = cfs_file.repository_relative_pathname
      bs.infer_media_type
    end
    bs
  end

  def representative_item
    item = nil
    if self.representative_item_id.present?
      item = Item.find_by_repository_id(self.representative_item_id)
    end
    item
  end

  ##
  # @return [RightsStatement, nil]
  #
  def rightsstatements_org_statement
    RightsStatement.for_uri(self.rightsstatements_org_uri)
  end

  def solr_id
    self.repository_id
  end

  def to_param
    self.repository_id
  end

  def to_s
    self.title
  end

  ##
  # @return [Hash]
  #
  def to_solr
    doc = {}
    doc[SolrFields::ID] = self.solr_id
    doc[SolrFields::CLASS] = self.class.to_s
    doc[SolrFields::LAST_INDEXED] = Time.now.utc.iso8601
    doc[SolrFields::ACCESS_SYSTEMS] = self.access_systems
    doc[SolrFields::ACCESS_URL] = self.access_url
    doc[SolrFields::DESCRIPTION] = self.description
    doc[SolrFields::DESCRIPTION_HTML] = self.description_html
    doc[SolrFields::PUBLISHED] = self.published
    doc[SolrFields::PUBLISHED_IN_DLS] = self.published_in_dls
    doc[SolrFields::REPOSITORY_TITLE] = self.medusa_repository&.title
    doc[SolrFields::REPRESENTATIVE_ITEM] = self.representative_item_id
    doc[SolrFields::RESOURCE_TYPES] = self.resource_types
    doc[SolrFields::TITLE] = self.title
    doc
  end

  ##
  # @return [void]
  # @raises [ActiveRecord::RecordNotFound]
  #
  def update_from_medusa
    unless self.repository_id
      raise ActiveRecord::RecordNotFound,
            'update_from_medusa() called without repository_id set'
    end
    response = Medusa.client.get(self.medusa_url('json'),
                                 follow_redirect: true)
    json_str = response.body
    struct = JSON.parse(json_str)

    self.access_systems = struct['access_systems'].map{ |t| t['name'] }
    self.access_url = struct['access_url']
    self.description = struct['description']
    self.description_html = struct['description_html']
    self.medusa_repository_id = struct['repository_path'].gsub(/[^0-9+]/, '').to_i
    self.published = struct['publish']
    self.representative_image = struct['representative_image']
    self.representative_item_id = struct['representative_item']
    self.resource_types = struct['resource_types'].map do |t| # titleize these
      t['name'].split(' ').map{ |t| t.present? ? t.capitalize : '' }.join(' ')
    end
    self.rights_statement = struct['rights']['custom_copyright_statement']
    self.title = struct['title']
  end

  private

  def do_before_validation
    self.medusa_cfs_directory_id&.strip!
    self.medusa_file_group_id&.strip!
    self.representative_item_id&.strip!
  end

end
