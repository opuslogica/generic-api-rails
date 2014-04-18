module GenericApiRails
  module Config
    DEFAULT_ERROR_TRANSFORM = proc { |hash| hash }

    class << self
      # authenticate_with receives a @params and @request hashes that
      # give the block access to all of the inputs from the request.
      # It must sort out api tokens, etc (for every API call), and
      # return an "authenticated" object, which will be used later to
      # check for permissions and do on.  The exact object type/etc is
      # irrelevant to the API server, and is only used to ask
      # questions later about whether or not the current API caller is
      # authorized to perform some action (including read) a resource.
      def authenticate_with(&blk)
        @authenticate_with = blk if blk
        @authenticate_with
      end
      
      # login_with takes the same @params and @request hash that
      # authenticate_with does, but only is called once per session,
      # to give the user some way to authenticate for later api calls.
      # Whatever it returns is directly returned as a JSON blob to the
      # client.  Make sure that the client knows how to turn whatever
      # is returned by this into something that is readable by
      # authenticate_with!
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
