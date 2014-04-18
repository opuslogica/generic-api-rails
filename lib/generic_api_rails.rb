require "generic_api_rails/version"
require "generic_api_rails/engine"
require "generic_api_rails/config"

module GenericApiRails
  def self.config(&block)
    if block
      block.call(WebLogin::Config)
    else
      WebLogin::Config
    end
  end
end
