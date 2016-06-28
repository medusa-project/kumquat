class Vocabulary < ActiveRecord::Base

  has_and_belongs_to_many :element_defs

  validates :key, presence: true, length: { maximum: 10 },
            uniqueness: { case_sensitive: false }
  validates :name, presence: true, length: { maximum: 100 },
            uniqueness: { case_sensitive: false }

end
