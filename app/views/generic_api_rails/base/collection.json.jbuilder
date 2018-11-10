simple = GenericApiRails.config.simple_api rescue nil
if template_exists?((tmpl="generic_api_rails/#{@model.new.to_partial_path}"),[],true)
  if simple
    json.array! collection, partial: tmpl
  else
    json.array! collection, partial: tmpl, as: @model.model_name.element
  end
elsif template_exists?(tmpl="generic_api_rails/base/item",[],true)
  if simple
    json.array! collection, partial: tmpl
  elsif total
    json.total count
    json.array! collection, partial: tmpl, as: :row # untested
  else
    json.array! collection, partial: tmpl, as: :item
  end
else
  if simple
    json.array! collection
  elsif total
    json.total total
    json.rows collection
  else
    json.array! collection
  end
end
