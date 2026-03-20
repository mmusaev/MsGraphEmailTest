# How to Grant Graph Permissions to Managed Identity

## Option 1: Using PowerShell Script (Recommended if you have PowerShell)

1. Open **PowerShell** (not bash/terminal)
2. Navigate to the EmailSenderFunctionApp directory
3. Run:
   ```powershell
   .\GrantGraphPermissions.ps1
   ```

## Option 2: Using Azure Portal (Easiest Method)

Unfortunately, you cannot directly assign Microsoft Graph permissions to a Managed Identity through the Azure Portal UI. You **must** use PowerShell, Azure CLI, or create an App Registration.

### Alternative: Create an App Registration (Portal-only method)

If you don't want to use PowerShell, you can use an App Registration instead of Managed Identity:

1. **Create App Registration**:
   - Go to **Azure Active Directory** > **App registrations** > **New registration**
   - Name: `msgraphsendemail-app`
   - Click **Register**

2. **Add API Permissions**:
   - In your new app, go to **API permissions**
   - Click **Add a permission** > **Microsoft Graph** > **Application permissions**
   - Search for and select **Mail.Send**
   - Click **Add permissions**
   - Click **Grant admin consent** (requires admin rights)

3. **Create Client Secret**:
   - Go to **Certificates & secrets** > **New client secret**
   - Description: `Function App Secret`
   - Expires: Choose duration
   - Click **Add**
   - **Copy the secret value immediately** (you won't see it again)

4. **Update Function Code**:
   You would need to modify the code to use ClientSecretCredential instead of DefaultAzureCredential

## Option 3: Using Azure Cloud Shell (No Local Installation Required)

1. Go to **Azure Portal** (https://portal.azure.com)
2. Click the **Cloud Shell** icon (>_) at the top
3. Select **PowerShell**
4. Run these commands:

```powershell
# Install Microsoft Graph PowerShell module
Install-Module Microsoft.Graph -Force -AllowClobber

# Connect to Microsoft Graph
Connect-MgGraph -Scopes AppRoleAssignment.ReadWrite.All,Application.Read.All

# Get Managed Identity
$msi = (Get-MgServicePrincipal -Filter "displayName eq 'msgraphsendemail'").Id
Write-Host "Managed Identity ID: $msi"

# Get Microsoft Graph Service Principal
$graphApp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"

# Get Mail.Send app role
$appRole = $graphApp.AppRoles | Where-Object {$_.Value -eq "Mail.Send"}

# Assign permission
New-MgServicePrincipalAppRoleAssignment `
    -ServicePrincipalId $msi `
    -PrincipalId $msi `
    -AppRoleId $appRole.Id `
    -ResourceId $graphApp.Id

Write-Host "Permission granted successfully!"

# Disconnect
Disconnect-MgGraph
```

## Verify Permissions Were Granted

1. Go to **Azure Active Directory** > **Enterprise applications**
2. Change filter to **Application Type: Managed Identities**
3. Find and click **msgraphsendemail**
4. Click **Permissions** in the left menu
5. You should see **Mail.Send** with status **Granted for [your directory]**

## After Granting Permissions

Don't forget to configure the SENDER_MAILBOX setting:

1. Go to your Function App **msgraphsendemail**
2. **Configuration** > **Application settings** > **+ New application setting**
3. Name: `SENDER_MAILBOX`
4. Value: `youremail@yourdomain.com` (Microsoft 365 email)
5. Click **OK** then **Save**
