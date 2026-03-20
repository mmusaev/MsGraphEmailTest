using Azure.Identity;
using EmailSenderFunctionApp.Services;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Graph;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices(services =>
    {
        services.AddSingleton<DefaultAzureCredential>();
        services.AddSingleton(sp =>
        {
            var credential = sp.GetRequiredService<DefaultAzureCredential>();
            return new GraphServiceClient(credential, ["https://graph.microsoft.com/.default"]);
        });
        services.AddSingleton<IEmailService, EmailService>();
        services.AddSingleton<IRequestParser, RequestParser>();
    })
    .Build();

host.Run();
