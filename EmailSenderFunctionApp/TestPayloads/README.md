# Test Payloads for SendEmail Azure Function

## How to Test

### Option 1: Using PowerShell (Recommended)
```powershell
# Replace with your function URL and key
$functionUrl = "http://localhost:7071/api/SendEmail"  # or your Azure URL
$functionKey = "your-function-key-here"  # not needed for local testing

# Test 1: Basic Text Email
$body = @{
    to = "recipient@example.com"
    subject = "Test Email from Azure Function"
    body = "This is a test email sent from Azure Function using Microsoft Graph API."
    isHtml = $false
    saveToSentItems = $false
} | ConvertTo-Json

Invoke-RestMethod -Uri $functionUrl -Method Post -Body $body -ContentType "application/json"

# Test 2: HTML Email
$body = @{
    to = "recipient@example.com"
    subject = "HTML Test Email"
    body = "<html><body><h1>Hello!</h1><p>This is a <strong>test</strong>.</p></body></html>"
    isHtml = $true
    saveToSentItems = $true
} | ConvertTo-Json

Invoke-RestMethod -Uri $functionUrl -Method Post -Body $body -ContentType "application/json"

# Test 3: Minimal Email (only required field)
$body = @{
    to = "recipient@example.com"
} | ConvertTo-Json

Invoke-RestMethod -Uri $functionUrl -Method Post -Body $body -ContentType "application/json"
```

### Option 2: Using cURL
```bash
# Basic Text Email
curl -X POST http://localhost:7071/api/SendEmail \
  -H "Content-Type: application/json" \
  -d '{
    "to": "recipient@example.com",
    "subject": "Test Email",
    "body": "This is a test",
    "isHtml": false,
    "saveToSentItems": false
  }'

# HTML Email
curl -X POST http://localhost:7071/api/SendEmail \
  -H "Content-Type: application/json" \
  -d '{
    "to": "recipient@example.com",
    "subject": "HTML Email",
    "body": "<h1>Hello</h1><p>Test</p>",
    "isHtml": true,
    "saveToSentItems": true
  }'
```

### Option 3: Azure Portal (Testing on Azure)
1. Go to your Function App in Azure Portal
2. Select your `SendEmail` function
3. Click **"Test/Run"**
4. Paste one of the payloads below
5. Click **Run**

---

## Valid Test Payloads

### 1. Basic Text Email ✅
```json
{
  "to": "recipient@example.com",
  "subject": "Test Email from Azure Function",
  "body": "This is a test email sent from Azure Function using Microsoft Graph API.",
  "isHtml": false,
  "saveToSentItems": false
}
```

### 2. HTML Email ✅
```json
{
  "to": "recipient@example.com",
  "subject": "HTML Test Email",
  "body": "<html><body><h1>Hello!</h1><p>This is a <strong>test email</strong> with <em>HTML formatting</em>.</p></body></html>",
  "isHtml": true,
  "saveToSentItems": true
}
```

### 3. Minimal Email (only required field) ✅
```json
{
  "to": "recipient@example.com"
}
```

### 4. Email with Subject, No Body ✅
```json
{
  "to": "recipient@example.com",
  "subject": "Email with no body content"
}
```

### 5. Professional Notification Email ✅
```json
{
  "to": "recipient@example.com",
  "subject": "Monthly Report - Azure Function Status",
  "body": "Dear Team,\n\nThis is your monthly status report.\n\nKey Metrics:\n- Emails sent: 1,234\n- Success rate: 99.8%\n- Average response time: 1.2s\n\nBest regards,\nAzure Function Bot",
  "isHtml": false,
  "saveToSentItems": true
}
```

### 6. Styled HTML Alert Email ✅
```json
{
  "to": "recipient@example.com",
  "subject": "System Alert: Action Required",
  "body": "<!DOCTYPE html><html><head><style>body{font-family:Arial,sans-serif;} .alert{background-color:#f44336;color:white;padding:20px;border-radius:5px;} .content{padding:20px;}</style></head><body><div class='alert'><h2>⚠️ Alert</h2></div><div class='content'><p>This is a system notification.</p><p>Please review the following:</p><ul><li>Item requiring attention</li><li>Action needed by end of day</li></ul></div></body></html>",
  "isHtml": true,
  "saveToSentItems": true
}
```

---

## Invalid Test Payloads (Should Fail)

