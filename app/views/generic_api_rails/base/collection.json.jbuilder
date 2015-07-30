if template_exists?((tmpl="generic_api_rails/#{@model.new.to_partial_path}"),[],true)
  json.array! collection, partial: tmpl, as: @model.model_name.element
elsif template_exists?(tmpl="generic_api_rails/base/item",[],true)
  if total
    json.total count
    json.array! collection, partial: tmpl, as: :row # untested
  else
    json.array! collection, partial: tmpl, as: :item
  end
else
  if total
    json.total total
    json.rows collection
  else
    json.array! collection
  end
end
