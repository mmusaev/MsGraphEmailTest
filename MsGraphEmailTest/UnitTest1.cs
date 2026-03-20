using Azure.Identity;
using Microsoft.Graph;
using Microsoft.Graph.Models;
using Microsoft.Graph.Users.Item.SendMail;

namespace MsGraphEmailTest
{
    public class UnitTest1
    {
        private const string TestRecipientEmail = "maratsmusaev@gmail.com"; // Update with actual test email

        /// <summary>
        /// Test sending email with Managed Identity
        /// </summary>
        [Fact()]
        public async Task SendEmail_WithManagedIdentity_Succeeds()
        {
            // Arrange - DefaultAzureCredential uses MSI in Azure, Azure CLI locally
            var credential = new DefaultAzureCredential();
            var graphClient = new GraphServiceClient(credential, ["https://graph.microsoft.com/.default"]);

            // Use the specific mailbox
            var senderMailbox = "maratsmusaev@gmail.com";

            var message = new Message
            {
                Subject = $"[MSI Test] Email - {DateTime.Now:yyyy-MM-dd HH:mm:ss}",
                Body = new ItemBody
                {
                    Content = "This is a test email sent using Managed Identity (DefaultAzureCredential) from MANotification integration",
                    ContentType = BodyType.Text
                },
                ToRecipients = new List<Recipient>
                {
                    new Recipient { EmailAddress = new EmailAddress { Address = TestRecipientEmail } }
                }
            };

            var requestBody = new SendMailPostRequestBody
            {
                Message = message,
                SaveToSentItems = false
            };

            // Act - Send using Managed Identity
            await graphClient.Users[senderMailbox].SendMail.PostAsync(requestBody);

            // Assert - if no exception, email was sent successfully
            Assert.True(true, "Email sent successfully using Managed Identity");
        }
    }

}