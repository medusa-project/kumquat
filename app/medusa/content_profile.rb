require 'csv'

##
# Content in a DLS-compatible Medusa file group is organized (in terms of its
# folder structure, naming scheme, etc.) according to a content profile. An
# instance of this class representing a given profile is associated with a
# [Collection] representing a Medusa collection.
#
class ContentProfile

  # Note: constants for quickly accessing a particular profile are defined
  # further down.

  PROFILES = [
      {
          id: 0,
          name: 'Free-Form'
      },
      {
          id: 1,
          name: 'Map'
      }
  ]

  # @!attribute id
  #   @return [Integer]
  attr_accessor :id

  # @!attribute name
  #   @return [String]
  attr_accessor :name

  ##
  # @return [Array<ContentProfile>]
  #
  def self.all
    PROFILES.map do |profile|
      p = ContentProfile.new
      p.id = profile[:id]
      p.name = profile[:name]
      p
    end
  end

  def self.find(id)
    self.all.select{ |p| p.id == id.to_i }.first
  end

  FREE_FORM_PROFILE = ContentProfile.find(0)
  MAP_PROFILE = ContentProfile.find(1)

  def ==(obj)
    obj.kind_of?(self.class) and obj.id == self.id
  end

  ##
  # Queries Medusa to find all bytestreams for the Item with the given ID.
  #
  # @param item_id [String]
  # @return [Array<Bytestream>]
  # @raises [HTTPClient::BadResponseError]
  # @raises [ArgumentError] If the item ID is nil
  #
  def bytestreams_from_medusa(item_id)
    raise ArgumentError, 'No ID provided' unless item_id
    case self.id
      when 0
        return free_form_bytestreams_from_medusa(item_id)
      when 1
        return map_bytestreams_from_medusa(item_id)
    end
    []
  end

  ##
  # Searches for all bytestreams for the Item with the given ID from the given
  # TSV string.
  #
  # @param item_id [String]
  # @param tsv [Array<Hash<String,String>>]
  # @return [Array<Bytestream>]
  # @raises [HTTPClient::BadResponseError]
  # @raises [ArgumentError] If any arguments are nil
  #
  def bytestreams_from_tsv(item_id, tsv)
    raise ArgumentError, 'No ID provided' unless item_id
    case self.id
      when 0
        return free_form_bytestreams_from_tsv(item_id, tsv)
      when 1
        return map_bytestreams_from_tsv(item_id, tsv)
    end
    []
  end

  ##
  # Returns an array of the UUIDs of all of an item's children.
  #
  # @param item_id [String]
  # @param tsv [Array<Hash<String,String>>]
  # @return [Array<String>] Array of UUIDs
  #
  def children_from_tsv(item_id, tsv)
    raise ArgumentError, 'No ID provided' unless item_id
    case self.id
      when 0
        return free_form_children_from_tsv(item_id, tsv)
      when 1
        return map_children_from_tsv(item_id, tsv)
    end
    []
  end

  ##
  # Returns an array of the UUIDs of all items in the given TSV.
  #
  # @param tsv [Array<Hash<String,String>>]
  # @return [Array<Hash<String,String>>] Array of item rows
  #
  def items_from_tsv(tsv)
    case self.id
      when 0
        return free_form_items_from_tsv(tsv)
      when 1
        return map_items_from_tsv(tsv)
    end
    []
  end

  ##
  # Queries Medusa to find the parent ID of the Item with the given ID.
  #
  # @param item_id [String]
  # @return [String, nil] UUID of the parent item of the given item, or nil if
  #                       there is no parent.
  # @raises [HTTPClient::BadResponseError]
  # @raises [ArgumentError] If the item ID is nil
  #
  def parent_id_from_medusa(item_id)
    raise ArgumentError, 'No ID provided' unless item_id
    case self.id
      when 0
        return free_form_parent_id_from_medusa(item_id)
      when 1
        return map_parent_id_from_medusa(item_id)
    end
    nil
  end

  ##
  # Returns the parent UUID of an item.
  #
  # @param item_id [String]
  # @param tsv [Array<Hash<String,String>>]
  # @return [String, nil] Parent UUID
  #
  def parent_id_from_tsv(item_id, tsv)
    raise ArgumentError, 'No ID provided' unless item_id
    case self.id
      when 0
        return free_form_parent_id_from_tsv(item_id, tsv)
      when 1
        return map_parent_id_from_tsv(item_id, tsv)
    end
    []
  end

  ##
  # @param tsv [Array<Hash<String,String>>]
  # @return [String]
  # @raises [ArgumentError] For DLS TSV
  #
  def top_dir_id(tsv)
    if ItemTsvIngester.dls_tsv?(tsv)
      raise ArgumentError, 'DLS TSV has no top directory'
    else
      row = tsv.select{ |row| row['parent_directory_uuid'].blank? }.first
      return row['uuid'] if row
    end
    nil
  end

  private

  ##
  # @param preservation_master [Bytestream]
  # @return [Bytestream]
  #
  def access_master_counterpart(preservation_master)
    bs = Bytestream.new
    bs.repository_relative_pathname = preservation_master.
        repository_relative_pathname.gsub('/preservation/', '/access/').
        chomp('.tif').chomp('.tiff').chomp('.TIF').chomp('.TIFF') + '.jp2'
    bs.bytestream_type = Bytestream::Type::ACCESS_MASTER
    bs.infer_media_type
    bs
  end

  ##
  # @param uuid [String]
  # @return [String] Absolute URI of the Medusa collection resource, or nil
  #                  if the instance does not have an ID.
  #
  def medusa_url(uuid)
    sprintf('%s/uuids/%s.json',
            PearTree::Application.peartree_config[:medusa_url].chomp('/'),
            uuid)
  end

  ##
  # In the free-form profile, there is one bytestream per file. Directories
  # have no bytestreams.
  #
  # @param item_id [String]
  # @return [Array<Bytestream>]
  #
  def free_form_bytestreams_from_medusa(item_id)
    bytestreams = []
    client = Medusa.client
    response = client.get(medusa_url(item_id), follow_redirect: true)
    if response.status < 300
      json = response.body
      struct = JSON.parse(json)
      if struct['mtime'] # Only files will have this key.
        bs = Bytestream.new
        bs.repository_relative_pathname =
            '/' + struct['relative_pathname'].reverse.chomp('/').reverse
        bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
        bs.infer_media_type
        bytestreams << bs
      end
    end
    bytestreams
  end

  ##
  # In the free-form profile, there is one bytestream per file. Directories
  # have no bytestreams.
  #
  # @param item_id [String] Medusa UUID
  # @param tsv [Array<Hash<String,String>>]
  # @return [Array<Bytestream>]
  #
  def free_form_bytestreams_from_tsv(item_id, tsv)
    bytestreams = []
    row = tsv.select{ |row| row['uuid'] == item_id }.first
    # We need to handle Medusa TSV and DLS TSV differently.
    # Only Medusa TSV will contain an `inode_type` column.
    if row and row['inode_type'] and row['inode_type'] == 'file'
      bs = Bytestream.new
      bs.repository_relative_pathname = '/' + row['relative_pathname']
      bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
      bs.infer_media_type
      bytestreams << bs
    else
      # It's coming from DLS TSV. Find out whether it's a file or a directory
      # from Medusa, as this information is not contained in the TSV.
      if MedusaCfsFile.file?(item_id)
        file = MedusaCfsFile.new
        file.id = item_id
        bs = Bytestream.new
        bs.repository_relative_pathname = file.repository_relative_pathname
        bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
        bs.infer_media_type
        bytestreams << bs
      end
    end
    bytestreams
  end

  ##
  # @param item_id [String]
  # @param tsv [Array<String>]
  # @return [String]
  #
  def free_form_children_from_tsv(item_id, tsv)
    children = []
    # We need to handle Medusa TSV and DLS TSV differently.
    if ItemTsvIngester.dls_tsv?(tsv)
      children += tsv.select{ |r| r['parentId'] == item_id }.
          map{ |r| r['uuid'] }
    else
      children += tsv.select{ |r| r['parent_directory_uuid'] == item_id }.
          map{ |r| r['uuid'] }
    end
    children
  end

  ##
  # @param tsv [Array<Hash<String,String>>]
  # @return [Array<Hash<String,String>>]
  #
  def free_form_items_from_tsv(tsv)
    # We need to handle Medusa TSV and DLS TSV differently.
    if ItemTsvIngester.dls_tsv?(tsv)
      item_rows = tsv.select{ |r| r['uuid'].present? }
    else
      # Exclude the top-level directory.
      item_rows = tsv.select{ |r| r['parent_directory_uuid'].present? }
    end
    item_rows
  end

  ##
  # @param item_id [String]
  # @return [String]
  #
  def free_form_parent_id_from_medusa(item_id)
    parent_id = nil
    client = Medusa.client
    response = client.get(medusa_url(item_id), follow_redirect: true)
    if response.status < 300
      json = response.body
      struct = JSON.parse(json)
      if struct['parent_directory']
        # Top-level items in a file group will have no parent_directory key,
        # so check one level up.
        json = client.get(medusa_url(struct['parent_directory']['uuid']),
                          follow_redirect: true).body
        struct2 = JSON.parse(json)
        if struct2['parent_directory']
          parent_id = struct['parent_directory']['uuid']
        end
      elsif struct['directory']
        parent_id = struct['directory']['uuid']
      end
    end
    parent_id
  end

  ##
  # @param item_id [String]
  # @param tsv [Array<Hash<String,String>>]
  # @return [String]
  #
  def free_form_parent_id_from_tsv(item_id, tsv)
    # We need to handle Medusa TSV and DLS TSV differently.
    if ItemTsvIngester.dls_tsv?(tsv)
      parent = tsv.select{ |r| r['uuid'] == item_id }.first
      if parent
        return parent['parentId']
      end
    else
      parent = tsv.select{ |r| r['uuid'] == item_id }.first
      if parent and parent['parent_directory_uuid'] != top_dir_id(tsv)
        return parent['parent_directory_uuid']
      end
    end
    nil
  end

  ##
  # Child items will reside in a directory called `access` or
  # `preservation`. These are the only items in this profile that will have
  # any associated bytestreams. Preservation and access filenames will be the
  # same, except preservation files will end in .tif and access filenames in
  # .jp2.
  #
  # @param item_id [String]
  # @return [Array<Bytestream>]
  #
  def map_bytestreams_from_medusa(item_id)
    client = Medusa.client
    json = client.get(medusa_url(item_id), follow_redirect: true).body
    struct = JSON.parse(json)
    bytestreams = []

    if struct['directory']
      case struct['directory']['name']
        when 'preservation'
          # add the preservation master
          bs = Bytestream.new
          bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
          bs.repository_relative_pathname =
              '/' + struct['relative_pathname'].reverse.chomp('/').reverse
          bs.infer_media_type
          bytestreams << bs

          # add the access master
          bytestreams << access_master_counterpart(bs)
        when 'access'
          # add the preservation master
          bs = Bytestream.new
          bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
          bs.repository_relative_pathname =
              '/' + struct['relative_pathname'].reverse.chomp('/').reverse.
                  gsub('/preservation/', '/access/').chomp('.jp2') + '.tif'
          bs.infer_media_type
          bytestreams << bs

          # add the access master
          bs = Bytestream.new
          bs.bytestream_type = Bytestream::Type::ACCESS_MASTER
          bs.repository_relative_pathname =
              '/' + struct['relative_pathname'].reverse.chomp('/').reverse
          bs.infer_media_type
          bytestreams << bs
      end

    end
    bytestreams
  end

  ##
  # Child items will reside in a directory called `access` or `preservation`.
  # These are the only items in this profile that will have  any associated
  # bytestreams. Preservation and access filenames will be the  same, except
  # preservation files will end in .tif and access filenames in .jp2.
  #
  # @param item_id [String]
  # @param tsv [Array<Hash<String,String>>]
  # @return [Array<Bytestream>]
  #
  def map_bytestreams_from_tsv(item_id, tsv)
    bytestreams = []
    row = tsv.select{ |row| row['uuid'] == item_id }.first
    # We need to handle Medusa TSV and DLS TSV differently.
    if row and !ItemTsvIngester.dls_tsv?(tsv)
      case row['inode_type']
        when 'file' # It's a compound object page.
          bs = Bytestream.new
          bs.repository_relative_pathname = '/' + row['relative_pathname']
          bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
          bs.infer_media_type
          bytestreams << bs
          # Add an access bytestream even if it doesn't exist in Medusa.
          # (Content in Medusa may be messy and missing access files could
          # appear eventually.) Same path except /access/ instead of
          # /preservation/ and a .jp2 extension instead of .tif.
          bytestreams << access_master_counterpart(bs)
        when 'folder'
          # If it has no children, assume it's a top-level non-compound-object,
          # which does have bytestreams. Otherwise, assume it's a top-level
          # compound-object, which does not.
          if children_from_tsv(item_id, tsv).empty?
            bs = Bytestream.new
            bs.repository_relative_pathname = '/' + row['relative_pathname'] +
                '/preservation/' + row['name'] + '.tif'
            bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
            bs.infer_media_type
            bytestreams << bs
            # Add an access bytestream even if it doesn't exist in Medusa.
            # (Content in Medusa may be messy and missing access files could
            # appear eventually.) Same path except /access/ instead of
            # /preservation/ and a .jp2 extension instead of .tif.
            bytestreams << access_master_counterpart(bs)
          end
      end
    else
      # It's coming from DLS TSV. Find out whether it's a file or a directory
      # from Medusa, as this information is not contained in the TSV.
      if MedusaCfsFile.file?(item_id)
        file = MedusaCfsFile.new
        file.id = item_id
        # Only preservation masters are considered "items" in this profile.
        if File.extname(file.repository_relative_pathname).downcase[0..3] == '.tif'
          bs = Bytestream.new
          bs.repository_relative_pathname = file.repository_relative_pathname
          bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
          bs.infer_media_type
          bytestreams << bs
          # Add an access bytestream even if it doesn't exist in Medusa.
          # (Content in Medusa may be messy and missing access files could
          # appear eventually.) Same path except /access/ instead of
          # /preservation/ and a .jp2 extension instead of .tif.
          bytestreams << access_master_counterpart(bs)
        end
      end
    end
    bytestreams
  end

  ##
  # @param item_id [String]
  # @param tsv [Array<String>]
  # @return [String]
  #
  def map_children_from_tsv(item_id, tsv)
    children = []
    # We need to handle Medusa TSV and DLS TSV differently.
    row = tsv.select{ |r| r['uuid'] == item_id }.first
    if ItemTsvIngester.dls_tsv?(tsv)
      children += tsv.select{ |r| r['parentId'] == row['uuid'] }.
          map{ |r| r['uuid'] }
    elsif row['inode_type'] == 'folder'
      preservation_dir = tsv.select{ |r| r['parent_directory_uuid'] == item_id and
          r['name'] == 'preservation' }.first
      if preservation_dir
        pres_dir_files = tsv.
            select{ |r| r['parent_directory_uuid'] == preservation_dir['uuid'] }.
            map{ |r| r['uuid'] }
        # If there is only 1 file in the preservation folder, assume it's a
        # non-compound object, which has no children.
        if pres_dir_files.length > 1
          children += pres_dir_files
        end
      end
    end
    children
  end

  ##
  # Returns all map item IDs in the given TSV.
  #
  # Note that this includes items that may be outside a collection's effective
  # CFS root, so the IDs should be checked with `ItemTsvIngester.within_root?`
  # before ingesting.
  #
  # @param tsv [Array<Hash<String,String>>]
  # @return [Array<Hash<String,String>>]
  #
  def map_items_from_tsv(tsv)
    item_rows = []
    if ItemTsvIngester.dls_tsv?(tsv)
      item_rows = tsv.select{ |r| r['uuid'].present? }
    else
      # Get the name of the top-level directory.
      top_dir = top_dir_id(tsv)
      tsv.each do |row|
        # If it's a folder within the top-level directory, and it has a
        # subfolder named "preservation", consider it an item.
        if row['inode_type'] == 'folder' and row['parent_directory_uuid'] == top_dir
          if tsv.select{ |r| r['parent_directory_uuid'] == row['uuid'] }.
              map{ |r| r['name'].strip }.include?('preservation')
            item_rows << row
          end
        else
          # If it's a compound object page, it will end in a TIFF extension.
          # But, if there is only one .tif file in the preservation directory,
          # it belongs to a top-level non-compound-object, so it's not a
          # compound object page.
          if row['name'] and File.extname(row['name']).downcase[0..3] == '.tif'
            # Get the ostensible parent in order to find out how many children
            # it has.
            if tsv.select{ |r| r['parent_directory_uuid'] == row['parent_directory_uuid'] }.length > 1
              item_rows << row
            end
          end
        end
      end
    end
    item_rows
  end

  ##
  # @param item_id [String]
  # @return [String]
  #
  def map_parent_id_from_medusa(item_id)
    client = Medusa.client
    json = client.get(medusa_url(item_id), follow_redirect: true).body
    struct = JSON.parse(json)

    # Top-level items will have `access`, `metadata`, and/or `preservation`
    # subdirectories.
    if struct['subdirectories']&.
        select{ |n| %w(access metadata preservation).include?(n['name']) }&.any?
      return nil
      # Child items will reside in a directory called `access` or
      # `preservation`.
    elsif struct['directory'] and
        %w(access preservation).include?(struct['directory']['name'])
      json = client.get(medusa_url(struct['directory']['uuid']),
                        follow_redirect: true).body
      struct2 = JSON.parse(json)
      return struct2['parent_directory']['uuid']
    end
  end

  ##
  # @param item_id [String]
  # @param tsv [Array<Hash<String,String>>]
  # @return [String]
  #
  def map_parent_id_from_tsv(item_id, tsv)
    # We need to handle Medusa TSV and DLS TSV differently.
    if ItemTsvIngester.dls_tsv?(tsv)
      parent = tsv.select{ |r| r['uuid'] == item_id }.first
      return parent['parentId'] if parent
    else
      row = tsv.select{ |r| r['uuid'] == item_id }.first
      if row and row['parent_directory_name'] == 'preservation'
        if tsv.select{ |r| r['parent_directory_uuid'] == row['parent_directory_uuid'] }.length > 1
          parent_dir = tsv.select{ |r| r['uuid'] == row['parent_directory_uuid'] }.first
          if parent_dir
            return parent_dir['parent_directory_uuid']
          end
        end
      end
    end
    nil
  end

end