require 'open-uri'

class GenericApiRails::AuthenticationController < GenericApiRails::BaseController
  skip_before_filter :api_setup

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

      res_hash = Rack::Utils.parse_query res
    
      long_lived_token = res_hash['access_token']
    rescue Exception => x
      render :json => { :error => x }
      return
    end

    # at this point, we have verified that the credential is authorized by
    # Facebook- facebook has even given us a long-lived token to
    # manipulate this credential via FB.  Now, all we need is some details
    # about our credential, namely the credential ID, and email.  We use Koala
    # here because it is a more flexible endpoint for Facebook, and we
    # don't want to be using OAuth here - we already have the token we
    # need.

    @graph = Koala::Facebook::API.new(long_lived_token, APP_SECRET)
    fb_user = @graph.get_object('me')

    uid = fb_user['id']
    
    # create a hash that matches what oauth spits out, but we've done
    # it with Koala:
    
    @provider = 'facebook'
    @uid = uid
    @email = fb_user[:email]

    render :json => instance_eval(&GenericApiRails.config.oauth_with)
  end

  def login
    @params = params
    @request = request
    
    render :json => instance_eval(&GenericApiRails.config.login_with)
  end

  def signup
    @params = params
    @request = request

    render :json => instance_eval(&GenericApiRails.config.signup_with)
  end
end
