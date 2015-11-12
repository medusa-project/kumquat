class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
      record.errors[attribute] << (options[:message] || "is not an email address")
    end
  end
end

class User < ActiveRecord::Base
  #has_and_belongs_to_many :roles

  validates :email, presence: true, uniqueness: true, email: true
  validates :password, length: { minimum: 5 }, if: :should_validate_password?
  validates :username, presence: true, length: { maximum: 30 },
            uniqueness: { case_sensitive: false },
            format: { with: /\A(?=.*[a-z])[a-z\d]+\Z/i,
                      message: 'Only letters and numbers are allowed.' }

  has_secure_password

  def to_param
    username
  end

  def has_permission?(key)
    return true if self.is_admin?
    #self.roles_having_permission(key).any? TODO: fix
  end

  alias_method :can?, :has_permission?

  def is_admin?
    # TODO: fix
    true
    #self.roles.where(key: 'admin').limit(1).any?
  end

  #def roles_having_permission(key)
  #  self.roles.select{ |r| r.has_permission?(key) }
  #end

  private

  def should_validate_password?
    password.present? or password_confirmation.present?
  end

end
