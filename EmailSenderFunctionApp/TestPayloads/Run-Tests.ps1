param(
    [Parameter(Mandatory=$false)]
    [string]$FunctionUrl = "http://localhost:7071/api/SendEmail",
    
    [Parameter(Mandatory=$true)]
    [string]$RecipientEmail
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🧪 SendEmail Function Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "URL: $FunctionUrl" -ForegroundColor Gray
Write-Host "Recipient: $RecipientEmail" -ForegroundColor Gray
Write-Host ""

$totalTests = 0
$passedTests = 0
$failedTests = 0

function Test-EmailFunction {
    param(
        [string]$TestName,
        [hashtable]$Payload,
        [bool]$ShouldSucceed = $true
    )
    
    $script:totalTests++
    Write-Host "📧 Test: $TestName" -ForegroundColor Yellow
    
    $jsonPayload = $Payload | ConvertTo-Json -Depth 10
    
    try {
        $result = Invoke-RestMethod -Uri $FunctionUrl -Method Post -Body $jsonPayload -ContentType "application/json"
        
        if ($ShouldSucceed) {
            Write-Host "   ✅ PASSED - $($result.message)" -ForegroundColor Green
            $script:passedTests++
        } else {
            Write-Host "   ❌ FAILED - Expected failure but succeeded" -ForegroundColor Red
            $script:failedTests++
        }
        
        Write-Host "   Response: $($result | ConvertTo-Json -Compress)" -ForegroundColor Gray
    }
    catch {
        if (-not $ShouldSucceed) {
            Write-Host "   ✅ PASSED - Failed as expected" -ForegroundColor Green
            $script:passedTests++
        } else {
            Write-Host "   ❌ FAILED - $($_.Exception.Message)" -ForegroundColor Red
            $script:failedTests++
        }
        
        if ($_.ErrorDetails.Message) {
            $errorObj = $_.ErrorDetails.Message | ConvertFrom-Json
            Write-Host "   Error: $($errorObj.error)" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
}

# ===========================
# Valid Test Cases
# ===========================
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "VALID TEST CASES (Should Succeed)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

Test-EmailFunction -TestName "Basic Text Email" -Payload @{
    to = $RecipientEmail
    subject = "Test Email - Basic Text"
    body = "This is a basic test email sent from the Azure Function test suite."
    isHtml = $false
    saveToSentItems = $false
} -ShouldSucceed $true

Test-EmailFunction -TestName "HTML Email" -Payload @{
    to = $RecipientEmail
    subject = "Test Email - HTML Formatted"
    body = "<html><body><h1>Hello!</h1><p>This is a <strong>test email</strong> with <em>HTML formatting</em>.</p><ul><li>Feature 1</li><li>Feature 2</li></ul></body></html>"
    isHtml = $true
    saveToSentItems = $true
} -ShouldSucceed $true

Test-EmailFunction -TestName "Minimal Email (only To field)" -Payload @{
    to = $RecipientEmail
} -ShouldSucceed $true

Test-EmailFunction -TestName "Email with Subject Only" -Payload @{
    to = $RecipientEmail
    subject = "Email with subject, no body"
} -ShouldSucceed $true

Test-EmailFunction -TestName "Email with Empty Body String" -Payload @{
    to = $RecipientEmail
    subject = "Empty Body Test"
    body = ""
} -ShouldSucceed $true

Test-EmailFunction -TestName "Professional Notification Email" -Payload @{
    to = $RecipientEmail
    subject = "System Notification - Test Suite"
    body = "Dear User,`n`nThis is an automated test notification.`n`nDetails:`n- Test Suite: SendEmail Function`n- Status: Testing`n- Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`nBest regards,`nAzure Function Test Bot"
    isHtml = $false
    saveToSentItems = $true
} -ShouldSucceed $true

Test-EmailFunction -TestName "Styled HTML Alert Email" -Payload @{
    to = $RecipientEmail
    subject = "⚠️ System Alert - Test"
    body = @"
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 0; }
        .alert { background-color: #f44336; color: white; padding: 20px; border-radius: 5px; }
        .content { padding: 20px; background-color: #f9f9f9; }
        .footer { padding: 10px; text-align: center; font-size: 12px; color: #666; }
    </style>
</head>
<body>
    <div class="alert">
        <h2>⚠️ Test Alert</h2>
    </div>
    <div class="content">
        <p>This is a test system notification with HTML styling.</p>
        <p><strong>Test Details:</strong></p>
        <ul>
            <li>Test Suite: SendEmail Function</li>
            <li>Test Type: HTML Email</li>
            <li>Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</li>
        </ul>
    </div>
    <div class="footer">
        Sent by Azure Function Test Suite
    </div>
</body>
</html>
"@
    isHtml = $true
    saveToSentItems = $true
} -ShouldSucceed $true

# ===========================
# Invalid Test Cases
# ===========================
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "INVALID TEST CASES (Should Fail)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

Test-EmailFunction -TestName "Missing Required Field (To)" -Payload @{
    subject = "Test"
    body = "This should fail - no recipient"
} -ShouldSucceed $false

Test-EmailFunction -TestName "Invalid Email Format" -Payload @{
    to = "not-a-valid-email"
    subject = "Test"
    body = "This should fail - invalid email format"
} -ShouldSucceed $false

Test-EmailFunction -TestName "Empty Email Address" -Payload @{
    to = ""
    subject = "Test"
    body = "This should fail - empty email"
} -ShouldSucceed $false

Test-EmailFunction -TestName "Null Email Address" -Payload @{
    to = $null
    subject = "Test"
    body = "This should fail - null email"
} -ShouldSucceed $false

# Test empty body (should fail due to API restriction)
Write-Host "📧 Test: Empty Request Body" -ForegroundColor Yellow
$totalTests++
try {
    $result = Invoke-RestMethod -Uri $FunctionUrl -Method Post -Body "" -ContentType "application/json"
    Write-Host "   ❌ FAILED - Expected failure but succeeded" -ForegroundColor Red
    $failedTests++
}
catch {
    Write-Host "   ✅ PASSED - Failed as expected (empty body)" -ForegroundColor Green
    $passedTests++
}
Write-Host ""

# ===========================
# Test Summary
# ===========================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📊 TEST SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Tests:  $totalTests" -ForegroundColor White
Write-Host "Passed:       $passedTests" -ForegroundColor Green
Write-Host "Failed:       $failedTests" -ForegroundColor Red
Write-Host ""

$successRate = [math]::Round(($passedTests / $totalTests) * 100, 2)
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -eq 100) { "Green" } elseif ($successRate -ge 80) { "Yellow" } else { "Red" })
Write-Host ""

if ($failedTests -eq 0) {
    Write-Host "🎉 All tests passed! Your function is working correctly." -ForegroundColor Green
} else {
    Write-Host "⚠️  Some tests failed. Please review the results above." -ForegroundColor Yellow
}

Write-Host "========================================" -ForegroundColor Cyan
