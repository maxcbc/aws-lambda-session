resource "aws_iam_group_policy" "group_policy" {
  name  = "aws-lambda-session-sls-policy"
  group = aws_iam_group.participants.name

  policy = data.aws_iam_policy_document.sls_deploy.json
}

data "aws_iam_policy_document" "sls_deploy" {

  statement {
    effect  = "Allow"
    actions = [
      "cloudformation:*"
    ]
    resources = [
      "arn:aws:cloudformation:*:*:stack/aws-lambda-session*"
    ]
  }
  statement {
    effect  = "Allow"
    actions = [
      "cloudformation:ValidateTemplate"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect  = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::aws-lambda-session*"
    ]
  }
  statement {
    actions = [
      "logs:*"
    ]
    resources = [
      "arn:aws:logs:*:*:log-group:/aws/lambda/aws-lambda-session*:log-stream:*"
    ]
    effect    = "Allow"
  }
  statement {
    effect  = "Allow"
    actions = [
      "iam:GetRole",
      "iam:PassRole",
      "iam:CreateRole",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:DeleteRole",
      "iam:DetachRolePolicy",
      "iam:GetRolePolicy",
      "iam:PutRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DeleteRolePolicy"
    ]
    resources = [
      "arn:aws:iam::*:role/aws-lambda-session-*-lambdaRole"
    ]
  }
  statement {
    effect  = "Allow"
    actions = [
      "apigateway:GET",
      "apigateway:POST",
      "apigateway:PUT",
      "apigateway:DELETE",
      "apigateway:PATCH"
    ]
    resources = [
      "arn:aws:apigateway:*::/tags*",
      "arn:aws:apigateway:*::/restapis*",
      "arn:aws:apigateway:*::/apikeys*",
      "arn:aws:apigateway:*::/usageplans*"
    ]
  }
  statement {
    effect  = "Allow"
    actions = [
      "lambda:*"
    ]
    resources = [
      "arn:aws:lambda:*:*:function:aws-lambda-session-*"
    ]
  }
  statement {
    effect  = "Allow"
    actions = [
      "events:Put*",
      "events:Remove*",
      "events:Delete*",
      "events:Describe*"
    ]
    resources = [
      "arn:aws:events:*:*:rule/aws-lambda-session-*"
    ]
  }
  statement {
    effect  = "Allow"
    actions = [
      "sqs:*",
    ]
    resources = [
      "arn:aws:sqs:*:*:aws-lambda-session-*"
    ]
  }
  statement {
    effect  = "Allow"
    actions = [
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:GetMetricData",
      "lambda:GetAccountSettings",
      "lambda:CreateEventSourceMapping",
      "lambda:GetEventSourceMapping",
      "lambda:DeleteEventSourceMapping",
      "lambda:ListEventSourceMappings",
      "lambda:ListFunctions",
      "cloudformation:ListStacks",
      "iam:ListPolicies",
      "sqs:ListQueues",
      "s3:ListBuckets",
      "s3:ListAllMyBuckets"
    ]
    resources = [
      "*"
    ]
  }
}
