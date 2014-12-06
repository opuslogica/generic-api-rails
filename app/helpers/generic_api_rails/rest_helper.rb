module GenericApiRails
  module RestHelper
    def template_exists?(name,prefixes=[],partial=false,keys=[],options={})
      @cached_controller ||= ApplicationController.new
      @cached_controller.template_exists?(name,prefixes,partial,keys,options)
    end
  end
end
