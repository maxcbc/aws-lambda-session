# Part 2 - Plugins & Resources

Let's start by re-deploying the app from part 1 by running:

```shell
serverless deploy --stage dev
```

## Part 2a - Plugins

Serverless is an extensible framework, meaning its possible to write custom plugins to add new features to the
framework. Indeed, there are many community plugins available on NPM.

By way of example we're going to install the typescript plugin, allowing us to convert our js handler code to
typescript.
First initialise a package.json and then install both the plugin and typescript itself from npm.

```shell
npm init -y
npm install -D serverless-plugin-typescript typescript
```

Then add the following line to your serverless.yml to tell serverless to use the plugin:

```yaml
plugins:
  - serverless-plugin-typescript
```

Rename your `index.js` file to `index.ts`:

```shell
mv index.js index.ts
```

Now our app will work as it is, but seeing as we're now writing typescript we can use some types from the `aws-lambda`
package to make our incoming event easier to use.

```shell
npm i -D aws-lambda @types/aws-lambda
```

And so we can update our handler code to:

```ts
import {Handler, APIGatewayProxyEvent, APIGatewayProxyResult} from 'aws-lambda';

export const handler: Handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
    return {
        statusCode: 200,
        headers: {
            'content-type': 'text/html'
        },
        body: `<h1 style="width: 100vw;text-align:center;margin-top: 40vh;">Hello ${event.pathParameters.name}</h1>`,
    };
};
```

And off we go and deploy.

```shell
serverless deploy --stage dev
```

And our page works as before, but we've now written it in typescript.

