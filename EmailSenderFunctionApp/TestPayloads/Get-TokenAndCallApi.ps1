# Acquires a token for the Function App's Easy Auth app registration and calls SendEmail
# Requires: Install-Module MSAL.PS -Scope CurrentUser
# Pass the client secret via -ClientSecret or the CLIENT_SECRET env var - never hardcode it here

param(
    [string]$ClientId = "74d2f633-0ef7-437e-89d3-4626212ebd88",
    [string]$TenantId = "71bd40cc-f247-42ec-8be3-b26ab2c3e15e",
    [string]$ClientSecret = $env:CLIENT_SECRET,
    [string]$FunctionUrl = "https://msgraphemail-abgde0dsd3c7a0hr.centralus-01.azurewebsites.net/api/SendEmail",
    [string]$RecipientEmail = "maratsmusaev@gmail.com"
)

if (-not $ClientSecret) {
    $secureInput = Read-Host "Enter client secret" -AsSecureString
    $ClientSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureInput))
}

if (-not (Get-Module -ListAvailable -Name MSAL.PS)) {
    Write-Host "Installing MSAL.PS module..." -ForegroundColor Yellow
    Install-Module MSAL.PS -Scope CurrentUser -Force
}

Import-Module MSAL.PS

# Client credentials flow, requesting a token for itself - must use the GUID form, not api:// URI (AADSTS90009)
$secureSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$token = Get-MsalToken -ClientId $ClientId -TenantId $TenantId -ClientSecret $secureSecret -Scopes "$ClientId/.default"

if (-not $token) {
    Write-Host "Failed to acquire token." -ForegroundColor Red
    exit 1
}

Write-Host "Access Token:" -ForegroundColor Cyan
Write-Host $token.AccessToken

$body = @{
    to      = $RecipientEmail
    subject = "Test email via token auth - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    body    = "This is a test email sent with an Easy Auth token."
    isHtml  = $false
} | ConvertTo-Json

$headers = @{
    Authorization = "Bearer $($token.AccessToken)"
    "Content-Type" = "application/json"
}

Write-Host "Calling $FunctionUrl ..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri $FunctionUrl -Method Post -Headers $headers -Body $body
    Write-Host "Response:" -ForegroundColor Green
    $response | ConvertTo-Json
}
catch {
    Write-Host "Request failed: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        Write-Host $reader.ReadToEnd() -ForegroundColor Red
    }
}
