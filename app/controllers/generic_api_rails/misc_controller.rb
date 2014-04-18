module GenericApiRails
  class MiscController < BaseController
    def version
      render :json => { version: "1" }
    end

    def whoami
      render :json => @credential.as_json if @credential
      render :json => { error: "Nobody!" } if not @credential
    end
  end
end
    
    
