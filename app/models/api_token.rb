class ApiToken < ActiveRecord::Base
  belongs_to :credential
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

  # API-specific versions of calls found in Credential for
  # authentication. They return objects that are ready to be
  # serialized to a JSON response.  The responses from sign_up,
  # sign_in, and authenticate_oauth are designed to be fed back
  # into authenticate.

  def self.authenticate(params,request)
    incoming_token = params[:api_token] || request.headers['api-token']

    api_token = ApiToken.find_by_token(incoming_token)
    credential = api_token.credential if api_token
    token = api_token.token if api_token
    
    if api_token and not token
      api_token.delete if api_token
      raise ApiError.find(ApiError::INVALID_API_TOKEN)
    end
    
    api_token
  end

  def self.sign_in(params,request)
    username = params[:username] || params[:email] || params[:login]
    incoming_api_token = params[:api_token] || request.headers['api-token']

    password = params[:password]
    credential = nil

    api_token = nil

    logger.info "INCOMING API TOKEN '#{incoming_api_token.presence}'"

    if incoming_api_token.presence and not username and not password
      api_token = ApiToken.find_by_token(incoming_api_token) rescue nil
      credential = api_token.credential if api_token
      (api_token.destroy and api_token = nil) if not credential
    end

    if not api_token
      if username.blank? or password.blank?
        raise ApiError.find(ApiError::INVALID_USERNAME_OR_PASSWORD)
      else
        credential = Credential.authenticate(username,password)
      end
    end
    logger.info "Credentials #{ credential }"
    done(credential)
  end

  def self.sign_up(params,request)
    username = params[:username] || params[:login] || params[:email]
    password = params[:password]
    
    done(Credential.sign_up( username, password))
  end
  
  def self.done(credential)
    if not credential
      return { :error => "No credential" }
    end

    api_token = ApiToken.find_or_create_by(credential_id:credential.id) if credential
    
    if credential and api_token
      res = credential.as_json(:only => [:id,:email])
      res = res.merge(api_token.as_json(:only => [:token]))
    else
      res = { :error => "Invalid credential" }
    end
    
    res
  end

  def self.authenticate_oauth(hash)
    credential = Credential.authenticate_oauth(hash)

    done(credential)
  end

end
