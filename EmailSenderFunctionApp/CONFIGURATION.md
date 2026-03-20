# Configuration Guide

## Overview

This application uses a **hybrid configuration approach** combining JSON configuration files with environment variable overrides, following .NET and Azure Functions best practices.

---

## Configuration Hierarchy

Configuration is loaded in this order (later sources override earlier ones):

1. `appsettings.json` - Base configuration (committed to source control)
2. `appsettings.{Environment}.json` - Environment-specific overrides (committed to source control)
3. **User Secrets** - Local development secrets (Development environment only, stored outside project)
4. **Environment Variables** - Runtime overrides (from `local.settings.json` or system)
5. **Azure Configuration** - Azure Portal Application Settings (production)

**Example Precedence:**
```
appsettings.json (SenderMailbox = "")
    ↓ overridden by
appsettings.Development.json (SenderMailbox = "dev@example.com")
    ↓ overridden by
User Secrets (SenderMailbox = "mydev@example.com")
    ↓ overridden by
local.settings.json / Environment Variables (EmailSettings__SenderMailbox = "override@example.com")
```

---

## Configuration Files

### `appsettings.json` (Base Settings)
```json
{
  "EmailSettings": {
    "SenderMailbox": "",
    "DefaultSubject": "Notification",
    "SaveToSentItems": false
  }
}
```

### `appsettings.Development.json` (Local Development)
```json
{
  "EmailSettings": {
    "SenderMailbox": "dev-sender@yourdomain.com"
  }
}
```

### `appsettings.Production.json` (Production - Optional)
```json
{
  "EmailSettings": {
    "SenderMailbox": ""  // Leave empty, will be set via environment variable
  }
}
```

---

## Configuration Options

### EmailSettings Section

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `SenderMailbox` | string | (required) | Microsoft 365 mailbox to send from |
| `DefaultSubject` | string | "Notification" | Default subject when not provided |
| `SaveToSentItems` | bool | false | Save sent emails to Sent Items folder |

---

## Setting Configuration Values

### Local Development

#### Option 1: User Secrets (Recommended for Sensitive Data) ⭐
User Secrets store sensitive data **outside** your project directory, making it impossible to accidentally commit.

**Set secrets:**
```powershell
# Navigate to project directory
cd C:\dev\MsGraphEmailTest\EmailSenderFunctionApp

# Set sender mailbox
dotnet user-secrets set "EmailSettings:SenderMailbox" "your-sender@yourdomain.com"

# View all secrets
dotnet user-secrets list

# Remove a secret
dotnet user-secrets remove "EmailSettings:SenderMailbox"

# Clear all secrets
dotnet user-secrets clear
```

**Location:**
- Stored in: `%APPDATA%\Microsoft\UserSecrets\01983f61-8b48-4e50-b730-59bf05f4b9bc\secrets.json`
- ✅ Safe from git commits
- ✅ Shared across your local projects if needed

**Visual Studio:**
1. Right-click project → **Manage User Secrets**
2. Edit the `secrets.json` file:
```json
{
  "EmailSettings": {
    "SenderMailbox": "your-sender@yourdomain.com"
  }
}
```

#### Option 2: Edit `appsettings.Development.json` (For Non-Sensitive Config)
```json
{
  "EmailSettings": {
    "SenderMailbox": "your-sender@yourdomain.com",
    "DefaultSubject": "Test Email",
    "SaveToSentItems": false
  }
}
```

#### Option 3: Use `local.settings.json` (Azure Functions Environment Variables)
```json
{
  "Values": {
    "EmailSettings__SenderMailbox": "your-sender@yourdomain.com"
  }
}
```

**⚠️ Note:** 
- `local.settings.json` is already in `.gitignore` (safe)
- Use `local.settings.template.json` as a template for team members
- Use double underscores (`__`) to represent nested configuration hierarchy

---

### Azure Production

