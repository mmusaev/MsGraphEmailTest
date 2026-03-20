using EmailSenderFunctionApp.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Microsoft.Graph;
using Microsoft.Graph.Models;
using Microsoft.Graph.Users.Item.SendMail;

namespace EmailSenderFunctionApp.Services;

public class EmailService(ILogger<EmailService> logger, GraphServiceClient graphClient, IOptions<EmailConfiguration> emailSettings) : IEmailService
{
    private readonly EmailConfiguration _emailSettings = emailSettings.Value;

    public async Task SendEmailAsync(EmailRequest emailRequest, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(emailRequest);

        if (string.IsNullOrWhiteSpace(_emailSettings.SenderMailbox))
        {
            throw new InvalidOperationException("SenderMailbox is not configured in EmailSettings");
        }

        logger.LogInformation("Sending email from {SenderMailbox} to {Recipient}", _emailSettings.SenderMailbox, emailRequest.To);

        var message = new Message
        {
            Subject = emailRequest.Subject ?? _emailSettings.DefaultSubject,
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

        await graphClient.Users[_emailSettings.SenderMailbox].SendMail.PostAsync(
            sendMailRequest,
            cancellationToken: cancellationToken);

        logger.LogInformation("Email sent successfully to {Recipient}", emailRequest.To);
    }
}
