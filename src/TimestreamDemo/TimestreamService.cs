using Amazon.CDK;
using Amazon.CDK.AWS.APIGateway;
using Amazon.CDK.AWS.Lambda;
using Amazon.CDK.AWS.Timestream;
using System.Collections.Generic;
using System.IO.Compression;
using System.Runtime.CompilerServices;

namespace TimestreamDemo
{

    public class TimestreamService : Construct
    {
        public TimestreamService(Construct scope, string id) : base(scope, id)
        {
            
            var handler = new Function(this, "StepHandler", new FunctionProps
            {
                Runtime = Runtime.NODEJS_10_X,
                Code = Code.FromAsset("LambdaResources"),
                Handler = "steps.main",
            });
            var db = new CfnDatabase(this, "TimestreamDB", new CfnDatabaseProps
            {
                DatabaseName = "StepDatabase",
            });
            var table = new CfnTable(this, "stepTable", new CfnTableProps()
            {
               TableName = "StepTable", 
              DatabaseName = db.DatabaseName
            });
            var api = new RestApi(this, "Steps-API", new RestApiProps
            {
                RestApiName = "Step Service",
                Description = "This service services Steps."
            });
            
            var postStepsIntegration = new LambdaIntegration(handler);
           
            var steps = api.Root.AddResource("healthInput");
            
            steps.AddMethod("POST", postStepsIntegration);        

        }
    }
}