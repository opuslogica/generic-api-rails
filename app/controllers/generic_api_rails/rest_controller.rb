module GenericApiRails
  class RestController < BaseController
    before_filter :setup
    before_filter :model
    skip_before_filter :verify_authenticity_token

    def render_json(data)

      simple = GenericApiRails.config.simple_api rescue nil

      render_one = lambda do |m|
        include = m.class.reflect_on_all_associations.select do 
          |a| a.macro == :has_and_belongs_to_many or a.macro == :has_one
        end.map do |a|
          h = {}
          h[a.name] = { only: [:id] }
          h
        end.inject({}) do |a,b|
          a.merge b
        end 

        include = include.merge @include if @include

        h = m.as_json(for_member: (@authenticated.member rescue nil), include: include)
        h = { model: h } if not simple
        if m.errors.keys
          h[:errors] = m.errors.messages
        end
        h
      end
      
      if data.respond_to?(:collect)
        meta = {}
        if data.respond_to?(:count)
          meta[:total] = data.count
        end

        data = data.limit(@limit) if @limit
        data = data.offset(@offset) if @offset

        meta[:rows] = data.collect(&render_one)
        meta = meta[:rows] if simple
        render json: meta
      else
        render json: render_one.call(data)
      end
    end

    def setup
      @rest = params[:rest]
      @action = params[:action]
      @controller = self
    end

    def model
      namespace ||= params[:namespace].camelize if params.has_key? :namespace
      model_name ||= params[:model].singularize.camelize
      if namespace
        qualified_name = "#{namespace}::#{model_name}" 
      else
        qualified_name = model_name
      end
      @model = qualified_name.constantize
    end

    def authorized?(action, resource)
      GenericApiRails.config.authorize_with.call(@authenticated, action, resource)
    end

    def id_list
      ids = params[:ids].split ','
      @instances = model.where(id: ids)
      
      render_error(ApiError::UNAUTHORIZED) and return false unless authorized?(:read, @instances)

      render_json @instances
    end
    
    def index
      query_begin = nil

      if params[:ids]
        id_list
      else
        search_hash = {}
        do_search = false
        special_handler = false

        @instances = nil

        params.each do |key, value|
          unless special_handler
            special_handler ||= GenericApiRails.config.search_for(@model, key)
            special_handler ||= GenericApiRails.config.search_for(@model, key.to_sym)
            if special_handler
              Rails.logger.info("CALLING SPECIAL HANDLER #{@model} :#{key.to_sym} with #{value}")
              @instances = instance_exec(value, &special_handler)
            end
          end
        end

        unless special_handler
          column_syms = model.columns.collect {|c| c.name.to_sym}
          params.each do |key, val|
            if column_syms.include?(key.to_sym)
              search_hash[key.to_sym] = val
              do_search = true
            elsif /.*_id$/.match(key.to_s)
              # This is an ID column, but our model doesn't "belong_to" this thing. So,
              # this thing must belong to us, whether through a join table or not.  Thus,
              #
              #       GET /api/addresses?person_id=12
              #
              # means, Person.find(12).addressess...
              # 
              other_model = (key.to_s.gsub(/_id$/, "").camelize.safe_constantize).new.class rescue nil
              begin
                query_begin = (other_model.find(val)).send(@model.name.tableize.to_sym) if other_model
              rescue ActiveRecord::RecordNotFound
                Rails.logger.info("GAR: Error finding the requested #{other_model.name}: #{val}")
                render_error(ApiError::UNAUTHORIZED) and return false
              end
            end
          end
        end

        query_begin ||= model
        if do_search
          @instances = query_begin.where(search_hash)
          render_error(ApiError::UNAUTHORIZED) and return false unless authorized?(:read, @instances)
        elsif special_handler
          render_error(ApiError::UNAUTHORIZED) and return false unless authorized?(:read, @instances)
        else
          render_error(ApiError::UNAUTHORIZED) and return false unless authorized?(:index, model)
          @instances = query_begin.all
        end
        
        @limit = params[:limit]
        @offset = params[:offset]
        @include = JSON.parse(params[:include]) rescue {}

        render_json(@instances)
      end
    end

    def read
      @instance = @model.find(params[:id]) rescue nil
      @include = JSON.parse(params[:include]) rescue {}

      render_error(ApiError::UNAUTHORIZED) and return false unless authorized?(:read, @instance)

      render_json @instance
    end

    def create
      hash = params[:rest]
      hash ||= params
      @instance = model.new()

      hash.delete(:controller)
      hash.delete(:action)
      hash.delete(:model)
      hash.delete(:base)

      # params.require(:rest).permit(params[:rest].keys.collect { |k| k.to_sym })

      @instance.assign_attributes(hash.to_hash)

      render_error(ApiError::UNAUTHORIZED) and return false unless authorized?(:create, @instance)
      @instance.save
      # puts "INSTANCE: ", @instance.attributes.to_s
 
      render_json @instance
    end

    def update
      @instance = @model.find(params[:id])
      hash = params[:rest]
      hash ||= params
      hash = hash.to_hash.with_indifferent_access
      hash.delete(:controller)
      hash.delete(:action)
      hash.delete(:model)
      hash.delete(:id)
      @instance.assign_attributes(hash)

      render_error(ApiError::UNAUTHORIZED) and return false unless authorized?(:update, @instance)

      @instance.save

      render_json @instance
    end

    def destroy
      @instance = model.find(params[:id])

      render_error(ApiError::UNAUTHORIZED) and return false unless authorized?(:destroy, @instance)
      
      @instance.destroy!
      
      render json: { success: true }
    end
  end
end
