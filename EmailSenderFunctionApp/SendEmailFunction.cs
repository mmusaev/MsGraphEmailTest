using EmailSenderFunctionApp.Extensions;
using EmailSenderFunctionApp.Services;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using System.Net;
using System.Text.Json;

namespace EmailSenderFunctionApp;

public class SendEmailFunction(ILogger<SendEmailFunction> logger, IEmailService emailService, IRequestParser requestParser)
{
    [Function("SendEmail")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Function, "post")] HttpRequestData req,
        CancellationToken cancellationToken)
    {
        logger.LogInformation("SendEmail function triggered");

        try
        {
            var requestBody = await req.ReadAsStringAsync();

            if (string.IsNullOrWhiteSpace(requestBody))
            {
                return await req.CreateErrorResponseAsync(HttpStatusCode.BadRequest,
                    "Request body is empty. Please provide a JSON body with 'to', 'subject', and 'body' fields.");
            }

            EmailRequest? emailRequest;
            try
            {
                emailRequest = requestParser.Parse<EmailRequest>(requestBody);
            }
            catch (JsonException jsonEx)
            {
                logger.LogWarning(jsonEx, "Invalid JSON format in request");
                return await req.CreateErrorResponseAsync(HttpStatusCode.BadRequest,
                    $"Invalid JSON format: {jsonEx.Message}");
            }

            if (emailRequest == null)
            {
                return await req.CreateErrorResponseAsync(HttpStatusCode.BadRequest,
                    "Failed to parse request. Please provide valid JSON.");
            }

            if (!requestParser.TryValidate(emailRequest, out var validationResults))
            {
                var errors = string.Join(", ", validationResults.Select(v => v.ErrorMessage));
                return await req.CreateErrorResponseAsync(HttpStatusCode.BadRequest, errors);
            }

            await emailService.SendEmailAsync(emailRequest, cancellationToken);

            return await req.CreateSuccessResponseAsync("Email sent successfully");
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error sending email");
            return await req.CreateErrorResponseAsync(HttpStatusCode.InternalServerError, ex.Message);
        }
    }
}
