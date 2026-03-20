using Azure.Identity;
using EmailSenderFunctionApp.Configuration;
using EmailSenderFunctionApp.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Graph;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureAppConfiguration((context, config) =>
    {
        config.SetBasePath(context.HostingEnvironment.ContentRootPath)
              .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
              .AddJsonFile($"appsettings.{context.HostingEnvironment.EnvironmentName}.json", optional: true, reloadOnChange: true)
              .AddEnvironmentVariables();

        // Add User Secrets in Development environment
        if (context.HostingEnvironment.IsDevelopment())
        {
            config.AddUserSecrets<Program>();
        }
    })
    .ConfigureServices((context, services) =>
    {
        // Bind configuration
        services.Configure<EmailConfiguration>(context.Configuration.GetSection(EmailConfiguration.SectionName));

        // Register services
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
