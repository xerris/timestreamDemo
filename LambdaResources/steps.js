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
                let records = []
                for(record of body.value){
                    const dimensions = [
                        {'Name': 'duration', 'Value': 'hour'}
                    ];
                    const memoryUtilization = {
                        'Dimensions': dimensions,
                        'MeasureName': 'steps',
                        'MeasureValue': record.steps.toString(),
                        'MeasureValueType': 'DOUBLE',
                        'Time': record.startDate.toString()
                    };
                    records.push(memoryUtilization)
                }
             
                const params = {
                    DatabaseName: "StepDatabase",
                    TableName: "StepTable",
                    Records: records
                };

                await writeClient.writeRecords(params).promise();
                return {
                    statusCode: 200,
                    headers: {},
                    body: JSON.stringify(records)
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
