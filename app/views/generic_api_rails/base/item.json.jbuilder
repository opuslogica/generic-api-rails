if template_exists?((tmpl="generic_api_rails/#{@model.name.pluralize.downcase}/#{@model.name.downcase}"), [], true)
  locals = {}
  locals[@model.name.downcase.singularize.to_sym] = item
  json.partial!(tmpl, locals)
else
  # this is not ideal, is it?
  attrs = item.as_json(for_member: (@authenticated.member rescue nil))
  json.extract!(attrs, *attrs.keys)
end
