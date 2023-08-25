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

output "user_credentials" {
  value = toset([
  for participant in toset(var.participant_names) : {
      user = aws_iam_user_login_profile.participants[participant].user,
      password = aws_iam_user_login_profile.participants[participant].password,
      access_key_id = aws_iam_access_key.participant_key[participant].id,
      secret_access_key = aws_iam_access_key.participant_key[participant].secret
    }
  ])
}

