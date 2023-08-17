# AWS Lambda Session

## Overview - What is AWS Lambda? Is serverless really serverless?

So called "serverless" functions aren't really serverless.
All it means is that the cloud provider looks after the server for you, and you just worry about the
functionality/logic.

They are event driven pieces of logic run in the cloud.
They can be triggered by lots of different event types, such as DB changes, http requests or in response to items on a
queue.

AWS Lambda Functions are AWS' "serverless" compute offering.
Microsoft's Azure has its own "Azure functions" and Google's GCP has "Google Cloud Functions" in the same market.

There is also something called the "Serverless Framework", this is an abstraction around these different technologies.
It is effectively a specific "Infrastructure as Code" (IaC) solution for serverless functions which can be used with
multiple providers.

It is widely used in the software industry, and we'll be using it in this session.
We'll be learning about the framework, how it works, how AWS lambda works and about AWS more generally.

## Prerequisites

Install the serverless framework globally

```shell
npm i -g serverless
```

You'll need an AWS_ACCESS_KEY_ID and an AWS_SECRET_ACCESS_KEY set on your machine and access to the AWS console.
You can use credentials for your own AWS account, or Max can provide some for you.

## Structure
This training session is split into 1 part:
- [Part 1 | A Simple HTTP Serverless App](./part-1/README.md)


