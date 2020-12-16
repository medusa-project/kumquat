##
# Arbitrary container of items.
#
# N.B.: For implementation reasons, when adding a compound object
# (non-free-form {Item} with children) to an instance, all of its child items
# must also be added as well.
#
# # Attributes
#
# * `collection_repository_id` UUID of the associated collection.
# * `created_at`               Managed by ActiveRecord.
# * `name`                     Name of the set.
# * `updated_at`               Managed by ActiveRecord.
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
  # @param item [Item]
  #
  def add_item(item)
    transaction do
      if self.items.where(repository_id: item.repository_id).count < 1
        self.items << item
        self.save!
      end
    end
  end

  ##
  # @param item [Item]
  #
  def add_item_and_children(item)
    transaction do
      # Add the item.
      add_item(item)

      # Add all of its children.
      item.all_children.each do |child|
        if self.items.where(repository_id: child.repository_id).count < 1
          self.items << child
        end
      end
      self.save!
    end
  end

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
  # @return [Integer] Number of objects contained in the instance. The result
  #                   is cached.
  #
  def num_objects
    unless @num_objects
      case self.collection.package_profile
        when PackageProfile::FREE_FORM_PROFILE
          @num_objects = Item.search.
              item_set(self).
              aggregations(false).
              include_unpublished(true).
              include_restricted(true).
              search_children(false).
              include_variants(*Item::Variants::FILE).
              limit(0).
              count
        else
          @num_objects = Item.search.
              item_set(self).
              aggregations(false).
              include_unpublished(true).
              include_restricted(true).
              search_children(false).
              limit(0).
              count
      end
    end
    @num_objects
  end

  ##
  # @return [String] The name.
  #
  def to_s
    "#{name}"
  end

  private

  def index_item(item)
    item.reindex
  end

end
