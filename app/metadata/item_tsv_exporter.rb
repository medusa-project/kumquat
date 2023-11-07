##
# Exports various sets of items to TSV format.
#
class ItemTsvExporter

  LINE_BREAK            = "\n"
  MULTI_VALUE_SEPARATOR = '||'
  URI_VALUE_SEPARATOR   = '&&'

  ##
  # @param items [Enumerable<Item>] Should all be in the same collection.
  # @return [String] The given items as a TSV string.
  #
  def items(items)
    # N.B.: The return value must remain in sync with that of
    # Item.tsv_columns().
    metadata_profile = items.first.collection.effective_metadata_profile
    ids = items.map(&:id).join(',')
    sql = select_clause(metadata_profile) +
      from_clause +
      "WHERE items.id IN (#{ids}) " +
      order_clause +
      ") a\n"

    io = StringIO.new
    io << Item.tsv_columns(metadata_profile).join("\t")
    io << LINE_BREAK
    ActiveRecord::Base.connection.exec_query(sql, 'SQL').each do |row|
      io << row.values.join("\t")
      io << LINE_BREAK
    end
    io.string
  end

  ##
  # Requires PostgreSQL.
  #
  # @param collection [Collection]
  # @param only_undescribed [Boolean]
  # @param published_after [Time]
  # @param published_before [Time]
  # @return [String] Full contents of the collection as a TSV string. Item
  #                  children are included. Ordering, limit, offset, etc. is
  #                  not customizable.
  #
  def items_in_collection(collection,
                          only_undescribed: false,
                          published_after: nil,
                          published_before: nil)
    # N.B.: The return value must remain in sync with that of
    # Item.tsv_columns().
    metadata_profile = collection.effective_metadata_profile
    sql = StringIO.new
    sql << select_clause(metadata_profile)
    sql << from_clause
    sql << 'WHERE items.collection_repository_id = $1 '
    sql <<   'AND items.published_at > $2 ' if published_after
    sql <<   'AND items.published_at < $3 ' if published_before
    sql << order_clause
    sql << ") a\n"

    # If we are supposed to include only undescribed items, consider items
    # that have no elements or only a title element undescribed. (DLD-26)
    sql << '      WHERE non_title_count < 1' if only_undescribed

    values = [collection.repository_id]
    values << published_after if published_after
    values << published_before if published_before

    tsv = StringIO.new
    tsv << Item.tsv_columns(metadata_profile).join("\t")
    tsv << LINE_BREAK
    ActiveRecord::Base.connection.exec_query(sql.string, 'SQL', values).each do |row|
      tsv << row.values.join("\t")
      tsv << LINE_BREAK
    end
    tsv.string
  end

  ##
  # Requires PostgreSQL.
  #
  # @param item_set [ItemSet]
  # @return [String] Full contents of the collection as a TSV string. Item
  #                  children are included. Ordering, limit, offset, etc. is
  #                  not customizable.
  #
  def items_in_item_set(item_set)
    # N.B.: The return value must remain in sync with that of
    # Item.tsv_columns().
    metadata_profile = item_set.collection.effective_metadata_profile
    sql = select_clause(metadata_profile) +
        from_clause +
        'LEFT JOIN item_sets_items ON item_sets_items.item_id = items.id ' +
        'WHERE item_sets_items.item_set_id = $1 ' +
        order_clause +
        ") a\n"
    values = [item_set.id]

    io = StringIO.new
    io << Item.tsv_columns(metadata_profile).join("\t")
    io << LINE_BREAK
    ActiveRecord::Base.connection.exec_query(sql, 'SQL', values).each do |row|
      io << row.values.join("\t")
      io << LINE_BREAK
    end
    io.string
  end

  private

  def select_clause(metadata_profile)
    element_subselects = []
    if metadata_profile
      metadata_profile.elements.each do |ed|
        subselects = []
        ed.vocabularies.sort{ |v| v.key <=> v.key }.each do |vocab|
          vocab_id = (vocab == Vocabulary.uncontrolled) ?
                         "IS NULL OR entity_elements.vocabulary_id = #{Vocabulary.uncontrolled.id}" : "= #{vocab.id}"
          subselects << "          array_to_string(
              array(
                SELECT replace(replace(coalesce(value, '') || '#{URI_VALUE_SEPARATOR}<' || coalesce(uri, '') || '>', '#{URI_VALUE_SEPARATOR}<>', ''), '||#{URI_VALUE_SEPARATOR}', '')
                FROM entity_elements
                WHERE entity_elements.item_id = items.id
                  AND (entity_elements.vocabulary_id #{vocab_id})
                  AND entity_elements.name = '#{ed.name}'
                  AND (value IS NOT NULL OR uri IS NOT NULL)
                  AND (length(value) > 0 OR length(uri) > 0)
              ), '#{MULTI_VALUE_SEPARATOR}') AS #{vocab.key}_#{ed.name}"
        end
        element_subselects << subselects.join(",\n") if subselects.any?
      end
    end
    element_subselects = element_subselects.any? ?
                             ',' + element_subselects.join(",\n") : ''

    "SELECT * FROM (
      SELECT items.repository_id,
        items.parent_repository_id,
        (SELECT array_to_string(
          array(
            SELECT DISTINCT object_key
            FROM binaries
            WHERE binaries.item_id = items.id
              AND binaries.master_type = #{Binary::MasterType::PRESERVATION}
            ORDER BY object_key
          ), '#{MULTI_VALUE_SEPARATOR}')) AS pres_pathname,
        (SELECT array_to_string(
          array(
            SELECT substring(object_key from '[^/]+$')
            FROM binaries
            WHERE binaries.item_id = items.id
              AND binaries.master_type = #{Binary::MasterType::PRESERVATION}
            ORDER BY object_key
          ), '#{MULTI_VALUE_SEPARATOR}')) AS pres_filename,
        (SELECT array_to_string(
          array(
            SELECT medusa_uuid
            FROM binaries
            WHERE binaries.item_id = items.id
              AND binaries.master_type = #{Binary::MasterType::PRESERVATION}
            ORDER BY object_key
          ), '#{MULTI_VALUE_SEPARATOR}')) AS pres_uuid,
        (SELECT array_to_string(
          array(
            SELECT DISTINCT object_key
            FROM binaries
            WHERE binaries.item_id = items.id
              AND binaries.master_type = #{Binary::MasterType::ACCESS}
            ORDER BY object_key
          ), '#{MULTI_VALUE_SEPARATOR}')) AS access_pathname,
        (SELECT array_to_string(
          array(
            SELECT substring(object_key from '[^/]+$')
            FROM binaries
            WHERE binaries.item_id = items.id
              AND binaries.master_type = #{Binary::MasterType::ACCESS}
            ORDER BY object_key
          ), '#{MULTI_VALUE_SEPARATOR}')) AS access_filename,
        (SELECT array_to_string(
          array(
            SELECT medusa_uuid
            FROM binaries
            WHERE binaries.item_id = items.id
              AND binaries.master_type = #{Binary::MasterType::ACCESS}
            ORDER BY object_key
          ), '#{MULTI_VALUE_SEPARATOR}')) AS access_uuid,
        items.variant,
        items.page_number,
        items.subpage_number,
        items.published,
        items.contentdm_alias,
        items.contentdm_pointer,
        (SELECT COUNT(id)
          FROM entity_elements
          WHERE entity_elements.item_id = items.id
            AND entity_elements.name != 'title') AS non_title_count
        #{element_subselects} "
  end

  def from_clause
    ' FROM items '
  end

  def order_clause
    'ORDER BY
        case
          when items.parent_repository_id IS NULL then
            items.repository_id
          else
            items.parent_repository_id
        end NULLS FIRST,
        items.page_number NULLS FIRST, items.subpage_number NULLS FIRST,
        pres_pathname NULLS FIRST '
  end

end