##
# Exports sets of collections to TSV format.
#
class CollectionTsvExporter

  LINE_BREAK            = ItemTsvExporter::LINE_BREAK
  MULTI_VALUE_SEPARATOR = ItemTsvExporter::MULTI_VALUE_SEPARATOR
  URI_VALUE_SEPARATOR   = ItemTsvExporter::URI_VALUE_SEPARATOR

  ##
  # @param collection_uuids [Enumerable<String>] Enumerable of collection
  #                                              UUIDs.
  # @return [String] The given collections as a TSV string.
  #
  def collections(collection_uuids)
    # N.B.: The return value must remain in sync with that of
    # Collection::TSV_COLUMNS.
    ids = collection_uuids.map{ |id| "'#{id}'" }.join(',')
    sql = select_clause +
      from_clause +
      "WHERE collections.repository_id IN (#{ids}) " +
      order_clause +
      ") a\n"
    io = StringIO.new
    io << Collection::TSV_COLUMNS.join("\t")
    io << LINE_BREAK
    ActiveRecord::Base.connection.exec_query(sql, 'SQL').each do |row|
      io << row.values.join("\t")
      io << LINE_BREAK
    end
    io.string
  end


  private

  def select_clause
    element_subselects = []
    %w[title description].each do |element|
      element_subselects << "          array_to_string(
        array(
          SELECT replace(
            replace(
              replace(
                replace(
                  replace(
                    coalesce(value, '') || '#{URI_VALUE_SEPARATOR}<' || coalesce(uri, '') || '>',
                    '#{URI_VALUE_SEPARATOR}<>',
                    ''),
                  '||#{URI_VALUE_SEPARATOR}',
                  ''),
                '\n',
                '<LF>'),
              '\r',
              '<CR>'),
            '\t',
            '<TAB>')
          FROM entity_elements
          WHERE entity_elements.collection_id = collections.id
            AND entity_elements.name = '#{element}'
            AND (value IS NOT NULL OR uri IS NOT NULL)
            AND (length(value) > 0 OR length(uri) > 0)
        ), '#{MULTI_VALUE_SEPARATOR}') AS #{element}"
    end
    element_subselects = element_subselects.join(",\n")

    "SELECT * FROM (
      SELECT collections.repository_id,
        #{element_subselects},
        collections.public_in_medusa,
        collections.published_in_dls,
        collections.restricted,
        collections.publicize_binaries,
        collections.representative_item_id,
        collections.representative_medusa_file_id,
        collections.medusa_repository_id,
        collections.medusa_file_group_uuid,
        collections.medusa_directory_uuid,
        CASE
          WHEN collections.package_profile_id = #{PackageProfile::FREE_FORM_PROFILE.id}
            THEN 'Free-Form'
          WHEN collections.package_profile_id = #{PackageProfile::COMPOUND_OBJECT_PROFILE.id}
            THEN 'Compound Object'
          WHEN collections.package_profile_id = #{PackageProfile::SINGLE_ITEM_OBJECT_PROFILE.id}
            THEN 'Single-Item Object'
          WHEN collections.package_profile_id = #{PackageProfile::MIXED_MEDIA_PROFILE.id}
            THEN 'Mixed Media'
        END,
        collections.physical_collection_url,
        collections.external_id,
        collections.access_url,
        collections.rights_statement,
        collections.rights_term_uri,
        collections.harvestable,
        collections.harvestable_by_idhh,
        collections.harvestable_by_primo "
  end

  def from_clause
    ' FROM collections '
  end

  def order_clause
    'ORDER BY title NULLS FIRST'
  end

end