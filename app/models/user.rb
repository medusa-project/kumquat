class User < ActiveRecord::Base

  has_and_belongs_to_many :roles

  validates :username, presence: true, length: { maximum: 50 },
            uniqueness: { case_sensitive: false }

  def has_permission?(key)
    return true if self.is_admin?
    self.roles_having_permission(key).any?
  end

  alias_method :can?, :has_permission?

  def is_admin?
    self.roles.where(key: 'admin').limit(1).any?
  end

  def roles_having_permission(key)
    self.roles.select{ |r| r.has_permission?(key) }
  end

  def to_param
    username
  end

  def to_s
    username
  end

end
