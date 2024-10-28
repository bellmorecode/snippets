using Microsoft.Graph;
using Microsoft.Identity.Client;
using System;
using System.Diagnostics;
using System.Net.Http.Headers;
using System.Threading.Tasks;

namespace HerrickAzureFunctions.Utils
{
    public static class GraphClientFactory
    {
        public static GraphServiceClient GetTeamsCallLoggerGraphClient()
        {
            return Utils.GraphClientFactory.GetGraphClient(
                Environment.GetEnvironmentVariable("TeamsCallLogger-Prod-client"),
                Environment.GetEnvironmentVariable("TeamsCallLogger-Prod-tenant"),
                Environment.GetEnvironmentVariable("TeamsCallLogger-Prod-secret"));
        }


        public static GraphServiceClient GetGraphClient(string client, string tenant, string secret)
        {
            var scopes = new string[] { "https://graph.microsoft.com/.default" };
            var confidentialClientApplication = ConfidentialClientApplicationBuilder.Create(client).WithTenantId(tenant).WithClientSecret(secret).Build();
            var graphServiceClient =
                new GraphServiceClient(new DelegateAuthenticationProvider(async (requestMessage) =>
                {
                    // Retrieve an access token for Microsoft Graph (gets a fresh token if needed).
                    var authResult = await confidentialClientApplication.AcquireTokenForClient(scopes).ExecuteAsync();

                    // Add the access token in the Authorization header of the API
                    requestMessage.Headers.Authorization = new AuthenticationHeaderValue("Bearer", authResult.AccessToken);

                }));

            return graphServiceClient;
        }
    }

    public class ODataService
    {
        protected const string dtformat = "yyyy-MM-dd";

        protected string date_from, date_to;

        public void FilterByDate(string from, string to)
        {
            date_from = from;
            date_to = to;
        }

        public void FilterByDate(DateTime? from, DateTime? to)
        {
            FilterByDate((from.HasValue ? from.Value : DateTime.Now).ToString(dtformat), (to.HasValue ? to.Value : DateTime.Now).ToString(dtformat));
        }
    }
    public class O365GraphService : ODataService
    {
        public O365GraphService()
        {

        }

        public async Task SendEmailAsync(Message msg)
        {
            try
            {

                string clientId = Environment.GetEnvironmentVariable("conflicts:o365-key"),
                        tenant = Environment.GetEnvironmentVariable("conflicts:o365-tenant"),
                        secret = Environment.GetEnvironmentVariable("conflicts:o365-secret");

                var client = GraphClientFactory.GetGraphClient(clientId, tenant, secret);
                await client.Users["mienaro@herrick.com"].SendMail(msg, true).Request().PostAsync();

            }
            catch (Exception ex)
            {
                Trace.TraceError($"Sending Email : {ex}");
            }
        }
    }
}