There are lots of [other plugins](https://www.serverless.com/plugins) out there, and we can't play with them all. A
notable shout out should be made to the [serverless-http](https://www.serverless.com/plugins/serverless-http) which
allows you to run a traditional node server (or using express, koa or hapi) via serverless.

## Part 2b - Adding additional resources

Sometimes when you're writing a serverless app, you need to add other AWS resources to your app such as a datastore.

Were going to update our app to save each `name` it is provided, and how many times it has been provided that name to a
file in a dedicated s3 bucket.
To do this we'll first want to add a bucket to our infrastructure.

This can be done easily by adding
the [appropriate config](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket.html)
to `serverless.yml` in the `Resources` object.
This object is a place where you can extend the CloudFormation config that serverless creates itself, for example by
adding your own CloudFormation resources.
Via this method you can provision any type of AWS resource you need, inline with the rest of your app.
We'll add our s3 bucket by adding the below (note the nested `resources.Resources` is deliberate as this tells
serverless to add this to the equivalent part of the Cloudformation config):

```yaml
resources:
  Resources:
    NameBucket:
      Type: 'AWS::S3::Bucket'
      DeletionPolicy: Delete
```

We'll also need to expose the name of the bucket to our lambda in an environment variable.
We can do this by using a CloudFormation Reference. This allows us to use the name of one resource in our cloudformation
config, in the definition of another resource (in this case our lambda). Simply add the following to the function
definition in `serverless.yml`:

```yml
    environment:
      NAME_BUCKET: !Ref NameBucket
```

We can now deploy this and our bucket will be created:

```shell
  serverless deploy --stage dev
```

You should then be able to see the s3 bucket in
the [cloudformation console](https://us-east-1.console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks). If
you go to your function in
the [lambda console](https://us-east-1.console.aws.amazon.com/lambda/home?region=us-east-1#/functions), and go to
_Configuration > Environment variables_ you should see the NAME_BUCKET variable has been populated.

We then need to update our code to store the `name` in the bucket.

Let's add a `lib/store-name.ts` with the following code

```ts
import {
    GetObjectCommand,
    GetObjectCommandOutput,
    PutObjectCommand,
    S3Client
} from "@aws-sdk/client-s3";

type NameStore = { [key: string]: number }
const client = new S3Client();
const params = {
    Bucket: process.env.NAME_BUCKET,
    Key: "names.json"
}

export async function storeName(name: string): Promise<void> {
    const existingNames = await getCurrentNames()

    if (!existingNames[name]) {
        existingNames[name] = 0
    }

    existingNames[name]++

    await client.send(new PutObjectCommand({
        ...params,
        Body: JSON.stringify(existingNames)
    }))

}

async function getCurrentNames(): Promise<NameStore> {
    const result = await getObjectIfExists()
    if (!result || !result.Body) {
        return {}
    }
    const body = await result.Body.transformToString();
    return JSON.parse(body)
}

async function getObjectIfExists(): Promise<GetObjectCommandOutput | undefined> {
    let result
    try {
        result = await client.send(new GetObjectCommand(params))

    } catch (e) {
        if (e.Code !== "NoSuchKey") {
            throw e
        }
    }
    return result
}
```

We'll then update our handler in `index.ts` to call this function.

```ts
import {Handler, APIGatewayProxyEvent, APIGatewayProxyResult} from 'aws-lambda';
import {storeName} from "./lib/store-name";

export const handler: Handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {

    const name = event.pathParameters.name

    await storeName(name)

    return {
        statusCode: 200,
        headers: {
            'content-type': 'text/html'
        },
        body: `<h1 style="width: 100vw;text-align:center;margin-top: 40vh;">Hello ${name}</h1>`,
    };
};
```

Lets deploy:

```shell
  serverless deploy --stage dev
```

Then go to our url and see what happens.
You'll get an internal server error. The issue is, our function doesn't have permission to access our bucket. To do this
we need to update its execution policy, again by updating to `serverless.yml`, but this time updating the provider
object to:

```yml
provider:
  name: aws
  runtime: nodejs18.x
  iam:
    role:
      statements:
        - Effect: Allow
          Action:
            - 's3:Get*'
            - 's3:Put*'
            - 's3:List*'
            - 's3:Head*'
          Resource:
            Fn::Join:
              - ''
              - - 'arn:aws:s3:::'
                - Ref: NameBucket
                - '*'
```

This gives the lambda functions in this service Get, Put, List and Head permissions for its own s3 bucket.

Redeploy:

```shell
  serverless deploy --stage dev
```

And you should now be able to load your page.
If you go to the [s3 console](https://us-east-1.console.aws.amazon.com/s3/buckets?region=us-east-1), open your bucket,
download your `names.json` and you should see it updates.

## Part 2c - Concurrency and queues

However, now we have a concurrency problem.
Our `storeName` function retrieves the existing json, updates it, then puts the updated version back in the bucket.
But there might be more than 1 lambda running at a time, meaning there is a race condition.

What we need is a way of ensuring only 1 lambda is storing names at any one time.
One way of achieving this would be to have our existing lambda put each `name` on a queue and have another lambda,
limited to a concurrency of 1, take the items off the queue.
That is exactly what we're going to do. We'll add an SQS queue to our Resources, add another lambda to listen to it, and
update our existing lambda to take things off it.

Let's start by adding the queue to `serverless.yml`.

```yml
    NameQueue:
      Type: 'AWS::SQS::Queue'
```

And get the queue name into and environment variable:

```yml
    environment:
      NAME_QUEUE_URL: !Ref NameQueue
```

And give our lambda permission to put items on the queue:

```yml
  iam:
    role:
      statements:
        - Effect: Allow
          Action:
            - 's3:Get*'
            - 's3:Put*'
            - 's3:List*'
            - 's3:Head*'
          Resource:
            Fn::Join:
              - ''
              - - 'arn:aws:s3:::'
                - Ref: NameBucket
                - '*'
        - Effect: Allow
          Action:
            - 'sqs:send*'
          Resource:
            - !GetAtt NameQueue.Arn
```

Note we use the `!GetAtt` function here to directly access the ARN (Amazon Resource Name) of the queue.

Then we need to create a function for sending our name to the queue by adding `lib/queue-name.ts` with the below:

```ts
import {SendMessageCommand, SQSClient} from "@aws-sdk/client-sqs";

const SQS_QUEUE_URL = process.env.NAME_QUEUE_URL
const client = new SQSClient()

export async function queueName(name: string): Promise<void> {
    const command = new SendMessageCommand({
        QueueUrl: SQS_QUEUE_URL,
        MessageBody: name,
    });

    await client.send(command);
}
```

Finally, we need to update our handler to send our name to the queue.

```ts
import {Handler, APIGatewayProxyEvent, APIGatewayProxyResult} from 'aws-lambda';
import {queueName} from "./lib/queue-name";

export const handler: Handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {

    const name = event.pathParameters.name

    await queueName(name)

    return {
        statusCode: 200,
        headers: {
            'content-type': 'text/html'
        },
        body: `<h1 style="width: 100vw;text-align:center;margin-top: 40vh;">Hello ${name}</h1>`,
    };
};
```

Now if we deploy this:

```shell
serverless deploy --stage dev
```

We'll see:

- the queue has been created in
  the [cloudformation console](https://us-east-1.console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks)
- that your page still works when you visit it in the browser
- and that you can see messages going on your queue when you look at your queues monitoring in
  the [sqs console](https://us-east-1.console.aws.amazon.com/sqs/v2/home?region=us-east-1#/queues)

We need to add another lambda to our service which will take items off the queue and store them in s3.
First we'll start by renaming our existing `handler` function to be `getHandler` in `index.ts`, and then update
the `handler` argument in `serverless.yml` to `index.getHandler`.
Lambdas which listen to sqs queues can process multiple messages from the queue in each invocation, so we need to update
our `storeName` function to be `storeNames` and allow it to store multiple names at once:

```ts
export async function storeNames(names: string[]): Promise<void> {
    const existingNames = await getCurrentNames()

    for (const name of names) {

        if (!existingNames[name]) {
            existingNames[name] = 0
        }

        existingNames[name]++
    }

    await client.send(new PutObjectCommand({
        ...params,
        Body: JSON.stringify(existingNames)
    }))
}
```

We'll then want to add a handler for our function to `index.ts`:

```ts
export const queueHandler: Handler = async (event: SQSEvent): Promise<SQSBatchResponse> => {

    const names = event.Records.map(record => record.body)

    await storeNames(names)

    return {
        batchItemFailures: []
    };
};
```

Finally, we need to update `serverless.yml` to include a second function, and hook it up to receive messages from our
queue.

```yml
  function2:
    handler: index.queueHandler
    reservedConcurrency: 1
    events:
      - sqs:
          arn: !GetAtt NameQueue.Arn
          batchSize: 100
          maximumBatchingWindow: 60
    environment:
      NAME_BUCKET: !Ref NameBucket
```

Then off we go and deploy again:

```shell
serverless deploy --stage=dev
```

And now we'll see:
We'll see:

- your page still works when you visit it in the browser
- that you can see messages going on your queue and being removed when you look at your queues monitoring in
  the [sqs console](https://us-east-1.console.aws.amazon.com/sqs/v2/home?region=us-east-1#/queues)
- your lambda in the [lambda console](https://us-east-1.console.aws.amazon.com/lambda/home?region=us-east-1#/functions)
  now has a sqs trigger and has successful invocations in its metrics
- your file in the s3 bucket is updating

That's it, you've built a service with http endpoints, storage and queues with serverless in AWS. Infrastructure as Code
can mean that you can solve a problem with infrastructure as easily as you can with code. You can think of
infrastructure, like queues or storage, as pre-built modules for your wider application; so just as you might solve an
issue with a npm package, why not solve it with a queue if that's a better fix? And if you're building a simple backend
service, and you need it to scale, or you need it to react to events or run on a schedule; why not use a lambda?

Anyway, serverless and AWS have a lot more to them than we've learned here, this is barely the icing on the cake. But
its a start. My advice would be to get reading, get yourself your own AWS account and start playing (just make sure you
tear things down and that you look at how much resources cost before you create them).

In that vain, manually delete your `names.json` from your bucket, and:

```shell
serverless remove --stage=dev
```
