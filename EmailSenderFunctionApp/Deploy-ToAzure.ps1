# Script to deploy Function App to Azure using Azure CLI

Write-Host "Building and deploying EmailSenderFunctionApp..." -ForegroundColor Cyan

# Resolve the project path safely from the script location
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectPath = Join-Path $scriptDir "EmailSenderFunctionApp.csproj"
$publishPath = Join-Path $scriptDir "publish"

if (-not (Test-Path $projectPath)) {
    Write-Host "Project file not found: $projectPath" -ForegroundColor Red
    exit 1
}

Set-Location $scriptDir

if (Test-Path $publishPath) {
    Remove-Item $publishPath -Recurse -Force
}

# Build and publish the project
Write-Host "Building project..." -ForegroundColor Yellow
dotnet publish $projectPath --configuration Release --output $publishPath

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

# Create a ZIP file
Write-Host "Creating deployment package..." -ForegroundColor Yellow
$zipPath = "./deploy.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath
}
Compress-Archive -Path ./publish/* -DestinationPath $zipPath -Force

# Deploy to Azure
Write-Host "Deploying to Azure Function App..." -ForegroundColor Yellow
$resourceGroup = "msgraphsendemail_group"
$functionAppName = "msgraphsendemail"

try {
    az functionapp deployment source config-zip `
        --resource-group $resourceGroup `
        --name $functionAppName `
        --src $zipPath
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Deployment successful!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "1. Verify SENDER_MAILBOX is configured in Application Settings" -ForegroundColor White
        Write-Host "2. Ensure Managed Identity has Mail.Send permissions" -ForegroundColor White
        Write-Host "3. Test your function at: https://$functionAppName.azurewebsites.net/api/SendEmail" -ForegroundColor White
    } else {
        Write-Host "Deployment failed!" -ForegroundColor Red
    }
}
catch {
    Write-Host "Error during deployment: $_" -ForegroundColor Red
}

# Cleanup
Set-Location ..
