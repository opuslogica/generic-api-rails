if template_exists?((tmpl="generic_api_rails/#{@model.name.pluralize.downcase}/#{@model.name.downcase}"),[],true)
  json.unsupported true
else
  attrs = item.as_json
  json.extract! attrs,*attrs.keys
end
