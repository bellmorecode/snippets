using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;

namespace fx
{
    public enum TestModes
    {
        Production = 0, Test = 1, Local = 99
    }
    public sealed class WorkflowService
    {
        readonly Microsoft.Extensions.Logging.ILogger log;
        public WorkflowService(Microsoft.Extensions.Logging.ILogger logger, TestModes mode = TestModes.Production)
        {
            log = logger;

            if (mode == TestModes.Local)
            {
                hostname = "localhost:7249";
            }

            if (mode == TestModes.Test)
            {
                hostname = "sample-test.azurewebsites.net";
            }
        }

        private string hostname = "sample.firstresponsedashboard.com";
        const string key = "XXX";
        private async Task<string> SendAsync(string path)
        {

            var uri = $"https://{hostname}/ops/{path}";
            var client = new HttpClient();

            log.LogInformation($"SendAsync:{uri}");

            var message = new HttpRequestMessage(HttpMethod.Post, uri);
            message.Headers.Add("authtoken", key);
            using (var response = await client.SendAsync(message))
            {
                using (var str = await response.Content.ReadAsStreamAsync())
                {
                    using (var reader = new StreamReader(str))
                    {
                        return reader.ReadToEnd();
                    }
                }
            }
        }

        public async Task<string> RunTest1()
        {
            return await SendAsync("Test1");
        }
    }
}
