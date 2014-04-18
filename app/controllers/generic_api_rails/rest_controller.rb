module GenericApiRails
  class RestController < BaseController
    before_filter :model

    def model
      @model ||= params[:model].singularize.camelize.constantize
    end

    rescue_from NotAuthorizedError do |e|
      render :json => { :error => "Not authorized" } , :status => 403
    end

    def authorize! resource
      auth_with = GenericApiRails.config.authorize_with

      unless auth_with.call(@authorized,params[:action].to_sym,resource)
        raise NotAuthorizedError
      end
    end

    def id_list
      ids = params[:ids].split ','
      r = model.where(:id => ids)
      
      authorize! :read , r
      render :json => r
    end
    
    def index
      if params[:ids]
        id_list
      else
        search_hash = {}
        do_search = false
        model.columns.each do |c|
          name = c.name
          search_hash[name.to_sym] = params[name] and do_search=true if params[name]
        end
        
        if do_search
          r = model.where(search_hash)
        else
          r = model.all
        end
        
        r = r.limit(1000)

        authorize! r

        render :json => r
      end
    end

    def show
      @resource = @model.find(params[:id])
      authorize! @resource
      render :json => @resource
    end

    def create
      hash = params[model.table_name.singularize]

      r = model.new()
      r.update_attributes(hash)
      authorize! r
      r.save

      render :json => r
    end

    def update
      hash = params[model.table_name.singularize]

      r = model.find(params[:id])
      r.update_attributes(hash)
      authorize! r
      r.save

      render :json => r
    end

    def destroy
      r = model.find(params[:id])
      authorize! r
      r.destroy!
      
      render :json => { success: true }
    end
  end
end
