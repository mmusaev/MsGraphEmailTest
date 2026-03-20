using System.ComponentModel.DataAnnotations;
using System.Text.Json;

namespace EmailSenderFunctionApp.Services;

public interface IRequestParser
{
    T? Parse<T>(string requestBody) where T : class;
    bool TryValidate<T>(T instance, out List<ValidationResult> validationResults) where T : class;
}
