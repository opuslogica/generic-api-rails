if template_exists?((tmpl="generic_api_rails/#{@model.name.pluralize.downcase}/#{@model.name.downcase}"),[],true)
  json.array! collection, partial: tmpl, as: @model.name.downcase.to_sym
elsif template_exists?(tmpl="generic_api_rails/base/item",[],true)
  json.array! collection, partial: tmpl, as: :item
else
  json.array! collection
end
