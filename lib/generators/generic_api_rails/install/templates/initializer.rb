GenericApiRails.config do |config|
  config.authenticate_with do
    # authenticate_with receives a @params and @request hashes that
    # give the block access to all of the inputs from the request.
    # It must sort out api tokens, etc (for every API call), and
    # return an "authenticated" object, which will be used later to
    # check for permissions and do on.  The exact object type/etc is
    # irrelevant to the API server, and is only used to ask
    # questions later about whether or not the current API caller is
    # authorized to perform some action (including read) a resource.

    c = ApiToken.authenticate(@params,@request).credential rescue nil
    
    # if API authentication fails, we may wish to defer to
    # session-based authentication, so a traditional web-app that has
    # an API component can be authenticated automatically, without the
    # use of an API token:

    c || authenticated
  end

  config.login_with do
    # login_with takes the same @params and @request hash that
    # authenticate_with does, but only is called once per session,
    # to give the user some way to authenticate for later api calls.
    # Whatever it returns is directly returned as a JSON blob to the
    # client.  Make sure that the client knows how to turn whatever
    # is returned by this into something that is readable by
    # authenticate_with!
    
    ApiToken.sign_in(@params,@request)
  end
  
  config.signup_with do
    # signup_with is essentially the same as login_with, with the
    # difference being that it rejects already-used emails and
    # creates a user before it is returned to the client.  It may
    # throw whatever errors it wishes, which will be passed along to
    # the client in JSON form.
    
    ApiToken.sign_up(@params,@request)
  end

  # You may also elect to use OmniAuth to allow for user sign in and
  # sign up.  To connect these dots, you must add a glue-function to
  # connect to whatever authentication package you are using.

  config.omniauth_with do
    ApiToken.authenticate_oauth(:email => @email, :provider => @provider, :uid => @uid)
  end

  # Built-in support for facebook requires that you simply add in the
  # app ID and app secret for your app:
  # config.use_facebook app_id: '<APP_ID>', app_secret: '<APP SECRET>'

  # Other options:
  #
  # You may read about the other options in lib/generic_api_rails/config.rb
end
