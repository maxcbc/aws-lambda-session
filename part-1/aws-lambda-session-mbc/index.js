module.exports.handler = async (event) => {
    return {
        statusCode: 200,
        headers: {
            'content-type': 'text/html'
        },
        body: `<h1 style="width: 100vw;text-align:center;margin-top: 40vh;">Hello ${event.pathParameters.name}</h1>`,
    };
};
