variable "participant_names" {
  type = list(string)
}

resource "aws_iam_user" "participants" {
  for_each = toset(var.participant_names)
  name = "aws-lambda-session-user-${each.key}"
}

resource "aws_iam_group_membership" "participants" {
  name = "aws-lambda-session-participant-group-membership"

  users = [
    for user in aws_iam_user.participants:
    user.name
  ]

  group = aws_iam_group.participants.name
}

resource "aws_iam_user_login_profile" "participants" {
  for_each = aws_iam_user.participants
  user    = each.value.name
}

resource "aws_iam_access_key" "participant_key" {
  for_each = aws_iam_user.participants
  user    = each.value.name
}

output "user_profiles" {
  value = toset([
  for profile in aws_iam_user_login_profile.participants : { user = profile.user, password = profile.password }
  ])
}


output "user_access_keys" {
  value = toset([
    for key in aws_iam_access_key.participant_key : { user = key.user, aws_access_key_id = key.id, aws_secret_access_key = key.secret }
  ])
}