#### Option 1: Azure Portal (Recommended for Production)
1. Go to your Function App in Azure Portal
2. Navigate to **Settings** → **Configuration**
3. Click **New application setting**
4. Add: `EmailSettings__SenderMailbox` = `sender@yourdomain.com`
5. Click **Save**

#### Option 2: Azure CLI
```bash
az functionapp config appsettings set \
  --name <your-function-app-name> \
  --resource-group <your-resource-group> \
  --settings "EmailSettings__SenderMailbox=sender@yourdomain.com"
```

#### Option 3: ARM Template / Bicep
```json
{
  "name": "EmailSettings__SenderMailbox",
  "value": "sender@yourdomain.com"
}
```

---

## Environment-Specific Behavior

### Development Environment
- Uses `appsettings.Development.json`
- Can override with `local.settings.json`
- Set environment: `ASPNETCORE_ENVIRONMENT=Development` or `AZURE_FUNCTIONS_ENVIRONMENT=Development`

### Production Environment
- Uses `appsettings.json` + `appsettings.Production.json`
- Overridden by Azure Application Settings
- Environment automatically set to `Production` in Azure

---

## Configuration Best Practices

### ✅ DO

- **Commit** `appsettings.json` and environment-specific files to source control
- **Use** JSON files for non-sensitive, application-wide settings
- **Use** environment variables or Azure Key Vault for secrets
- **Use** the IOptions pattern for type-safe configuration
- **Validate** required configuration at startup

### ❌ DON'T

- **Don't** commit secrets or sensitive data to `appsettings.json`
- **Don't** hardcode configuration values in code
- **Don't** use `Environment.GetEnvironmentVariable()` directly (use IOptions instead)

---

## Accessing Configuration in Code

### Using IOptions Pattern (Current Implementation)

```csharp
public class EmailService(IOptions<EmailConfiguration> emailSettings)
{
    private readonly EmailConfiguration _settings = emailSettings.Value;
    
    public void SendEmail()
    {
        var mailbox = _settings.SenderMailbox;
        var subject = _settings.DefaultSubject;
    }
}
```

### Benefits
- ✅ Type-safe access
- ✅ IntelliSense support
- ✅ Validation at startup
- ✅ Testable (easy to mock)
- ✅ Reloadable (with IOptionsSnapshot)

---

## Configuration for Different Environments

### Local Development
```bash
# Set environment (PowerShell)
$env:AZURE_FUNCTIONS_ENVIRONMENT="Development"

# Or in local.settings.json
{
  "Values": {
    "AZURE_FUNCTIONS_ENVIRONMENT": "Development"
  }
}
```

### Azure Deployment
Environment is automatically set to **Production** in Azure.

To use a different environment (e.g., Staging):
```bash
az functionapp config appsettings set \
  --name <app-name> \
  --resource-group <rg-name> \
  --settings "AZURE_FUNCTIONS_ENVIRONMENT=Staging"
```

Then create `appsettings.Staging.json` with staging-specific settings.

---

## Troubleshooting

### Issue: "SenderMailbox is not configured"

**Solution:**
1. Check `appsettings.Development.json` has `SenderMailbox` set
2. Or set environment variable: `EmailSettings__SenderMailbox`
3. In Azure, verify Application Setting exists

### Issue: Configuration not loading

**Solution:**
1. Ensure `appsettings.json` is set to **Copy to Output Directory** = `Copy if newer`
2. Check file is deployed to Azure (visible in Kudu console)
3. Verify JSON syntax is valid

### Issue: Environment variable not overriding JSON

**Solution:**
- Use double underscores: `EmailSettings__SenderMailbox`
- NOT: `EmailSettings.SenderMailbox` or `EmailSettings:SenderMailbox`

---

## Adding New Configuration Options

1. **Add to `EmailConfiguration.cs`:**
```csharp
public class EmailConfiguration
{
    public string NewProperty { get; set; } = "default";
}
```

