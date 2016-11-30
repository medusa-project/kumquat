class Agent < ActiveRecord::Base

  before_validation :ascribe_default_uri, if: :new_record?

  validates_presence_of :name, :uri

  private

  def ascribe_default_uri
    self.uri = "urn:uuid:#{SecureRandom.uuid}" if self.uri.blank?
  end

end
