using Amazon.CDK;
using Amazon.CDK.AWS.APIGateway;
using Amazon.CDK.AWS.Lambda;
using Amazon.CDK.AWS.Timestream;
using System.Collections.Generic;
using System.IO.Compression;

namespace TimestreamDemo
{

    public class TimestreamService : Construct
    {
        public TimestreamService(Construct scope, string id) : base(scope, id)
        {
            
            var handler = new Function(this, "WidgetHandler", new FunctionProps
            {
                Runtime = Runtime.NODEJS_10_X,
                Code = Code.FromAsset("resources"),
                Handler = "widgets.main",
            });
            var db = new CfnDatabase(this, "testTimestream", new CfnDatabaseProps
            {
                DatabaseName = "NewDBTest",
                
            });
            var table = new CfnTable(this, "testTable", new CfnTableProps()
            {
                TableName = "test",
                DatabaseName = db.DatabaseName
            });
            var api = new RestApi(this, "Widgets-API", new RestApiProps
            {
                RestApiName = "Widget Service",
                Description = "This service services widgets."
            });

            var getWidgetsIntegration = new LambdaIntegration(handler, new LambdaIntegrationOptions
            {
                RequestTemplates = new Dictionary<string, string>
                {
                    ["application/json"] = "{ \"statusCode\": \"200\" }"
                }
            });

            api.Root.AddMethod("GET", getWidgetsIntegration);

        }
    }
}