if template_exists?((tmpl="generic_api_rails/#{@model.new.to_partial_path}"),[],true)
  json.array! collection, partial: tmpl, as: @model.model_name.element
elsif template_exists?(tmpl="generic_api_rails/base/item",[],true)
  json.array! collection, partial: tmpl, as: :item
else
  json.array! collection
end
