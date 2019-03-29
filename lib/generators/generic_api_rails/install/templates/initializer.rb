GenericApiRails.config do |config|
  # When SIMPLE_API is true, just the data is returned in JSON format.
  # When SIMPLE_API is false, an object consisting of metadata and data is returned.
  #
  # If the operation returns an array and the API is not simple, the result contains the total number
  # of rows available, and then an array of models only as long as the (optional) LIMIT parameter. For
  # example, if there are 4 rows of people in the database, then GET /people?limit=2 returns:
  # { total:4 rows:[{model:{id:1, attribute:value}, errors: {}}, {model:{id:2, attribute:value}, errors{}}]}
  #
  # If the operation returns an array, and the API is simple, the result is an array of objects, each of
  # which is only the attributes for that object:
  # [{id:1, attribute:value},{id:2, attribute:value}]
  #
  # If the operation returns a singleton, and the API is not simple, the result is:
  # {model:{id:1, attribute:value}}
  #
  # If the operation returns a singleton, and the API is simple, the result is:
  # {id:1, attribute:value}
  config.simple_api = false

  config.login_with do |username, password|
    # login_with takes a block that accepts two arguments, username
    # and password, which the caller should use to authenticate the
    # user.  If the user is authenticated, return an object
    # indicating this.  It will be stored along with the API token
    # for later use.

    Credential.authenticate(username, password)
  end
  
  config.signup_with do |username, password|
    # signup_with is essentially the same as login_with, with the
    # difference being that it rejects already-used emails and
    # creates a user before it is returned to the client.  It may
    # throw whatever errors it wishes, which will be passed along to
    # the client in JSON form.
    
    Credential.sign_up(username, password)
  end
  
  # authorize_with specifies the block to use to determine whether
  # a certain user is authorized to perform an action on a
  # resource.
  # - user is whatever authorize_with returns
  # - action is a symbol that is :index, :read, :create, :update, :destroy
  # - resource is an individual model or the model's class if a collection 
  config.authorize_with do |user, action, resource|
    # allowed = false
    # allowed = true if action == :create and resource == Person
    # allowed = true if action == :read and resource.class == Person and resource.id == 1
    # Rails.logger.debug("user = '#{user}' -- action = '#{action} -- resource-type = '#{resource.class.to_s}' -- resource = '#{resource}'")
    # allowed
    true
  end

  # You may also elect to use OmniAuth to allow for user sign in and
  # sign up.  To connect these dots, you must add a glue-function to
  # connect to whatever authentication package you are using.

  config.oauth_with do |hash|
    Credential.authenticate_oauth(hash)
  end

  # Built-in support for facebook requires that you simply add in the
  # app ID and app secret for your app:
  # config.use_facebook app_id: '<APP_ID>', app_secret: '<APP SECRET>'

  # Other options:
  #
  # You may read about the other options in lib/generic_api_rails/config.rb
end
