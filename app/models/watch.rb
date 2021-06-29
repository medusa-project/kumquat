##
# Encapsulates the act of a user watching something.
#
class Watch < ApplicationRecord
  belongs_to :collection
  belongs_to :user
end
