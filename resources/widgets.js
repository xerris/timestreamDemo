const AWS = require('aws-sdk');
var https = require('https');
exports.main = async function(event, context) {

    try {
        var agent = new https.Agent({
            maxSockets: 5000
        });
        writeClient = new AWS.TimestreamWrite({
                maxRetries: 10,
                httpOptions: {
                    timeout: 20000,
                    agent: agent
                }
            });
        queryClient = new AWS.TimestreamQuery();
        
        var method = event.httpMethod;

        if (method === "GET") {
            if (event.path === "/") {
                return {
                    statusCode: 200,
                    headers: {},
                    body: "HI"
                };
            }
        }
        if (method === "POST") {
            if (event.path === "/") {

                const memoryUtilization = {
                    'Dimensions': dimensions,
                    'MeasureName': 'memory_utilization',
                    'MeasureValue': '40',
                    'MeasureValueType': 'DOUBLE',
                    'Time': currentTime.toString()
                };
             
                const records = [memoryUtilization];
             
                const params = {
                    DatabaseName: "NewDBTest",
                    TableName: "test",
                    Records: records
                };
             
                await writeClient.writeRecords(params).promise();
                return {
                    statusCode: 200,
                    headers: {},
                    body: JSON.stringify(memoryUtilization)
                };
            }
        }
        // We only accept GET for now
        return {
            statusCode: 400,
            headers: {},
            body: "We only accept GET /"
        };
    } catch(error) {
        var body = error.stack || JSON.stringify(error, null, 2);
        return {
            statusCode: 400,
            headers: {},
            body: JSON.stringify(body)
        }
    }
}
