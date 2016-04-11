class Theme < ActiveRecord::Base

  has_many :collections, inverse_of: :theme

  validates :name, length: { minimum: 2, maximum: 30 },
            uniqueness: { case_sensitive: false }

  ##
  # @return [Theme]
  #
  def self.default
    Theme.where(default: true).limit(1).first
  end

  ##
  # Returns the expected pathname of the theme's folder relative to the
  # application root.
  #
  # @return [String]
  #
  def pathname
    self.required ?
        File.join('app', 'views') :
        File.join('local', 'themes', self.name.downcase.gsub(' ', '_'))
  end

end
