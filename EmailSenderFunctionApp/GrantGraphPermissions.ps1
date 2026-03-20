# Grant Microsoft Graph Mail.Send permission to Function App Managed Identity
# Run this script in PowerShell (not bash)

param(
    [string]$FunctionAppName = "msgraphsendemail",
    [string]$ResourceGroup = "msgraphsendemail_group"
)

Write-Host "=== Granting Microsoft Graph Permissions to Managed Identity ===" -ForegroundColor Cyan

# Check if Microsoft.Graph module is installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Host "Installing Microsoft.Graph module..." -ForegroundColor Yellow
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}

# Connect to Microsoft Graph
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
Connect-MgGraph -Scopes AppRoleAssignment.ReadWrite.All,Application.Read.All

# Get the Managed Identity Object ID
Write-Host "Getting Managed Identity details..." -ForegroundColor Yellow
try {
    $msi = (Get-MgServicePrincipal -Filter "displayName eq '$FunctionAppName'").Id
    
    if (-not $msi) {
        Write-Host "ERROR: Could not find Managed Identity for '$FunctionAppName'" -ForegroundColor Red
        Write-Host "Make sure System-assigned Managed Identity is enabled on your Function App" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "Managed Identity Object ID: $msi" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Failed to get Managed Identity: $_" -ForegroundColor Red
    exit 1
}

# Get Microsoft Graph Service Principal
Write-Host "Getting Microsoft Graph Service Principal..." -ForegroundColor Yellow
$graphApp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"

if (-not $graphApp) {
    Write-Host "ERROR: Could not find Microsoft Graph Service Principal" -ForegroundColor Red
    exit 1
}

# Get the Mail.Send app role
Write-Host "Looking for Mail.Send permission..." -ForegroundColor Yellow
$appRole = $graphApp.AppRoles | Where-Object {$_.Value -eq "Mail.Send"}

if (-not $appRole) {
    Write-Host "ERROR: Could not find Mail.Send app role" -ForegroundColor Red
    exit 1
}

Write-Host "Found Mail.Send role ID: $($appRole.Id)" -ForegroundColor Green

# Check if permission is already assigned
Write-Host "Checking existing permissions..." -ForegroundColor Yellow
$existingAssignment = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $msi | 
    Where-Object { $_.AppRoleId -eq $appRole.Id -and $_.ResourceId -eq $graphApp.Id }

if ($existingAssignment) {
    Write-Host "Mail.Send permission is already assigned!" -ForegroundColor Green
    exit 0
}

# Assign the Mail.Send permission to the Managed Identity
Write-Host "Assigning Mail.Send permission..." -ForegroundColor Yellow
try {
    New-MgServicePrincipalAppRoleAssignment `
        -ServicePrincipalId $msi `
        -PrincipalId $msi `
        -AppRoleId $appRole.Id `
        -ResourceId $graphApp.Id
    
    Write-Host "SUCCESS! Mail.Send permission granted to Managed Identity" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Configure SENDER_MAILBOX application setting in Azure Portal" -ForegroundColor White
    Write-Host "2. Set it to a valid Microsoft 365 email address" -ForegroundColor White
    Write-Host "3. Test your function" -ForegroundColor White
}
catch {
    Write-Host "ERROR: Failed to assign permission: $_" -ForegroundColor Red
    exit 1
}

# Disconnect
Disconnect-MgGraph
