if template_exists?((tmpl="generic_api_rails/#{@model.name.underscore.pluralize}/#{@model.name.underscore}"),[],true)
  json.array! collection, partial: tmpl, as: @model.name.underscore.to_sym
elsif template_exists?(tmpl="generic_api_rails/base/item",[],true)
  json.array! collection, partial: tmpl, as: :item
else
  json.array! collection
end
