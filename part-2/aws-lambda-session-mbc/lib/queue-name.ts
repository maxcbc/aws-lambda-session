import { SendMessageCommand, SQSClient } from "@aws-sdk/client-sqs";

const SQS_QUEUE_URL = process.env.NAME_QUEUE_URL
const client = new SQSClient()
export async function queueName(name: string): Promise<void> {
    const command = new SendMessageCommand({
        QueueUrl: SQS_QUEUE_URL,
        MessageBody: name,
    });

    await client.send(command);
}