class Vocabulary < ActiveRecord::Base

  validates :key, presence: true, length: { maximum: 10 },
            uniqueness: { case_sensitive: false }
  validates :name, presence: true, length: { maximum: 100 },
            uniqueness: { case_sensitive: false }

end
