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
                Code = Code.FromAsset("LambdaResources"),
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
            
            var postWidgetIntegration = new LambdaIntegration(handler);
           
            var widget = api.Root.AddResource("healthInput");

            // Add new widget to bucket with: POST /{id}
            
            widget.AddMethod("POST", postWidgetIntegration);        // POST /{id}

        }
    }
}