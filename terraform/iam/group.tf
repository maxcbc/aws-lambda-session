resource "aws_iam_group" "participants" {
  name = "aws-lambda-session-participants"
  path = "/users/"
}
