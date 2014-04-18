require "generic_api_rails/version"
require "generic_api_rails/engine"
require "generic_api_rails/config"

module GenericApiRails
  def self.config(&block)
    if block
      block.call(GenericApiRails::Config)
    else
      GenericApiRails::Config
    end
  end
end
