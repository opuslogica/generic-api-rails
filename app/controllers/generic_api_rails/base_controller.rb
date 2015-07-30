module GenericApiRails
  class BaseController < ::ApplicationController
    before_filter :cors_set_access_control_headers
    before_filter :cors_preflight_check
    before_filter :api_setup

    skip_before_filter :verify_authenticity_token, :only => [:options]

    rescue_from ActiveRecord::RecordNotFound, with: :render_404
    
    def options
    end

    # For all responses in this controller, return the CORS access control headers.
    def cors_set_access_control_headers
      response.headers['Access-Control-Allow-Origin'] = '*'
      response.headers['Access-Control-Allow-Credentials'] = 'true'
      response.headers['Access-Control-Allow-Methods'] = 'GET, PUT, POST, DELETE, OPTIONS, PATCH'
      response.headers['Access-Control-Max-Age'] = "1728000"
      response.headers['Access-Control-Allow-Headers'] = 'X-CSRF-Token, X-Requested-With, X-Prototype-Version, content-type, api-token'
    end

    # If this is a preflight OPTIONS request, then short-circuit the
    # request, return only the necessary headers and return an empty
    # text/plain.
    def cors_preflight_check
      if request.method == "OPTIONS"
        headers['Access-Control-Allow-Origin'] = '*'
        headers['Access-Control-Allow-Methods'] = 'GET, PUT, POST, DELETE, OPTIONS, PATCH'
        headers['Access-Control-Allow-Headers'] = 'X-CSRF-Token, X-Requested-With, X-Prototype-Version, content-type, api-token'
        headers['Access-Control-Max-Age'] = '1728000'
        render(text: '', content_type: 'text/plain')
        false
      end
      true
    end

    def authorized?(action, resource)
      GenericApiRails.config.authorize_with.call(@authenticated, action, resource)
    end

    def api_setup
      @params = params
      @request = request

      incoming_token = params[:api_token] || request.headers['api-token']
      @api_token = api_token = ApiToken.find_by_token(incoming_token) if incoming_token

      credential = api_token.credential if api_token
      token = api_token.token if api_token
      
      if api_token and not token
        api_token.delete if api_token
        raise ApiError.find(ApiError::INVALID_API_TOKEN)
      end
      
      @authenticated = credential

      s = GenericApiRails.config.session_authentication_method
      send(s) if s
      
      @action = params[:action]
      @controller = params[:controller]
      @arguments = params[:rest]
    end

    def render_error(error_code, extra_hash_members={})
      apierr = ApiError.find_by_code(error_code)
      
      errhash = { :error => apierr.as_json({}) }.merge(extra_hash_members)
      
      errhash = GenericApiRails.config.transform_error_with.call(errhash)

      # logger.info "ERRHASH #{errhash}"
      render_result(errhash, apierr.status_code)
    end

    def render_result(hash={:error => "unknown error!"}, status=200)
      render :json => hash.as_json({}), :status => status
    end

    @private
    def render_404
      errhash = { :error =>  { description: "Record not found" , code: 404, status_code: 404 } }
      errhash = GenericApiRails.config.transform_error_with.call(errhash)
      render :json => errhash , :status => 404
    end
  end
end