### 1. Missing Required Field ❌
**Expected Error:** `Email recipient is required`
```json
{
  "subject": "Test",
  "body": "This should fail"
}
```

### 2. Invalid Email Format ❌
**Expected Error:** `Invalid email address format`
```json
{
  "to": "not-an-email",
  "subject": "Test",
  "body": "This should fail"
}
```

### 3. Empty Email Address ❌
**Expected Error:** `Email recipient is required`
```json
{
  "to": "",
  "subject": "Test",
  "body": "This should fail"
}
```

### 4. Empty Request Body ❌
**Expected Error:** `Request body is empty`
```json

```

### 5. Invalid JSON ❌
**Expected Error:** `Invalid JSON format`
```
{ this is not valid json }
```

---

## Expected Responses

### Success Response (200 OK)
```json
{
  "success": true,
  "message": "Email sent successfully",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

### Validation Error (400 Bad Request)
```json
{
  "success": false,
  "error": "Email recipient is required",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

### Server Error (500 Internal Server Error)
```json
{
  "success": false,
  "error": "Error message details",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

---

## Testing Locally

1. **Start the Function:**
   ```powershell
   func start
   ```

2. **Function will be available at:**
   ```
   http://localhost:7071/api/SendEmail
   ```

3. **Use any of the test methods above**

---

## Testing in Azure

1. **Get your Function URL:**
   - Go to Azure Portal → Function App → Functions → SendEmail
   - Click "Get Function URL"
   - Copy the URL (includes the function key)

2. **Replace localhost with your Azure URL:**
   ```
   https://your-app.azurewebsites.net/api/SendEmail?code=your-function-key
   ```

3. **Send test requests using the payloads above**

---

## Quick Test Script

Save this as `test-email-function.ps1`:

```powershell
param(
    [Parameter(Mandatory=$false)]
    [string]$FunctionUrl = "http://localhost:7071/api/SendEmail",
    
    [Parameter(Mandatory=$true)]
    [string]$RecipientEmail
)

Write-Host "🧪 Testing SendEmail Function" -ForegroundColor Cyan
Write-Host "URL: $FunctionUrl" -ForegroundColor Gray
Write-Host ""

# Test 1: Basic Email
Write-Host "Test 1: Basic Text Email..." -ForegroundColor Yellow
$payload1 = @{
    to = $RecipientEmail
    subject = "Test Email - Basic"
    body = "This is a basic test email."
    isHtml = $false
    saveToSentItems = $false
} | ConvertTo-Json

try {
    $result1 = Invoke-RestMethod -Uri $FunctionUrl -Method Post -Body $payload1 -ContentType "application/json"
    Write-Host "✅ SUCCESS: $($result1.message)" -ForegroundColor Green
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 2: HTML Email
Write-Host "Test 2: HTML Email..." -ForegroundColor Yellow
$payload2 = @{
    to = $RecipientEmail
    subject = "Test Email - HTML"
    body = "<h1>Hello!</h1><p>This is an <strong>HTML</strong> test.</p>"
    isHtml = $true
    saveToSentItems = $true
} | ConvertTo-Json

try {
    $result2 = Invoke-RestMethod -Uri $FunctionUrl -Method Post -Body $payload2 -ContentType "application/json"
    Write-Host "✅ SUCCESS: $($result2.message)" -ForegroundColor Green
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 3: Invalid Email (should fail)
Write-Host "Test 3: Invalid Email (expected to fail)..." -ForegroundColor Yellow
$payload3 = @{
    to = "not-an-email"
    subject = "Test"
} | ConvertTo-Json

try {
    $result3 = Invoke-RestMethod -Uri $FunctionUrl -Method Post -Body $payload3 -ContentType "application/json"
    Write-Host "❌ UNEXPECTED SUCCESS" -ForegroundColor Red
} catch {
    Write-Host "✅ EXPECTED FAILURE: Validation working correctly" -ForegroundColor Green
}
Write-Host ""

Write-Host "🎉 Testing complete!" -ForegroundColor Cyan
```

**Usage:**
```powershell
.\test-email-function.ps1 -RecipientEmail "your@email.com"
# Or for Azure:
.\test-email-function.ps1 -FunctionUrl "https://your-app.azurewebsites.net/api/SendEmail?code=xxx" -RecipientEmail "your@email.com"
```
