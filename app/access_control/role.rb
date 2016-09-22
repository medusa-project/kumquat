##
# Encapsulates a role in a role-based access control (RBAC) system.
#
class Role < ActiveRecord::Base

  has_many :hosts, -> { order(:pattern) }, dependent: :destroy

  has_and_belongs_to_many :allowing_collections, class_name: 'Collection',
                          foreign_key: :allowed_role_id
  has_and_belongs_to_many :denying_collections, class_name: 'Collection',
                          foreign_key: :denied_role_id
  has_and_belongs_to_many :allowing_items, class_name: 'Item',
                          foreign_key: :allowed_role_id
  has_and_belongs_to_many :denying_items, class_name: 'Item',
                          foreign_key: :denied_role_id
  has_and_belongs_to_many :permissions
  has_and_belongs_to_many :users

  validates :key, presence: true, length: { maximum: 30 },
            uniqueness: { case_sensitive: false }
  validates :name, presence: true, length: { maximum: 255 },
            uniqueness: { case_sensitive: false }

  ##
  # @param hostname [String] Full hostname
  # @param ip_address [String] Full IP address
  # @return [Set<Role>]
  #
  def self.all_matching_hostname_or_ip(hostname, ip_address)
    roles = Set.new
    Role.all.each do |role|
      role.hosts.each do |host|
        roles << role if host.pattern_matches?(hostname) or
            host.pattern_matches?(ip_address)
      end
    end
    roles
  end

  ##
  # @return [String]
  #
  def to_param
    key
  end

  ##
  # @return [Boolean]
  #
  def has_permission?(key)
    (self.permissions.where(key: key).count > 0)
  end

end
