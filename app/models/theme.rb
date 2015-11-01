class Theme < ActiveRecord::Base

  #include Defaultable

  #has_many :collections, class_name: 'DB::Collection'

  validates :name, length: { minimum: 2, maximum: 30 },
            uniqueness: { case_sensitive: false }

  ##
  # @return Theme
  #
  def self.default
    Theme.where(default: true).limit(1).first
  end

  ##
  # Returns the expected pathname of the theme's folder relative to the
  # application root.
  #
  # @return string
  #
  def pathname
    if self.required
      return File.join('app', 'views')
    end
    File.join('local', 'themes', self.name.downcase.gsub(' ', '_'))
  end

end
