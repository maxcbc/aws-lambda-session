import {Handler, APIGatewayProxyEvent, APIGatewayProxyResult, SQSEvent, SQSBatchResponse} from 'aws-lambda';
import {queueName} from "./lib/queue-name";
import {storeNames} from "./lib/store-name";

export const getHandler: Handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {

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

export const queueHandler: Handler = async (event: SQSEvent): Promise<SQSBatchResponse> => {

    const names = event.Records.map(record => record.body)

    await storeNames(names)

    return {
        batchItemFailures: []
    };
};