# frozen_string_literal: true

class NotAuthorizedError < StandardError

  attr_accessor :reason

end
