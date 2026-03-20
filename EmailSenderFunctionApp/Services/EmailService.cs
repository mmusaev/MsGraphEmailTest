using Microsoft.Extensions.Logging;
using Microsoft.Graph;
using Microsoft.Graph.Models;
using Microsoft.Graph.Users.Item.SendMail;

namespace EmailSenderFunctionApp.Services;

public class EmailService(ILogger<EmailService> logger, GraphServiceClient graphClient) : IEmailService
{
    private const string SenderMailboxKey = "SENDER_MAILBOX";
    private readonly string _senderMailbox = Environment.GetEnvironmentVariable(SenderMailboxKey)
        ?? throw new InvalidOperationException($"{SenderMailboxKey} environment variable is not configured");

    public async Task SendEmailAsync(EmailRequest emailRequest, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(emailRequest);

        logger.LogInformation("Sending email from {SenderMailbox} to {Recipient}", _senderMailbox, emailRequest.To);

        var message = new Message
        {
            Subject = emailRequest.Subject ?? "Notification",
            Body = new ItemBody
            {
                Content = emailRequest.Body ?? string.Empty,
                ContentType = emailRequest.IsHtml ? BodyType.Html : BodyType.Text
            },
            ToRecipients =
            [
                new Recipient
                {
                    EmailAddress = new EmailAddress { Address = emailRequest.To }
                }
            ]
        };

        var sendMailRequest = new SendMailPostRequestBody
        {
            Message = message,
            SaveToSentItems = emailRequest.SaveToSentItems
        };

        await graphClient.Users[_senderMailbox].SendMail.PostAsync(sendMailRequest, cancellationToken: cancellationToken);

        logger.LogInformation("Email sent successfully to {Recipient}", emailRequest.To);
    }
}
