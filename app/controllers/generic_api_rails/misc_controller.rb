module GenericApiRails
  class MiscController < BaseController
    def version
      render :json => { version: "1" }
    end

    def whoami
      render :json => @authenticated.as_json if @authenticated
      render :json => { error: "Nobody!" } if not @authenticated
    end
  end
end
    
    
