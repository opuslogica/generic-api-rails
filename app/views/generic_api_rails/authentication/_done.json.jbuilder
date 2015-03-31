json.extract! @credential
json.email @credential.email.address
json.person_id @credential.member.person.id
json.member_id @credential.member.id
json.token @api_token.token
