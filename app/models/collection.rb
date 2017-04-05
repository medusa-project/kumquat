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

  include AuthorizableByRole
  include Describable
  include SolrQuerying

  class SolrFields
    ACCESS_SYSTEMS = 'access_systems_sim'
    ACCESS_URL = 'access_url_si'
    ALLOWED_ROLES = 'allowed_roles_sim'
    CLASS = 'class_si'
    DENIED_ROLES = 'denied_roles_sim'
    DESCRIPTION = 'description_txti'
    DESCRIPTION_HTML = 'description_html_txti'
    HARVESTABLE = 'harvestable_bi'
    ID = 'id'
    LAST_INDEXED = 'last_indexed_dti'
    METADATA_DESCRIPTION = "#{ItemElement::solr_prefix}description_txti"
    METADATA_TITLE = "#{ItemElement::solr_prefix}title_txti"
    PARENT_COLLECTIONS = 'parent_collections_sim'
    PHYSICAL_COLLECTION_URL = 'physical_collection_url_si'
    PUBLISHED = 'published_bi'
    PUBLISHED_IN_DLS = 'published_in_dls_bi'
    REPOSITORY_TITLE = 'repository_title_si'
    REPRESENTATIVE_IMAGE = 'representative_image_si'
    REPRESENTATIVE_ITEM = 'representative_item_si'
    RESOURCE_TYPES = 'resource_types_sim'
    SEARCH_ALL = 'searchall_natsort_en_im'
    TITLE = 'title_natsort_en_i'
  end

  UUID_REGEX = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

  serialize :access_systems
  serialize :resource_types

  belongs_to :metadata_profile, inverse_of: :collections

  # See CollectionJoin for an explanation of why we don't join on database IDs.
  has_many :child_collection_joins, class_name: 'CollectionJoin',
           primary_key: :repository_id, foreign_key: :parent_repository_id,
           dependent: :destroy
  has_many :children, through: :child_collection_joins,
           source: :child_collection
  has_many :elements, class_name: 'CollectionElement', inverse_of: :collection,
           dependent: :destroy
  has_many :parent_collection_joins, class_name: 'CollectionJoin',
           primary_key: :repository_id, foreign_key: :child_repository_id,
           dependent: :destroy
  has_many :parents, through: :parent_collection_joins,
           source: :parent_collection

  has_and_belongs_to_many :allowed_roles, class_name: 'Role',
                          association_foreign_key: :allowed_role_id
  has_and_belongs_to_many :denied_roles, class_name: 'Role',
                          association_foreign_key: :denied_role_id

  validates_format_of :repository_id,
                      with: UUID_REGEX,
                      message: 'UUID is invalid'
  validate :validate_medusa_uuids

  before_validation :do_before_validation

  # This is commented out because, even though it has to happen, it is
  # potentially very time-consuming. CollectionsController.update() is
  # currently the only means by which collections are updated, so it will
  # invoke this method in a background job.
  #
  #after_update :propagate_host_authorization

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
  # @return [Enumerable<Hash>] Array of hashes with `:name`, `:label`, and `id`
  #                            keys in the order they should appear.
  #
  def self.solr_facet_fields
    [
        { name: SolrFields::REPOSITORY_TITLE, label: 'Repository',
          id: 'pt-repository-facet' },
        { name: SolrFields::RESOURCE_TYPES, label: 'Resource Type',
          id: 'pt-resource-type-facet' },
        { name: SolrFields::ACCESS_SYSTEMS, label: 'Access Systems',
          id: 'pt-access-systems-facet' }
    ]
  end

  ##
  # @param element_name [String] Element to replace.
  # @param replace_values [Enumerable<Hash<Symbol,String>] Enumerable of hashes
  #                                                        with `:string` and
  #                                                        `:uri` keys.
  # @param task [Task] Supply to track progress.
  # @return [void]
  # @raises [ArgumentError]
  #
  def change_item_element_values(element_name, replace_values, task = nil)
    raise ArgumentError, 'replace_values must be an Enumerable' unless
        replace_values.respond_to?(:each)
    ActiveRecord::Base.transaction do
      num_items = self.items.count
      self.items.each_with_index do |item, index|
        item.elements.where(name: element_name).destroy_all
        replace_values.each do |hash|
          hash = hash.symbolize_keys
          item.elements.build(name: element_name,
                              value: hash[:string],
                              uri: hash[:uri])
        end
        item.save!

        if task and index % 10 == 0
          task.update(percent_complete: index / num_items.to_f)
        end
      end
    end
  end

  ##
  # @return [void]
  #
  def delete_from_solr
    Solr.instance.delete(self.solr_id)
  end

  ##
  # Satisfies the AuthorizableByRole module contract.
  #
  alias_method :effective_allowed_roles, :allowed_roles

  ##
  # Satisfies the AuthorizableByRole module contract.
  #
  alias_method :effective_denied_roles, :denied_roles

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

  ##
  # @return [MetadataProfile] The profile assigned to the instance, or the
  #                           default profile if none is assigned.
  def effective_metadata_profile
    self.metadata_profile || MetadataProfile.default
  end

  ##
  # @return [Item]
  #
  def effective_representative_item
    self.representative_item || self # TODO: this is a little weird
  end

  ##
  # @return [void]
  #
  def index_in_solr
    Solr.instance.add(self.to_solr)
  end

  ##
  # @return [ActiveRecord::Relation<Item>] All items in the collection.
  #
  def items
    Item.where(collection_repository_id: self.repository_id)
  end

  ##
  # Requires PostgreSQL.
  #
  # @param options [Hash]
  # @option options [Boolean] :only_undescribed
  # @return [String] Full contents of the collection as a TSV string. Item
  #                  children are included. Ordering, limit, offset, etc. is
  #                  not customizable.
  #
  def items_as_tsv(options = {})
    # We use a PostgreSQL query because going through ActiveRecord (which we
    # used to do via Item.to_tsv() in a loop) is just too slow.
    # N.B. The return value must remain in sync with that of Item.tsv_header().

    element_subselects = []
    self.effective_metadata_profile.elements.each do |ed|
      subselects = []
      ed.vocabularies.sort{ |v| v.key <=> v.key }.each do |vocab|
        vocab_id = (vocab == Vocabulary.uncontrolled) ?
            "IS NULL OR entity_elements.vocabulary_id = #{Vocabulary.uncontrolled.id}" : "= #{vocab.id}"
        subselects << "          array_to_string(
            array(
              SELECT replace(replace(coalesce(value, '') || '#{Item::TSV_URI_VALUE_SEPARATOR}<' || coalesce(uri, '') || '>', '#{Item::TSV_URI_VALUE_SEPARATOR}<>', ''), '||#{Item::TSV_URI_VALUE_SEPARATOR}', '')
              FROM entity_elements
              WHERE entity_elements.item_id = items.id
                AND (entity_elements.vocabulary_id #{vocab_id})
                AND entity_elements.name = '#{ed.name}'
                AND (value IS NOT NULL OR uri IS NOT NULL)
                AND (length(value) > 0 OR length(uri) > 0)
            ), '#{Item::TSV_MULTI_VALUE_SEPARATOR}') AS #{vocab.key}_#{ed.name}"
      end
      element_subselects << subselects.join(",\n") if subselects.any?
    end
    element_subselects = element_subselects.join(",\n")

    sql = "SELECT * FROM (
      SELECT items.repository_id,
        items.parent_repository_id,
        (SELECT repository_relative_pathname
          FROM binaries
          WHERE binaries.item_id = items.id
            AND binaries.master_type = #{Binary::Type::PRESERVATION_MASTER}
          LIMIT 1) AS pres_pathname,
        (SELECT substring(repository_relative_pathname from '[^/]+$')
          FROM binaries
          WHERE binaries.item_id = items.id
            AND binaries.master_type = #{Binary::Type::PRESERVATION_MASTER}
          LIMIT 1) AS pres_filename,
        (SELECT repository_relative_pathname
          FROM binaries
          WHERE binaries.item_id = items.id
            AND binaries.master_type = #{Binary::Type::ACCESS_MASTER}
          LIMIT 1) AS access_pathname,
        (SELECT substring(repository_relative_pathname from '[^/]+$')
          FROM binaries
          WHERE binaries.item_id = items.id
            AND binaries.master_type = #{Binary::Type::ACCESS_MASTER}
          LIMIT 1) AS access_filename,
        items.variant,
        items.page_number,
        items.subpage_number,
        items.latitude,
        items.longitude,
        items.contentdm_alias,
        items.contentdm_pointer,
        (SELECT COUNT(id)
          FROM entity_elements
          WHERE entity_elements.item_id = items.id
            AND entity_elements.name != 'title') AS non_title_count,
        #{element_subselects}
      FROM items
      WHERE items.collection_repository_id = $1
      ORDER BY
        case
          when items.parent_repository_id IS NULL then
            items.repository_id
          else
            items.parent_repository_id
        end,
        items.page_number, items.subpage_number, pres_pathname NULLS FIRST
    ) a\n"

    # If we are supposed to include only undescribed items, consider items
    # that have no elements or only a title element undescribed. (DLD-26)
    if options[:only_undescribed]
      sql += "      WHERE non_title_count < 1"
    end

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
                    Configuration.instance.medusa_url.chomp('/'),
                    self.repository_id,
                    format)
    end
    url
  end

  ##
  # @param source_element [String] Element name.
  # @param dest_element [String] Element name.
  # @param task [Task] Supply to receive progress updates.
  # @return [void]
  # @raises [ArgumentError]
  #
  def migrate_item_elements(source_element, dest_element, task = nil)
    # Check that the destination element is present in the instance's
    # metadata profile.
    source_def = self.metadata_profile.elements.
        select{ |e| e.name == source_element }.first
    dest_def = self.metadata_profile.elements.
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
      num_items = self.items.count
      self.items.each_with_index do |item, index|
        item.migrate_elements(source_element, dest_element)

        if task and index % 10 == 0
          task.update(percent_complete: index / num_items.to_f)
        end
      end
    end
  end

  ##
  # @return [Integer] Number of items in the collection regardless of hierarchy
  #                   level or public accessibility.
  #
  def num_items
    @num_items = Item.solr.
        where(Item::SolrFields::COLLECTION => self.repository_id).count unless @num_items
    @num_items
  end

  ##
  # @return [Integer] Number of objects in the collection. The result is cached.
  #
  def num_objects
    unless @num_objects
      case self.package_profile
        when PackageProfile::FREE_FORM_PROFILE
          query = Item.solr.
              where(Item::SolrFields::COLLECTION => self.repository_id).
              where(Item::SolrFields::VARIANT => Item::Variants::FILE)
        else
          query = Item.solr.
              where(Item::SolrFields::COLLECTION => self.repository_id).
              where(Item::SolrFields::PARENT_ITEM => :null)
      end
      @num_objects = query.count
    end
    @num_objects
  end

  ##
  # @return [Integer] Number of public objects in the collection.
  #                   The result is cached.
  #
  def num_public_objects
    unless @num_public_objects
      case self.package_profile
        when PackageProfile::FREE_FORM_PROFILE
          query = Item.solr.
              where(Item::SolrFields::COLLECTION => self.repository_id).
              where(Item::SolrFields::PUBLISHED => true).
              where(Item::SolrFields::DESCRIBED => true).
              where(Item::SolrFields::COLLECTION_PUBLISHED => true).
              where(Item::SolrFields::VARIANT => Item::Variants::FILE)
        else
          query = Item.solr.
              where(Item::SolrFields::COLLECTION => self.repository_id).
              where(Item::SolrFields::PUBLISHED => true).
              where(Item::SolrFields::DESCRIBED => true).
              where(Item::SolrFields::COLLECTION_PUBLISHED => true).
              where(Item::SolrFields::PARENT_ITEM => :null)
      end
      @num_public_objects = query.count
    end
    @num_public_objects
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

  ##
  # Propagates allowed and denied roles from the instance to all of its items.
  # This is an O(n) operation.
  #
  # @param task [Task] Supply to receive progress updates.
  # @return [void]
  #
  def propagate_roles(task = nil)
    ActiveRecord::Base.transaction do
      # Save callbacks will call this method on direct children, so there is
      # no need to crawl deeper levels of the item tree.
      num_items = self.items.count
      self.items.where(parent_repository_id: nil).each_with_index do |item, index|
        item.save!

        if task and index % 10 == 0
          task.update(percent_complete: index / num_items.to_f)
        end
      end
    end
  end

  ##
  # @param matching_mode [Symbol] :exact_match, :contain, :start, or :end
  # @param find_value [String] Value to search for.
  # @param element_name [String] Element in which to search.
  # @param replace_mode [Symbol] What part of the matches to replace:
  #                              :whole_value or :matched_part
  # @param replace_value [String] Value to replace the matches with.
  # @param task [Task] Supply to receive status updates.
  # @return [void]
  # @raises [ArgumentError]
  #
  def replace_item_element_values(matching_mode, find_value, element_name,
                                  replace_mode, replace_value, task = nil)
    ActiveRecord::Base.transaction do
      num_items = self.items.count
      self.items.each_with_index do |item, index|
        item.elements.where(name: element_name).each do |element|
          case matching_mode
            when :exact_match
              if element.value == find_value
                element.value = replace_value
                element.save!
              end
            when :contain
              if element.value&.include?(find_value)
                case replace_mode
                  when :whole_value
                    element.value = replace_value
                  when :matched_part
                    element.value.gsub!(find_value, replace_value)
                  else
                    raise ArgumentError, "Illegal replace mode: #{replace_mode}"
                end
                element.save!
              end
            when :start
              if element.value&.start_with?(find_value)
                case replace_mode
                  when :whole_value
                    element.value = replace_value
                  when :matched_part
                    element.value.gsub!(find_value, replace_value)
                  else
                    raise ArgumentError, "Illegal replace mode: #{replace_mode}"
                end
                element.save!
              end
            when :end
              if element.value&.end_with?(find_value)
                case replace_mode
                  when :whole_value
                    element.value = replace_value
                  when :matched_part
                    element.value.gsub!(find_value, replace_value)
                  else
                    raise ArgumentError, "Illegal replace mode: #{replace_mode}"
                end
                element.save!
              end
            else
              raise ArgumentError, "Illegal matching mode: #{matching_mode}"
          end

          if task and index % 10 == 0
            task.update(percent_complete: index / num_items.to_f)
          end
        end
      end
    end
  end

  ##
  # @return [Binary,nil] Best representative image binary based on the
  #                      representative item set in Medusa, if available, or
  #                      the representative image, if not.
  #
  def representative_image_binary
    binary = nil
    if self.representative_item
      item = self.representative_item
      binary = item.iiif_image_binary
    elsif self.representative_image.present?
      cfs_file = MedusaCfsFile.new
      cfs_file.uuid = self.representative_image
      binary = Binary.new
      binary.cfs_file_uuid = cfs_file.uuid
      binary.repository_relative_pathname = cfs_file.repository_relative_pathname
      binary.infer_media_type
    end
    binary
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
    doc[SolrFields::ALLOWED_ROLES] = self.allowed_roles.map(&:key)
    doc[SolrFields::CLASS] = self.class.to_s
    doc[SolrFields::DENIED_ROLES] = self.denied_roles.map(&:key)
    doc[SolrFields::LAST_INDEXED] = Time.now.utc.iso8601
    doc[SolrFields::ACCESS_SYSTEMS] = self.access_systems
    doc[SolrFields::ACCESS_URL] = self.access_url
    doc[SolrFields::DESCRIPTION] = self.description
    doc[SolrFields::DESCRIPTION_HTML] = self.description_html
    doc[SolrFields::HARVESTABLE] = self.harvestable

    # Copy description and title into a "metadata" field in order to have Solr
    # copy them into a searchall field.
    doc[SolrFields::METADATA_DESCRIPTION] = self.description
    doc[SolrFields::METADATA_TITLE] = self.title

    # TODO: this won't work with unpersisted CollectionJoins
    #doc[SolrFields::PARENT_COLLECTIONS] = self.parents.map(&:repository_id)
    doc[SolrFields::PARENT_COLLECTIONS] =
        self.parent_collection_joins.map(&:parent_repository_id)
    doc[SolrFields::PHYSICAL_COLLECTION_URL] = self.physical_collection_url
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
    client = MedusaClient.new
    response = client.get(self.medusa_url('json'))
    json_str = response.body
    begin
      struct = JSON.parse(json_str)
    rescue JSON::ParserError => e
      if e.message.include?('UUID not found')
        raise ActiveRecord::RecordNotFound, self.repository_id
      end
      raise e
    end

    ActiveRecord::Base.transaction do
      self.elements.destroy_all

      self.access_systems = struct['access_systems'].map{ |t| t['name'] }
      self.access_url = struct['access_url']
      if struct['description'].present?
        self.elements.build(name: 'description', value: struct['description'])
      end
      self.description_html = struct['description_html']
      self.medusa_repository_id = struct['repository_path'].gsub(/[^0-9+]/, '').to_i
      self.physical_collection_url = struct['physical_collection_url']
      self.published = struct['publish']
      self.representative_image = struct['representative_image']
      self.representative_item_id = struct['representative_item']
      self.resource_types = struct['resource_types'].map do |t| # titleize these
        t['name'].split(' ').map{ |t| t.present? ? t.capitalize : '' }.join(' ')
      end
      self.rights_statement = struct['rights']['custom_copyright_statement']
      self.elements.build(name: 'title', value: struct['title'])

      self.parents.destroy_all
      struct['parent_collections'].each do |parent_struct|
        self.parent_collection_joins.build(parent_repository_id: parent_struct['uuid'],
                                           child_repository_id: self.repository_id)
      end

      self.children.destroy_all
      struct['child_collections'].each do |child_struct|
        self.child_collection_joins.build(parent_repository_id: self.repository_id,
                                          child_repository_id: child_struct['uuid'])
      end

      self.save!
    end
  end

  private

  def do_before_validation
    self.medusa_cfs_directory_id&.strip!
    self.medusa_file_group_id&.strip!
    self.representative_image&.strip!
    self.representative_item_id&.strip!
  end

  def validate_medusa_uuids
    client = MedusaClient.new
    if self.medusa_file_group_id.present? and
        self.medusa_file_group_id_changed? and
        client.class_of_uuid(self.medusa_file_group_id) != MedusaFileGroup
      errors.add(:medusa_file_group_id, 'is not a Medusa file group UUID')
    end
    if self.medusa_cfs_directory_id.present? and
        self.medusa_cfs_directory_id_changed? and
        client.class_of_uuid(self.medusa_cfs_directory_id) != MedusaCfsDirectory
      errors.add(:medusa_cfs_directory_id, 'is not a Medusa directory UUID')
    end
  end

end
