json.extract! @credential
json.email @credential.email.address
json.person_id @credential.member.person.id
json.member_id @credential.member.id
json.token @api_token.token
json.id @credential.member.person.id
json.api_server_url(@credential.api_server_url) if not @credential.api_server_url.blank?
