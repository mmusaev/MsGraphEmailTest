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
        services.PostConfigure<EmailConfiguration>(options =>
        {
            if (string.IsNullOrWhiteSpace(options.SenderMailbox))
            {
                var legacySenderMailbox = context.Configuration["SENDER_MAILBOX"];
                if (!string.IsNullOrWhiteSpace(legacySenderMailbox))
                {
                    options.SenderMailbox = legacySenderMailbox;
                }
            }
        });

        // Register services
        services.AddSingleton(sp =>
        {
            var config = sp.GetRequiredService<IConfiguration>();
            var managedIdentityClientId = config["AZURE_CLIENT_ID"];

            return new DefaultAzureCredential(new DefaultAzureCredentialOptions
            {
                ExcludeInteractiveBrowserCredential = true,
                ManagedIdentityClientId = string.IsNullOrWhiteSpace(managedIdentityClientId) ? null : managedIdentityClientId
            });
        });
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
