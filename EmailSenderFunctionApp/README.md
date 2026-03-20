# Email Sender Function App

Azure Function App that sends emails using Microsoft Graph API with Managed Identity authentication.

## Prerequisites

1. **Azure Resources**:
   - Azure Function App with Managed Identity enabled
   - Microsoft 365 mailbox (sender)
   - Azure AD App Registration with appropriate permissions (if not using application permissions directly on Managed Identity)

2. **Microsoft Graph API Permissions**:
   The Managed Identity needs the following application permissions:
   - `Mail.Send` - Send mail as any user

## Configuration

### Local Development

1. Update `local.settings.json`:
   ```json
   {
     "Values": {
       "SENDER_MAILBOX": "sender@yourcompany.com"
     }
   }
   ```

2. Login to Azure CLI:
   ```bash
   az login
   ```

### Azure Deployment

1. **Enable Managed Identity** on your Function App:
   ```bash
   az functionapp identity assign --name <function-app-name> --resource-group <resource-group>
   ```

2. **Grant Microsoft Graph Permissions**:
   ```bash
   # Get the Managed Identity Object ID
   $objectId = az functionapp identity show --name <function-app-name> --resource-group <resource-group> --query principalId -o tsv

   # Get Microsoft Graph Service Principal ID
   $graphId = az ad sp list --query "[?appId=='00000003-0000-0000-c000-000000000000'].id" -o tsv

   # Get Mail.Send role ID
   $mailSendRoleId = az ad sp show --id $graphId --query "appRoles[?value=='Mail.Send'].id" -o tsv

   # Assign the role
   az rest --method POST --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$graphId/appRoleAssignments" --body "{'principalId':'$objectId','resourceId':'$graphId','appRoleId':'$mailSendRoleId'}"
   ```

3. **Set Application Settings**:
   ```bash
   az functionapp config appsettings set --name <function-app-name> --resource-group <resource-group> --settings SENDER_MAILBOX=sender@yourcompany.com
   ```

## Usage

### Send Email Request

**Endpoint**: `POST /api/SendEmail`

**Request Body**:
```json
{
  "to": "recipient@example.com",
  "subject": "Test Email",
  "body": "This is a test email sent via Azure Function with Managed Identity",
  "isHtml": false,
  "saveToSentItems": false
}
```

**Example using cURL**:
```bash
curl -X POST "https://<function-app-name>.azurewebsites.net/api/SendEmail?code=<function-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "recipient@example.com",
    "subject": "Test Email",
    "body": "Hello from Azure Functions!",
    "isHtml": false
  }'
```

**Response (Success)**:
```json
{
  "success": true,
  "message": "Email sent successfully",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

## Important Notes

1. **Sender Mailbox**: Must be a valid Microsoft 365/Exchange Online mailbox, NOT a Gmail or other external email address.

2. **Managed Identity**: In Azure, the Function uses Managed Identity. Locally, it falls back to Azure CLI credentials.

3. **Permissions**: The Managed Identity must have `Mail.Send` application permission granted in Azure AD.

4. **Testing Locally**: Ensure you're logged in with Azure CLI (`az login`) with an account that has appropriate permissions.

## Troubleshooting

- **401 Unauthorized**: Check that Managed Identity has correct Graph API permissions
- **403 Forbidden**: Verify the sender mailbox exists and the identity has rights to send from it
- **SENDER_MAILBOX not configured**: Set the environment variable in local.settings.json or Azure App Settings
