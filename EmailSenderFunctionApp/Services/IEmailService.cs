namespace EmailSenderFunctionApp.Services;

public interface IEmailService
{
    Task SendEmailAsync(EmailRequest emailRequest, CancellationToken cancellationToken = default);
}
