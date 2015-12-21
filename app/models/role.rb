##
# Encapsulates a role in a role-based access control (RBAC) system.
# A role can have zero or more permissions as well as zero or more users.
#
class Role < ActiveRecord::Base
  has_and_belongs_to_many :permissions
  has_and_belongs_to_many :users

  validates :key, presence: true, length: { maximum: 30 },
            uniqueness: { case_sensitive: false }
  validates :name, presence: true, length: { maximum: 255 },
            uniqueness: { case_sensitive: false }

  def after_initialize
    if self.key == 'admin'
      self.permissions = Permission.all
      self.save!
    end
  end

  def to_param
    key
  end

  def has_permission?(key)
    (self.permissions.where(key: key).count > 0)
  end

end
