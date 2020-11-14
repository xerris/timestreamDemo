using Amazon.CDK;
using System;
using System.Collections.Generic;
using System.Linq;

namespace TimestreamDemo
{
    sealed class Program
    {
        public static void Main(string[] args)
        {
            var app = new App();
            new TimestreamDemoStack(app, "TimestreamDemoStack");
            app.Synth();
        }
    }
}
