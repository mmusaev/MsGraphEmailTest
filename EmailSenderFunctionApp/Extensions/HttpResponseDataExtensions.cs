using Microsoft.Azure.Functions.Worker.Http;
using System.Net;

namespace EmailSenderFunctionApp.Extensions;

public static class HttpResponseDataExtensions
{
    public static async Task<HttpResponseData> CreateSuccessResponseAsync(this HttpRequestData req, string message)
    {
        var response = req.CreateResponse(HttpStatusCode.OK);
        await response.WriteAsJsonAsync(new { success = true, message, timestamp = DateTime.UtcNow });
        return response;
    }

    public static async Task<HttpResponseData> CreateErrorResponseAsync(this HttpRequestData req, HttpStatusCode statusCode, string error)
    {
        var response = req.CreateResponse(statusCode);
        await response.WriteAsJsonAsync(new { success = false, error, timestamp = DateTime.UtcNow });
        return response;
    }
}
