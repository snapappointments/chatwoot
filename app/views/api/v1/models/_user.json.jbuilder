json.id resource.id
json.provider resource.provider
json.uid resource.uid
json.name resource.name
json.nickname resource.nickname
json.email resource.email
json.account_id resource.active_account_user&.account_id
json.pubsub_token resource.pubsub_token
json.role resource.active_account_user&.role
json.inviter_id resource.active_account_user&.inviter_id
json.confirmed resource.confirmed?
json.avatar_url resource.avatar_url
json.access_token resource.access_token.token
json.availability_status resource.availability_status
json.accounts do
  json.array! resource.account_users do |account_user|
    json.id account_user.account_id
    json.name account_user.account.name
    json.active_at account_user.active_at
    json.role account_user.role
  end
end