2. **Add to `appsettings.json`:**
```json
{
  "EmailSettings": {
    "NewProperty": "value"
  }
}
```

3. **Access in code:**
```csharp
var value = _emailSettings.NewProperty;
```

---

## Migration from Environment Variables

If you're migrating from the old environment variable approach:

### Before (Environment Variables Only):
```csharp
var mailbox = Environment.GetEnvironmentVariable("SENDER_MAILBOX");
```

### After (IOptions Pattern):
```csharp
public class EmailService(IOptions<EmailConfiguration> settings)
{
    private readonly EmailConfiguration _settings = settings.Value;
    
    public void DoSomething()
    {
        var mailbox = _settings.SenderMailbox;
    }
}
```

### Azure Portal Migration:
- **Old:** `SENDER_MAILBOX` = `sender@domain.com`
- **New:** `EmailSettings__SenderMailbox` = `sender@domain.com`

---

## Security Considerations

### Secrets Management

For sensitive data (API keys, connection strings, email credentials):

#### 🏠 Local Development

**Option 1: User Secrets** (Recommended) ⭐
```powershell
# Set a secret
dotnet user-secrets set "EmailSettings:SenderMailbox" "your-email@domain.com"

# Or via Visual Studio
# Right-click project → Manage User Secrets
```

**Benefits:**
- ✅ Stored outside project directory (`%APPDATA%\Microsoft\UserSecrets\{UserSecretsId}\`)
- ✅ Impossible to accidentally commit
- ✅ Per-user configuration
- ✅ Only loaded in Development environment

**Option 2: local.settings.json**
- Already in `.gitignore` ✅
- Use `local.settings.template.json` to share structure with team
- Never commit the actual `local.settings.json`

#### ☁️ Azure Production

**Option 1: Azure Application Settings** (Simple Secrets)
```bash
az functionapp config appsettings set \
  --name <app-name> \
  --resource-group <rg-name> \
  --settings "EmailSettings__SenderMailbox=sender@domain.com"
```

**Option 2: Azure Key Vault** (Recommended for Production)
```csharp
// In Program.cs
.ConfigureAppConfiguration((context, config) =>
{
    if (!context.HostingEnvironment.IsDevelopment())
    {
        var builtConfig = config.Build();
        var keyVaultUrl = builtConfig["KeyVaultUrl"];
        config.AddAzureKeyVault(
            new Uri(keyVaultUrl),
            new DefaultAzureCredential());
    }
})
```

**Option 3: Key Vault References in Azure Portal**
Instead of setting the actual value, reference Key Vault:
```
@Microsoft.KeyVault(SecretUri=https://myvault.vault.azure.net/secrets/SenderMailbox/)
```

### What NOT to Commit

❌ **Never commit these files with real secrets:**
- `local.settings.json` (already in `.gitignore` ✅)
- `appsettings.Development.json` **if it contains secrets** (use User Secrets instead)
- Any file with passwords, API keys, or connection strings

✅ **Safe to commit:**
- `local.settings.template.json` (template without actual values)
- `appsettings.json` (base configuration without secrets)
- `appsettings.Production.json` (structure only, secrets come from Azure)

---

## Summary

| Scenario | Configuration Method | Priority |
|----------|---------------------|----------|
| **Local Dev** | `appsettings.Development.json` | 1st choice |
| **Local Override** | `local.settings.json` (env vars) | Override |
| **Azure Production** | Azure Application Settings | 1st choice |
| **Secrets** | Azure Key Vault | Required |
| **CI/CD** | ARM/Bicep templates | Automated |

---

✅ **Current Implementation:** Hybrid approach with IOptions pattern
✅ **Type-safe:** Strong typing with `EmailConfiguration` class
✅ **Flexible:** JSON files + environment variable overrides
✅ **Secure:** Secrets can be moved to Key Vault easily
✅ **Testable:** Easy to mock IOptions in unit tests
