#!/usr/bin/env bash


jq -c '.[]' "credentials.json" | while read USER; do
    # do stuff with $i
    echo $USER
    USERNAME="$(echo $USER | jq -r '.user')"
    PASSWORD="$(echo $USER | jq -r '.password')"
    AWS_ACCESS_KEY_ID="$(echo $USER | jq -r '.access_key_id')"
    AWS_SECRET_ACCESS_KEY="$(echo $USER | jq -r '.secret_access_key')"
    read -r -d '' TEMPLATE << EOM
{
  "title": "${USERNAME} | aws-lambda-session | AWS",
  "category": "LOGIN",
  "vault": {
    "name": "TEMP"
  },
  "urls": [
    {
      "label": "website",
      "primary": true,
      "href": "https://maxcbc.signin.aws.amazon.com"
    }
  ],
  "sections": [
    {
      "id": "console"
    },
    {
      "id": "cli"
    }
  ],
  "fields": [
    {
      "id": "username",
      "type": "STRING",
      "purpose": "USERNAME",
      "label": "username",
      "value": "$USERNAME",
      "section": {
        "id": "console"
      }
    },
    {
      "id": "password",
      "type": "CONCEALED",
      "purpose": "PASSWORD",
      "label": "password",
      "value": "$PASSWORD",
      "section": {
        "id": "console"
      }
    },
    {
      "type": "STRING",
      "label": "AWS_ACCESS_KEY_ID",
      "value": "$AWS_ACCESS_KEY_ID",
      "section": {
        "id": "cli"
      }
    },
    {
      "type": "STRING",
      "label": "AWS_SECRET_ACCESS_KEY",
      "value": "$AWS_SECRET_ACCESS_KEY",
      "section": {
        "id": "cli"
      }
    }
  ]
}
EOM
    echo "$TEMPLATE" | op item create

done
