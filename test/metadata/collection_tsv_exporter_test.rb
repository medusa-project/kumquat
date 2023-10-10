require 'test_helper'

class CollectionTsvExporterTest < ActiveSupport::TestCase

  COLLECTION = {
    'uuid': 'bbe5cc7c-9689-2f25-7d2c-da361492b55e',
    'title': nil,
    'description': nil,
    'public_in_medusa': true,
    'published_in_dls': true,
    'restricted': false,
    'publicize_binaries': true,
    'representative_item_id': nil,
    'representative_medusa_file_id': nil,
    'medusa_repository_id': 1,
    'medusa_file_group_uuid': 'bd7811d0-0d79-15c5-da1a-da28261f680a',
    'medusa_directory_uuid': nil,
    'package_profile_id': 'Compound Object',
    'physical_collection_url': nil,
    'external_id': nil,
    'access_url': nil,
    'rights_statement': nil,
    'rights_term_uri': nil,
    'harvestable': true,
    'harvestable_by_idhh': true,
    'harvestable_by_primo': true
  }

  setup do
    @instance = CollectionTsvExporter.new
  end

  # collections()

  test 'collections() works' do
    expected_values  = [COLLECTION]
    collections      = [collections(:compound_object)]
    collection_uuids = collections.map(&:repository_id)

    assert_equal to_tsv(Collection::TSV_COLUMNS, expected_values),
                 @instance.collections(collection_uuids)
  end


  private

  ##
  # @param header [Array]
  # @param values [Array<Hash<String,Object>>]
  # @return [String]
  #
  def to_tsv(header, values)
    header.join("\t") + CollectionTsvExporter::LINE_BREAK +
      values.map { |v| v.values.join("\t") }.join(CollectionTsvExporter::LINE_BREAK) +
      CollectionTsvExporter::LINE_BREAK
  end

end