module GenericApiRails
  class RestController < BaseController
    before_filter :model
    
    def model
      @model ||= params[:model].singularize.camelize.constantize
    end

    def authorized?(action, resource)
      GenericApiRails.config.authorize_with.call(@authorized, action, resource)
    end

    def id_list
      ids = params[:ids].split ','
      r = model.where(:id => ids)
      
      render_error(ApiError::UNAUTHORIZED) and return false unless authorized?(:read, r)

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
          render_error(ApiError:UNAUTHORIZED) and return false unless authorized?(:read, r)

        else
          render_error(ApiError::UNAUTHORIZED) and return false unless authorized?(:index, model)
          r = model.all
        end
        
        r = r.limit(1000)

        render :json => r
      end
    end

    def read
      @resource = @model.find(params[:id])

      render_error(ApiError::UNAUTHORIZED) and return false unless authorized?(:read, @resource)

      render :json => @resource
    end

    def create
      hash = params[model.table_name.singularize]

      r = model.new()
      r.update_attributes(hash)

      render_error(ApiError::UNAUTHORIZED) and return false unless authorized?(:create, r)

      r.save

      render :json => r
    end

    def update
      hash = params[model.table_name.singularize]

      r = model.find(params[:id])
      r.update_attributes(hash)

      render_error(ApiError::UNAUTHORIZED) and return false unless authorized?(:update, r)

      r.save

      render :json => r
    end

    def destroy
      r = model.find(params[:id])

      render_error(ApiError::UNAUTHORIZED) and return false unless authorized?(:destroy, r)

      r.destroy!
      
      render :json => { success: true }
    end
  end
end
