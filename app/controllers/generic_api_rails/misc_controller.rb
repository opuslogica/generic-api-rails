module GenericApiRails
  class MiscController < BaseController
    def version
      render json: { version: "1.0" }
    end

    def whoami
      render json: (@authenticated ? @authenticated : { error: "Nobody!" })
    end
  end
end
    
    
