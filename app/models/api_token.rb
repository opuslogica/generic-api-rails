class ApiToken < ActiveRecord::Base
  belongs_to :credential, polymorphic: true
  before_save :create_token_if_necessary
  delegate :person, to: :credential

  def make_token
    SecureRandom.uuid
  end

  def create_token_if_necessary
    self.token = make_token() if not token
  end

  def admin_object_name
    token
  end

end
