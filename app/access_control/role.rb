##
# Encapsulates a role in a role-based access control (RBAC) system.
#
class Role < ApplicationRecord

  has_and_belongs_to_many :permissions
  has_and_belongs_to_many :users

  validates :key, presence: true, length: { maximum: 30 },
            uniqueness: { case_sensitive: false }
  validates :name, presence: true, length: { maximum: 255 },
            uniqueness: { case_sensitive: false }

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
