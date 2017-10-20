##
# # Attributes
#
# * collection_repository_id: Medusa UUID of the associated collection.
# * name:                     Name of the set.
#
class ItemSet < ActiveRecord::Base

  has_and_belongs_to_many :items, after_add: :index_item,
                          after_remove: :index_item
  has_and_belongs_to_many :users

  # collection_repository_id
  validates_format_of :collection_repository_id, with: StringUtils::UUID_REGEX,
                      message: 'UUID is invalid'
  # name
  validates :name, presence: true, length: { minimum: 4 }
  validates_uniqueness_of :name, scope: :collection_repository_id

  accepts_nested_attributes_for :users

  ##
  # @return [Collection]
  #
  def collection
    unless @collection
      @collection = Collection.find_by_repository_id(self.collection_repository_id)
    end
    @collection
  end

  ##
  # @return [Integer] Number of objects in the instance. The result is cached.
  #
  def num_objects
    unless @num_objects
      case self.collection.package_profile
        when PackageProfile::FREE_FORM_PROFILE
          @num_objects = ItemFinder.new.
              item_set(self).
              aggregations(false).
              search_children(false).
              include_variants(*Item::Variants::FILE).
              limit(0).
              count
        else
          @num_objects = ItemFinder.new.
              item_set(self).
              aggregations(false).
              search_children(false).
              limit(0).
              count
      end
    end
    @num_objects
  end

  def to_s
    "#{name}"
  end

  private

  def index_item(item)
    item.reindex
  end

end
