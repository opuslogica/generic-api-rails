require 'open-uri'
require 'koala'

class GenericApiRails::AuthenticationController < GenericApiRails::BaseController
  skip_before_filter :api_setup, except: [:logout,:change_password]
  skip_before_filter :verify_authenticity_token

  def change_password
    old_password = params[:old_password]
    new_password = params[:new_password]

    render :json => { success: false, error: "Not logged in" } and return unless @authenticated

    @res = GenericApiRails.config.change_password_with.call(@authenticated,old_password,new_password);

    render :json => { success: false , error: "Invalid password" }  and return unless @res
    
    render :json => { success: true }
  end

  def reset_password
    token = params[:token]
    password = params[:password]

    @credential = GenericApiRails.config.reset_password_with.call(token,password)

    render :json => { error: { description: "Invalid token." } } and return false unless @credential
    if( @credential.errors.messages.length > 0) 
      errors = {};
      @credential.errors.each do |key,value|
        if value.kind_of? Array
          errors[key] = value.join(', ')
        else
          errors[key] = value
        end
      end
      render :json => { :errors =>  errors }
      return
    end
    
    done
  end

  def recover_password
    success = GenericApiRails.config.recover_password_with.call(params[:email] || params[:username] || params[:login])
    
    render :json => { success: success }
  end
  
  def done
    render_error(ApiError::INVALID_USERNAME_OR_PASSWORD) and return false unless @credential
    
    # We cannot create a polymorphic association with find or create by, it appears
    if GenericApiRails.config.new_api_token_every_login == true
      @api_token ||= ApiToken.create(credential: @credential)
    else
      @api_token ||= ApiToken.where(credential: @credential).first_or_create
    end
    
    # if @credential and @api_token
    #   res = @credential.as_json
    #   res[:email] = @credential.email.address
    #   res[:person_id] = @credential.member.person.id
    #   res = res.merge(@api_token.as_json(:only => [:token]))
    # else
    #   raise "failed to create api token? should be impossible..."
    # end
  end

  # To configure facebook authorization, add the following to
  # config/initializers/generic_api.rb:
  #
  #  config.use_facebook(app_id: '1234567890', app_secret: '123abc123abc')
  #
  def facebook
    # By default, client-side authentication gives you a short-lived
    # token:
    short_lived_token = params[:access_token]
    
    fb_hash = GenericApiRails.config.facebook_hash
    if fb_hash.nil?
      logger.error('Facebook login/signup not configured. For configuration instructions see controllers/generic_api_rails/authentication_controller.rb in the generic_api_rails project')
      render :json => { success: false , error: "Facebook login/signup not configured" }
      return
    end

    app_id = fb_hash[:app_id]
    app_secret = fb_hash[:app_secret]

    # to upgrade it, hit this URI, and use the token it hands back:
    token_upgrade_uri = "https://graph.facebook.com/oauth/access_token?client_id=#{app_id}&client_secret=#{app_secret}&grant_type=fb_exchange_token&fb_exchange_token=#{short_lived_token}"
    
    begin
      res = URI.parse(token_upgrade_uri).read

      res_hash = Rack::Utils.parse_query(res)

      long_lived_token = res_hash['access_token']
    rescue Exception => x
      logger.error(self.class.name + " - facebook: #{x}")
      long_lived_token = short_lived_token
      # render :json => { :error => "token-upgrade error (#{x})" }
      # return
    end

    # at this point, we have verified that the credential is authorized by
    # Facebook- facebook has even given us a long-lived token to
    # manipulate this credential via FB.  Now, all we need is some details
    # about our credential, namely the credential ID, and email.  We use Koala
    # here because it is a more flexible endpoint for Facebook, and we
    # don't want to be using OAuth here - we already have the token we
    # need.

    @graph = ::Koala::Facebook::API.new(long_lived_token, app_secret)
    fb_user = @graph.get_object("me", fields: "email,first_name,last_name,middle_name,birthday,about,location")
    # logger.info("FB_USER: #{fb_user}")
    uid = fb_user["id"]
    profile_pic = @graph.get_picture(uid, { height: 500, width: 500 })

    # create a hash that matches what oauth spits out, but we've done
    # it with Koala:
    @provider = "facebook"
    @uid = uid
    @email = fb_user["email"]

    person_hash = {
      fname: fb_user["first_name"],
      lname: fb_user["last_name"],
      minitial: fb_user["middle_name"],
      profile_picture_uri: profile_pic,
      birthdate: fb_user["birthday"]
    }

    @results = GenericApiRails.config.oauth_with.call(provider: "facebook", uid: uid, email: @email , person: person_hash)

    if @results[0].nil?
      # error = @results[1]
      @credential = nil
    else
      @credential = @results[0]
    end

    done
  end

  # log in/sign up with Google
  def google
    google_config = GenericApiRails.config.google_hash
    access_token = params['access_token']

    # get the token
    #https://www.googleapis.com/oauth2/v3/token
    code_uri = URI('https://www.googleapis.com/oauth2/v3/token');
    oauth_https = Net::HTTP.new(code_uri.host, code_uri.port)
    oauth_https.use_ssl = true

    post_data = {
      :code => access_token,
      :client_id => google_config[:client_id],
      :client_secret => google_config[:client_secret],
      :redirect_uri => access_token['redirect_uri'],
      :grant_type => 'authorization_code'
    }

    post_data_string = URI.escape(post_data.collect{|k,v| "#{k}=#{v}"}.join('&'))
    code_response = oauth_https.post(code_uri.path, post_data_string) 

    if code_response.code.to_s != 200.to_s
      render :json => { success: false , error: "Could not authenticate using Google" }
      return
    end

    auth_response = JSON.parse(code_response.body)
    access_token = auth_response['access_token']

    logger.debug("INCOMING API TOKEN '#{incoming_api_token.presence}'")
    render :json => { success: false , error: "Could not authenticate using Google" }
  end

  # Log in/sign up with linkedin
  #
  # To configure Linkedin authorization, add the following to
  # config/initializers/generic_api.rb:
  #
  #  config.use_linkedin(client_id: '1234567890', client_secret: 'abcdefghij', redirect_uri: 'http://foo.bar.com/linkedin_redirect')
  def linkedin
    linkedin_config = GenericApiRails.config.linkedin_hash
    if linkedin_config.nil?
      logger.error('Linkedin login/signup not configured. For configuration instructions see controllers/generic_api_rails/authentication_controller.rb in the generic_api_rails project')
      render :json => { success: false , error: "Linkedin login/signup not configured" }
      return
    end
    
    # Get the "Real" authorization code
    temp_access_token = params['access_token']

    code_uri = URI('https://www.linkedin.com/uas/oauth2/accessToken')
    oauth_https = Net::HTTP.new(code_uri.host, code_uri.port)
    oauth_https.use_ssl = true

    post_data = {
      :grant_type => 'authorization_code',
      :code => temp_access_token,
      :client_id => linkedin_config[:client_id],
      :client_secret => linkedin_config[:client_secret],
      :redirect_uri => params['redirect_uri'] || linkedin_config[:redirect_uri]
    }
    post_data_string = URI.escape(post_data.collect{|k,v| "#{k}=#{v}"}.join('&'))

    code_response = oauth_https.post(code_uri.path, post_data_string) 

    if code_response.code.to_s != 200.to_s
      # log the error message if there is one
      if code_response.body
        resp = JSON.parse(code_response.body)
        logger.error("Error authenticating user against Linkedin: #{resp['error_description']}")
      end
      render :json => { success: false , error: "Could not authenticate using Linkedin" }
      return
    end

    auth_response = JSON.parse(code_response.body)
    access_token = auth_response['access_token']

    if access_token.nil?
      render :json => { success: false , error: "Could not get access token from Linkedin" }
      return
    end

    # Get the user's info
    # user_uri = URI('https://api.linkedin.com/v1/people/~?format=json')
    user_uri =URI('https://api.linkedin.com/v1/people/~:(id,email-address,firstName,lastName)?format=json')
    api_https = Net::HTTP.new(user_uri.host, user_uri.port)
    api_https.use_ssl = true

    request = Net::HTTP::Get.new(user_uri.request_uri)
    request['Authorization'] = "Bearer #{access_token}"

    user_response = api_https.request(request)
    if user_response.code.to_s != 200.to_s
      render :json => { success: false , error: "Could not get user info from Linkedin" }
      return
    end

    user_info = JSON.parse(user_response.body)
    uid = user_info['id']
    @email = user_info['emailAddress']

    person_hash = {
      fname: user_info["firstName"],
      lname: user_info["lastName"]
      #minitial: user_info["middle_name"],
      #profile_picture_uri: profile_pic,
      #birthdate: user_info["birthday"]
    }
    
    # You'll have to define GenericApiRails.config.oauth_with for your
    # particular application
    @results = GenericApiRails.config.oauth_with.call(provider: "linkedin", uid: uid, email: @email , person: person_hash)

    if @results[0].nil?
      @credential = nil
    else
      @credential = @results[0]
    end

    done
  end

  def login
    username = params[:username] || params[:email] || params[:login]
    incoming_api_token = params[:api_token] || request.headers["api-token"]
    password = params[:password]

    username = username.downcase if username.present?
    @credential = nil
    api_token = nil

    logger.debug("INCOMING API TOKEN '#{incoming_api_token.presence}'")

    if incoming_api_token.present? and not password
      @api_token = ApiToken.find_by(token: incoming_api_token) rescue nil
      if @api_token
        @credential = @api_token.credential
        if @credential.email.respond_to? :address
          cred_email = @credential.email.address
        else
          cred_email = @credential.email
        end
        (@api_token.destroy and @api_token = nil) if (not @credential) or (username && cred_email.downcase != username.downcase)
      end
    end

    if not @api_token
      if username.blank? or password.blank?
        render_error(ApiError::INVALID_USERNAME_OR_PASSWORD) and return
      else
        @credential = GenericApiRails.config.login_with.call(username, password)
      end
    end

    logger.debug("Credentials #{ @credential }")
    done
  end

  def validate_signup_params(params)
    errs = {}
    if not params[:fname] and not params[:lname] and not params[:name]
      errs[:fname] = "You must provide at least one name"
    end

    if not true
      errs[:fname] = "You must provide a first name" unless params[:fname].present?
      errs[:lname] = "You must provide a last name" unless params[:lname].present?
    end

    errs[:username] = "You must provide a valid email" unless params[:username].present?
    errs[:password] = "You must provide a password of at least 4 characters" unless params[:password].present? && params[:password].length >= 4
    errs = nil if errs.keys.length == 0
    errs
  end

  def signup
    username = params[:username] || params[:login] || params[:email]
    password = params[:password]

    options = params
    if not params.has_key?(:fname) and not params.has_key?(:lname) and params.has_key?(:name)
      options[:name] = params[:name]
      components = params[:name].split(" ") rescue [params[:name]]
      fname = components.shift
      lname = components.join
    else
      fname = params[:fname]
      lname = params[:lname]
    end

    options[:fname] = fname
    options[:lname] = lname
    
    options[:password_confirmation] = params[:password_confirmation]
     
    @results = GenericApiRails.config.signup_with.call(username, password, options)
    errors = {};
    if @results[0].nil?
      @credential = nil
      errors[:message] = @results[1]
      render json: { errors: errors } and return
    else
      @credential = @results[0]

      if @credential.respond_to?(:errors) and @credential.errors.messages.length > 0
        @credential.errors.each do |key,value|
          if value.kind_of?(Array)
            errors[key] = value.join(', ')
          else
            errors[key] = value
          end
        end
        render :json => { :errors =>  errors }
        return
      end

      if not @credential.id
        render :json => { :error => { message: "Unknown error signing up" } }
        return
      end
    end
    
    done

    render 'login'
  end
  
  def logout
    render_error(ApiError::INVALID_API_TOKEN) and return unless @authenticated

    @api_token.destroy!
    render :json => { status: "OK" }
  end
end
