# 🔐 User Secrets Setup Guide

## Quick Start

### Initialize User Secrets (Already Done ✅)
```powershell
dotnet user-secrets init
```

This creates a unique ID in your `.csproj` file:
```xml
<UserSecretsId>01983f61-8b48-4e50-b730-59bf05f4b9bc</UserSecretsId>
```

---

## Setting Secrets

### Method 1: Command Line (Recommended)

```powershell
# Navigate to project directory
cd C:\dev\MsGraphEmailTest\EmailSenderFunctionApp

# Set sender mailbox
dotnet user-secrets set "EmailSettings:SenderMailbox" "your-sender@yourdomain.com"

# Set other settings (optional)
dotnet user-secrets set "EmailSettings:DefaultSubject" "My Default Subject"
dotnet user-secrets set "EmailSettings:SaveToSentItems" "true"
```

### Method 2: Visual Studio

1. **Right-click** on `EmailSenderFunctionApp` project
2. Select **Manage User Secrets**
3. Edit the `secrets.json` file that opens:

```json
{
  "EmailSettings": {
    "SenderMailbox": "your-sender@yourdomain.com",
    "DefaultSubject": "Test Email",
    "SaveToSentItems": false
  }
}
```

4. **Save** the file

---

## Managing Secrets

### View All Secrets
```powershell
dotnet user-secrets list
```

### Remove a Specific Secret
```powershell
dotnet user-secrets remove "EmailSettings:SenderMailbox"
```

### Clear All Secrets
```powershell
dotnet user-secrets clear
```

---

## Where Are Secrets Stored?

User Secrets are stored **outside** your project directory:

**Windows:**
```
%APPDATA%\Microsoft\UserSecrets\01983f61-8b48-4e50-b730-59bf05f4b9bc\secrets.json
```

**Full Path Example:**
```
C:\Users\YourUsername\AppData\Roaming\Microsoft\UserSecrets\01983f61-8b48-4e50-b730-59bf05f4b9bc\secrets.json
```

**macOS/Linux:**
```
~/.microsoft/usersecrets/01983f61-8b48-4e50-b730-59bf05f4b9bc/secrets.json
```

✅ This location is **never** included in your git repository!

---

## Configuration Precedence

When the app runs in **Development** environment, configuration is loaded in this order:

1. `appsettings.json`
2. `appsettings.Development.json`
3. **User Secrets** ← Your secrets override previous settings
4. `local.settings.json` (environment variables)
5. System environment variables

**Example:**

If you have:
- `appsettings.Development.json`: `"SenderMailbox": "dev@example.com"`
- **User Secrets**: `"SenderMailbox": "my-personal@example.com"`

The app will use: **`my-personal@example.com`** ✅

---

## Team Setup

### For New Team Members

1. **Clone the repository**
   ```powershell
   git clone https://github.com/mmusaev/MsGraphEmailTest.git
   cd MsGraphEmailTest\EmailSenderFunctionApp
   ```

2. **User Secrets are already initialized** (UserSecretsId is in .csproj)

3. **Set your personal secrets**
   ```powershell
   dotnet user-secrets set "EmailSettings:SenderMailbox" "yourname@yourdomain.com"
   ```

   OR copy `local.settings.template.json` → `local.settings.json` and fill in values

4. **Run the app**
   ```powershell
   func start
   ```

### Sharing Configuration Structure (Not Secrets!)

✅ **Commit to git:**
- `local.settings.template.json` (template without actual values)
- Documentation about what secrets are needed

❌ **Never commit:**
- `local.settings.json` (actual values)
- User Secrets (stored outside project anyway)

---

## Troubleshooting

### ❓ "SenderMailbox is not configured"

**Solution:**
```powershell
# Check if secrets are set
dotnet user-secrets list

# If empty, set the required secret
dotnet user-secrets set "EmailSettings:SenderMailbox" "your@email.com"
```

### ❓ Secrets not loading?

**Check environment:**
```powershell
# User Secrets only load in Development environment
$env:AZURE_FUNCTIONS_ENVIRONMENT = "Development"
```

Or set in `local.settings.json`:
```json
{
  "Values": {
    "AZURE_FUNCTIONS_ENVIRONMENT": "Development"
  }
}
```

### ❓ Can't find secrets.json file?

**Open directly:**
```powershell
# Windows PowerShell
$secretsPath = "$env:APPDATA\Microsoft\UserSecrets\01983f61-8b48-4e50-b730-59bf05f4b9bc\secrets.json"
notepad $secretsPath

# Or use Visual Studio: Right-click project → Manage User Secrets
```

### ❓ Want to see the actual secrets file location?

```powershell
dotnet user-secrets list --verbose
```

---

## Best Practices

### ✅ DO

- Use User Secrets for personal development credentials
- Use `local.settings.json` for Azure Functions-specific environment variables
- Commit `local.settings.template.json` to help team members
- Document what secrets are required

### ❌ DON'T

- Don't commit `local.settings.json` with real secrets
- Don't put secrets in `appsettings.json` or `appsettings.Development.json`
- Don't share your User Secrets file directly (each dev should have their own)

---

## Example: Complete Local Setup

```powershell
# 1. Clone and navigate to project
cd C:\dev\MsGraphEmailTest\EmailSenderFunctionApp

# 2. Set your secrets
dotnet user-secrets set "EmailSettings:SenderMailbox" "your-email@domain.com"

# 3. Verify
dotnet user-secrets list

# 4. Build and run
dotnet build
func start
```

---

## Migration from Environment Variables

If you were using environment variables before:

### Before:
```powershell
$env:SENDER_MAILBOX = "sender@domain.com"
```

### After (User Secrets):
```powershell
dotnet user-secrets set "EmailSettings:SenderMailbox" "sender@domain.com"
```

### After (local.settings.json):
```json
{
  "Values": {
    "EmailSettings__SenderMailbox": "sender@domain.com"
  }
}
```

---

## Additional Resources

- [Microsoft Docs: User Secrets](https://docs.microsoft.com/aspnet/core/security/app-secrets)
- [Azure Functions Configuration](https://docs.microsoft.com/azure/azure-functions/functions-app-settings)
- [Configuration in .NET](https://docs.microsoft.com/dotnet/core/extensions/configuration)

---

✅ **Setup Complete!** Your secrets are now safely stored outside the project directory.
