module GenericApiRails
  module Config
    DEFAULT_ERROR_TRANSFORM = proc { |hash| hash }

    class << self
      # session_authentication_method specifies what controller action
      # GenercApiRails should use to process/activate session-based
      # authentication.  Whatever method specified (as a symbol) must
      # be defined on ApplicationController (or monkey-patched into
      # GenericApiRails::BaseController) and must return an object
      # that represents the authenticated user.
      def session_authentication_method(sym=nil)
        @session_authentication_method = sym if sym
        @session_authentication_method
      end

      # login_with takes a block that accepts two arguments, username
      # and password, which the caller should use to authenticate the
      # user.  If the user is authenticated, return an object
      # indicating this.  It will be stored along with the API token
      # for later use.
      def login_with(&blk)
        @login_with = blk if blk
        @login_with
      end

      # signup_with is essentially the same as login_with, with the
      # difference being that it rejects already-used emails and
      # creates a user before it is returned to the client.  It may
      # throw whatever errors it wishes, which will be passed along to
      # the client in JSON form.
      def signup_with(&blk)
        @sign_up_with = blk if blk
        @sign_up_with
      end

      # For OAuth purposes, the API server tries to smoothen
      # differences between different authorization providers and
      # calls omniauth_with with a provider, uid, and email for
      # account creation and/or authorization.  Similar to login_with
      # and signup_with, omniauth_with must return a JSON hash that
      # will tell the user how to authenticate in the future.
      def oauth_with(&blk)
        @oauth_with = blk if blk
        @oauth_with
      end

      # authorize_with specifies the block to use to determine whether
      # a certain user is authorized to perform an action on a
      # resource.  The block should be of the form:
      # config.authorize_with do |user,action,resource|
      #
      # - user is whatever authorize_with returns
      # - action is a symbol that is :index, :show, :create, :update, :destroy
      # - resource is an individual model or collection 
      def authorize_with(&blk)
        @authorize_with = blk if blk
        @authorize_with
      end

      # transform_error_with allows you to be more specific with
      # how API errors are displayed to the user, by default just the
      # description is sent to the user with an HTTP status code.

      def transform_error_with(&blk)
        @transform_error_with = blk if blk
        @transform_error_with || DEFAULT_ERROR_TRANSFORM
      end

      # Here are some pieces of configuration that allow for the
      # definition of special-case search terms.  Using these, you can
      # specify an API route like:
      #
      # /api/widgets?wodget_ids=8,6,2
      #
      # using the call:
      #
      # config.search_for Widget, :wodget_ids do |wodget_ids|
      #   Widget.search_using_wodgets(Wodget.where(:id => wodget_ids.split(',')))
      # end
      def search_for(model, symbol, &blk)
        @search_helpers ||= Hash.new
        model_specific = @search_helpers[model.to_s] ||= Hash.new

        model_specific[symbol] = blk if blk

        model_specific[symbol]
      end
      
      # Enable facebook-based API authentication in the app (requires
      # :app_id and :app_secret):
      def use_facebook(hash)
        @facebook_hash = hash
        @facebook_hash
      end

      def use_facebook?
        !!@facebook_hash
      end

      def facebook_hash
        @facebook_hash
      end
    end
  end
end
