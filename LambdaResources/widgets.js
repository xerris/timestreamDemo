const AWS = require('aws-sdk');
var https = require('https');
exports.main = async function(event, context) {

    try {
        var agent = new https.Agent({
            maxSockets: 5000
        });
        var writeClient = new AWS.TimestreamWrite({
                maxRetries: 10,
                httpOptions: {
                    timeout: 20000,
                    agent: agent
                }
        });
        
        var method = event.httpMethod;
        var body = JSON.parse(event.body);
        if (method === "POST") {
            if (event.path === "/healthInput") {
                const currentTime = Date.now().toString(); // Unix time in milliseconds
 
                const dimensions = [
                    {'Name': 'region', 'Value': 'us-east-1'},
                    {'Name': 'az', 'Value': 'az1'},
                    {'Name': 'hostname', 'Value': 'host1'}
                ];
                const memoryUtilization = {
                    'Dimensions': dimensions,
                    'MeasureName': 'memory_utilization',
                    'MeasureValue': body.value,
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
    } catch(error) {
        var body = error.stack || JSON.stringify(error, null, 2);
        return {
            statusCode: 400,
            headers: {},
            body: JSON.stringify(body)
        }
    }
}
