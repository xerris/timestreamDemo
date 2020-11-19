using Amazon.CDK;

namespace TimestreamDemo
{
    public class TimestreamDemoStack : Stack
    {
        internal TimestreamDemoStack(Construct scope, string id, IStackProps props = null) : base(scope, id, props)
        {
            new TimestreamService(this, "Steps");
            // The code that defines your stack goes here
        }
    }
}
