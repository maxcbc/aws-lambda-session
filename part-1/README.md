# Part 1 - A Simple HTTP App

## Part 1a - Scaffolding your app

We'll use the serverless CLI to scaffold our basic serverless app. Run:  
```shell
serverless
```

- Select "AWS - Node.js - Starter".
- Call your project `aws-lambda-session-<initials>" where <initials> are your initials
- Answer `n` when asked "Do you want to login/register to Serverless Dashboard?"
- Answer `n` when asked "Do you want to deploy now?" (we'll come to this shortly)

You should now have an `aws-lambda-session-<initials>` directory containing some files.

Change into this directory, you should see an `index.js` file, which exports a `handler` function which takes an `event`
argument.
This is your "lambda function", when your function is called (the term "invoked" is used) the event
argument will contain information about the event which caused your function to be invoked.

The configuration for your function is in the `serverless.yml` file.
In this you'll see:

- service | the name of your project
- frameworkVersion | the version of the serverless framework you're using
- provider | general AWS configuration for all the functions contained in the config
- functions | configuration for individual functions within your project

In this you'll see that a function has been predefined for you as `function1` with a `handler` property
as `index.handler`.
This handler syntax can be a little confusing, but it follows the pattern `<filepath>.<exported function name>`, which
in this case means use `index.js` and find the exported property `handler`.

The serverless framework allows you to invoke your function locally, just run

```shell
serverless invoke local --function function1
```

You can also invoke it locally with a data argument, which gets passed as the event argument to your function. This can
be useful for testing your function

```shell
serverless invoke local --function function1 --data '{"hello": "world"}'
```

## Part 1b - Deploying your app

Next up we'll want to deploy your function. The serverless framework uses the term `stage` to refer to different
environments.
In effect this is just a suffix added to resource names when they're created in AWS. The default value is `dev` but
we'll set it explicitly for clarity.
To deploy simply run:

```shell
serverless deploy --stage dev
```

In the output, you'll see that serverless first packages your project up, uploads it and then creates and updates
something called a CloudFormation stack. We'll come onto what this all means shortly.

Once you're function is deployed, you can then invoke the deployed function, like before using the command:

```shell
serverless invoke --stage dev --function function1 --data '{"hello": "world"}'
```

You should have got the same output as before, but this time your function has been run on AWS. Well Done!

At this point, it's a good idea to understand what the serverless framework is doing for us here, under the covers.
When used with AWS, the serverless framework is effectively just a simplified abstraction of AWS' own 'CloudFormation'
IaC service. CloudFormation allows a user to group related AWS resources together in a 'Stack' with their properties
defined in a JSON or YAML based config file.
Users can provide CloudFormation with a config file and AWS will create all the resources defined in that config file in
a stack. Simply provide an updated config file and AWS will create, delete and/or modify the resources in the stack
accordingly.

When you deployed your function `serverless` created a `.serverless` directory.
Take a look inside, you'll see the following files:

- `cloudformation-template-create-stack.json`
- `cloudformation-template-update-stack.json`
- `aws-lambda-session-<initials>.zip`

During the deployment, serverless first creates a stack using the `cloudformation-template-create-stack.json` file.
This creates a s3 bucket, known as the deployment bucket.
Serverless then uploads `aws-lambda-session-<initials>.zip` to the bucket and
uses `cloudformation-template-update-stack.json` to update the Cloudformation stack and create your lambda and the
associated resources.

You can see
a [list of CloudFormation stacks in the AWS console](https://us-east-1.console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks).
If you click on your stacks name (it should be `aws-lambda-session-<initials>-dev`) and click "Resources" you can see
the list of AWS resources serverless has created for you.

## Part 1c - Adding a trigger

As mentioned above, your lambda functions can be triggered by many different types of events.
This could be a cron schedule, items being added to a queue or a http request. These events can all be configured via
your serverless.yml.
We'll add a simple http trigger to our function by updating the config to match the below.

```yaml
  function1:
    handler: index.handler
    events:
      - http:
          path: hello/{name}
          method: get
          request:
            parameters:
              paths:
                name: true
```

And update index.js to match the below

```js
module.exports.handler = async (event) => {
    return {
        statusCode: 200,
        headers: {
            'content-type': 'text/html'
        },
        body: `<h1 style="width: 100vw;text-align:center;margin-top: 40vh;">Hello ${event.pathParameters.name}</h1>`,
    };
};
```

Then re-deploy by running:

```shell
serverless deploy --stage dev
```

Once its deployed, you should see something like the below in the output:

```
endpoint: GET - https://x0n3h6ja64.execute-api.us-east-1.amazonaws.com/dev/hello/{name}
```

Visit that link in the browser, replacing `{name}` with your name.

Look at your stack's resources via
the [AWS console](https://us-east-1.console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks).
You'll see serverless has created Amazon API Gateway resources to make your function accessible via the internet.

## Part 1d - A note on costs, scaling and usage

AWS Lambda functions are incredibly cheap to run. They are charged by how much they're used; using a combination of
number of invocations,
execution time and memory usage. Prices start at $0.0000166667 for every GB-second of execution time plus $0.20 per 1M
requests; however you get 1M free requests per month and 400,000 GB-seconds of free compute time per month. Because
you're charged by usage, this means that if your functions aren't invoked, you don't get charged.

Not only that, AWS automatically scales the number of concurrent 'executors' of your function to meet demand until you
reach your account's concurrency limit. By default, AWS provides your account with a total concurrency limit of 1,000
across all functions in a region though this can be increased on request.

If it's so cheap, why isn't everything built using serverless? Three key reasons:

- If you're running lots of concurrent functions, and/or running continuously, it's actually cheaper to just run
  something on a server.
- Lambda functions can only run for a maximum time of 15 minutes. If you're running a process that takes longer that
  can't be split up, then you can't run it on Lambdas.
- Lambdas suffer from a problem called cold start times. When a new executor is started for your function, it first
  needs to download our code to the executor and provision it with the memory, runtime and other configuration
  specified. All this takes time, perhaps 200-400ms, meaning it can affect the performance of your service. While this
  issue can be mitigated by paying to keep a certain number of executors 'warm' at any time, it cannot be completely
  eliminated.

That said, there are many sites which run everything in Lambdas. If a site has limited dynamic content, or is a Single
Page App, it can be very cheap to host the site as static assets on s3 and use lambdas for API calls to progressively
enhance the site with data.
Alternatively, if the site has a lot of dynamic data but is cachable on a CDN, lambdas can act as a very cheap and
scalable backend.

Anyway, back to our project. At the end of any session it's always a good idea to spin down your dev environment, so let's do that now with:
```shell
serverless remove --stage dev
```
Serverless will then tell Cloudformation to remove all the resources in the stack and then delete the stack.