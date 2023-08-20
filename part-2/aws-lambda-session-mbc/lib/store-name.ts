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