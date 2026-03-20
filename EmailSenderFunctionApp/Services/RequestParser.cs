using System.ComponentModel.DataAnnotations;
using System.Text.Json;

namespace EmailSenderFunctionApp.Services;

public class RequestParser : IRequestParser
{
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNameCaseInsensitive = true };

    public T? Parse<T>(string requestBody) where T : class
    {
        if (string.IsNullOrWhiteSpace(requestBody))
        {
            return null;
        }

        return JsonSerializer.Deserialize<T>(requestBody, JsonOptions);
    }

    public bool TryValidate<T>(T instance, out List<ValidationResult> validationResults) where T : class
    {
        validationResults = [];
        var validationContext = new ValidationContext(instance);
        return Validator.TryValidateObject(instance, validationContext, validationResults, validateAllProperties: true);
    }
}
