module GenericApiRails
  class BaseController << ::ApplicationController
    before_filter :cors_set_access_control_headers
    before_filter :cors_preflight_check
    before_filter :api_setup

    skip_before_filter :verify_authenticity_token, :only => [:options]
    
    def options
    end

    # For all responses in this controller, return the CORS access control headers.
    def cors_set_access_control_headers
      response.headers['Access-Control-Allow-Origin'] = '*'
      response.headers['Access-Control-Allow-Credentials'] = 'true'
      response.headers['Access-Control-Allow-Methods'] = 'GET, PUT, POST, DELETE, OPTIONS, PATCH'
      response.headers['Access-Control-Max-Age'] = "1728000"
      response.headers['Access-Control-Allow-Headers'] = 'X-CSRF-Token, X-Requested-With, X-Prototype-Version, content-type, api-token, bzu-client-id'
    end

    # If this is a preflight OPTIONS request, then short-circuit the
    # request, return only the necessary headers and return an empty
    # text/plain.
    def cors_preflight_check
      if request.method == "OPTIONS"
        headers['Access-Control-Allow-Origin'] = '*'
        headers['Access-Control-Allow-Methods'] = 'GET, PUT, POST, DELETE, OPTIONS, PATCH'
        headers['Access-Control-Allow-Headers'] = 'X-CSRF-Token, X-Requested-With, X-Prototype-Version, content-type, api-token, bzu-client-id'
        headers['Access-Control-Max-Age'] = '1728000'
        render :text => '', :content_type => 'text/plain'
      end
    end

    def api_setup
      @params = params
      @request = request

      begin
        @authenticated = instance_eval(Config.config.authenticate_with)
      rescue => e
        render_result( { :error => "Error authenticating." } , 403 ) and return false
      end
      
      @action = params[:action]
      @controller = params[:controller]
      
      @arguments = params.reject { |k,v| %w(api_token api-token controller action id ids api quick shallow created_at updated_at).include?(k) }
    end

  end
end
