class ApiError < ActiveRecord::Base
  INVALID_ARGUMENT             = 11
  INVALID_RANGE                = 12
  INVALID_USERNAME_OR_PASSWORD = 17
  INVALID_API_TOKEN            = 18
  INVALID_PERSON_ID            = 20
  
  STANDARD_ERRORS =
    [
     { :code => INVALID_ARGUMENT, :description => "Invalid argument", :status_code => 403 },
     { :code => INVALID_RANGE, :description => "Invalid range argument - missing beg or end", :status_code => 403 },
     { :code => INVALID_API_TOKEN, :description => "Invalid API token", :status_code => 403 },
     { :code => INVALID_USERNAME_OR_PASSWORD, :description => "Invalid username or password", :status_code => 403 },
     { :code => INVALID_PERSON_ID, :description => "Invalid person id", :status_code => 403 },
    ]

  def self.make_standard_errors
    STANDARD_ERRORS.each do |h|
      e = self.find_or_create_by(code: h[:code])
      e.description = h[:description] if e.description != h[:description]
      e.status_code = h[:status_code] if e.status_code != h[:status_code]
      e.save
    end
  end

  def as_json(options={})
    super(:only => [:code, :status_code, :description])
  end
end
