terraform {
  backend "s3" {
    region         = "eu-west-1"
    bucket         = "maxcbc-terraform"
    dynamodb_table = "maxcbc-terraform"
    encrypt        = true
    key            = "aws-lambda-session/main.tfstate"
  }
}

locals {
  participant_names = [
    "MBC",
    "NW",
    "LG"
  ]
}

provider "aws" {
  region = "eu-west-1"
}

module iam {
  source            = "./iam"
  participant_names = local.participant_names
}

resource "local_file" "creds" {
  for_each = toset(local.participant_names)
  content  = jsonencode({
    profiles : module.iam.user_profiles,
    access_keys : module.iam.user_access_keys
  })
  filename = "credentials.json"
}