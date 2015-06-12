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
    @api_token ||= ApiToken.create(credential: @credential)
    
    # @api_token = ApiToken.find_or_create_by(credential_id: @credential.id, credential_type: @crendential.class.name)

    # if @credential and @api_token
    #   res = @credential.as_json
    #   res[:email] = @credential.email.address
    #   res[:person_id] = @credential.member.person.id
    #   res = res.merge(@api_token.as_json(:only => [:token]))
    # else
    #   raise "failed to create api token? should be impossible..."
    # end

    
  end

  def facebook
    # By default, client-side authentication gives you a short-lived
    # token:
    short_lived_token = params[:access_token]
    
    fb_hash = GenericApiRails.config.facebook_hash

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

    @credential = GenericApiRails.config.oauth_with.call(provider: "facebook", uid: uid, email: @email , person: person_hash)

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
        render_error ApiError::INVALID_USERNAME_OR_PASSWORD and return
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
#    errs = validate_signup_params params
#    render :json => { :errors => errs } and return if errs

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

    @credential = GenericApiRails.config.signup_with.call(username, password, options)
    
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

    if( !@credential.id )
      render :json => { :error => { message: "Unknown error signing up" } }
      return
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
