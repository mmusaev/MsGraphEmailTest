# Script to build and package the Function App for deployment

Write-Host "Building EmailSenderFunctionApp..." -ForegroundColor Cyan

# Navigate to project directory
$projectPath = "EmailSenderFunctionApp"
Set-Location $projectPath

# Build and publish the project
Write-Host "Building project..." -ForegroundColor Yellow
dotnet publish --configuration Release --output ./publish

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    Set-Location ..
    exit 1
}

# Create a ZIP file
Write-Host "Creating deployment package..." -ForegroundColor Yellow
$zipPath = "./EmailSenderFunctionApp-deploy.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath
}
Compress-Archive -Path ./publish/* -DestinationPath $zipPath -Force

Write-Host ""
Write-Host "SUCCESS! Deployment package created:" -ForegroundColor Green
Write-Host "Location: $(Resolve-Path $zipPath)" -ForegroundColor White
Write-Host ""
Write-Host "To deploy manually:" -ForegroundColor Cyan
Write-Host "1. Go to Azure Portal (https://portal.azure.com)" -ForegroundColor White
Write-Host "2. Navigate to your Function App: msgraphsendemail" -ForegroundColor White
Write-Host "3. Go to 'Advanced Tools' (Kudu)" -ForegroundColor White
Write-Host "4. Click 'Tools' > 'Zip Push Deploy'" -ForegroundColor White
Write-Host "5. Drag and drop the ZIP file: $zipPath" -ForegroundColor White
Write-Host ""
Write-Host "OR use the Azure Portal deployment center:" -ForegroundColor Cyan
Write-Host "1. Go to your Function App > 'Deployment Center'" -ForegroundColor White
Write-Host "2. Click 'Upload' and select the ZIP file" -ForegroundColor White

# Open the file location
Write-Host ""
Write-Host "Opening file location..." -ForegroundColor Yellow
Invoke-Item (Split-Path (Resolve-Path $zipPath))

Set-Location ..
