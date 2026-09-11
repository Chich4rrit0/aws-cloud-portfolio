[CmdletBinding()]
param(
    [Parameter()]
    [string]$Profile = 'portfolio-root-temp',

    [Parameter()]
    [string]$Region = 'us-east-1'
)

$ErrorActionPreference = 'Stop'

$apiName = 'portfolio-p02-link-shortener-api'
$functionName = 'portfolio-p02-link-shortener'
$userPoolName = 'portfolio-p02-admins'
$appClientName = 'portfolio-p02-api-client'
$authorizerName = 'portfolio-p02-cognito-jwt'
$permissionStatementId = 'apigateway-invoke-project-02'
$apiTags = 'Project=aws-cloud-portfolio,ProjectNumber=02,Environment=lab,ManagedBy=aws-cli'

function Invoke-Aws {
    param([Parameter(Mandatory)][string[]]$Arguments)

    & aws --profile $Profile --region $Region --no-cli-pager @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI failed: aws $($Arguments -join ' ')"
    }
}

$existingApiId = (& aws --profile $Profile --region $Region --no-cli-pager apigatewayv2 get-apis `
    --query "Items[?Name=='$apiName'].ApiId | [0]" --output text).Trim()
if ($LASTEXITCODE -ne 0) {
    throw 'Could not inspect existing HTTP APIs.'
}
if (-not [string]::IsNullOrWhiteSpace($existingApiId) -and $existingApiId -ne 'None') {
    throw "HTTP API already exists: $apiName. This creation script intentionally does not modify an existing API."
}

$functionArn = (& aws --profile $Profile --region $Region --no-cli-pager lambda get-function `
    --function-name $functionName --query 'Configuration.FunctionArn' --output text).Trim()
if ($LASTEXITCODE -ne 0) {
    throw "Required Lambda function was not found: $functionName"
}

$userPoolId = (& aws --profile $Profile --region $Region --no-cli-pager cognito-idp list-user-pools `
    --max-results 60 --query "UserPools[?Name=='$userPoolName'].Id | [0]" --output text).Trim()
if ([string]::IsNullOrWhiteSpace($userPoolId) -or $userPoolId -eq 'None') {
    throw "Required Cognito User Pool was not found: $userPoolName"
}

$appClientId = (& aws --profile $Profile --region $Region --no-cli-pager cognito-idp list-user-pool-clients `
    --user-pool-id $userPoolId --max-results 60 --query "UserPoolClients[?ClientName=='$appClientName'].ClientId | [0]" --output text).Trim()
if ([string]::IsNullOrWhiteSpace($appClientId) -or $appClientId -eq 'None') {
    throw "Required Cognito app client was not found: $appClientName"
}

$accountId = (& aws --profile $Profile --region $Region --no-cli-pager sts get-caller-identity `
    --query 'Account' --output text).Trim()
if ($LASTEXITCODE -ne 0) {
    throw 'Could not retrieve AWS account context.'
}

$apiId = (& aws --profile $Profile --region $Region --no-cli-pager apigatewayv2 create-api `
    --name $apiName --protocol-type HTTP --tags $apiTags --query 'ApiId' --output text).Trim()
if ($LASTEXITCODE -ne 0) {
    throw "Could not create HTTP API: $apiName"
}

$integrationId = (& aws --profile $Profile --region $Region --no-cli-pager apigatewayv2 create-integration `
    --api-id $apiId --integration-type AWS_PROXY --integration-uri $functionArn `
    --payload-format-version '2.0' --timeout-in-millis 3000 --query 'IntegrationId' --output text).Trim()
if ($LASTEXITCODE -ne 0) {
    throw 'Could not create Lambda integration.'
}

$issuer = "https://cognito-idp.$Region.amazonaws.com/$userPoolId"
$authorizerId = (& aws --profile $Profile --region $Region --no-cli-pager apigatewayv2 create-authorizer `
    --api-id $apiId --name $authorizerName --authorizer-type JWT `
    --identity-source '$request.header.Authorization' --jwt-configuration "Audience=$appClientId,Issuer=$issuer" `
    --query 'AuthorizerId' --output text).Trim()
if ($LASTEXITCODE -ne 0) {
    throw 'Could not create the JWT authorizer.'
}

Invoke-Aws -Arguments @(
    'apigatewayv2', 'create-route', '--api-id', $apiId,
    '--route-key', 'GET /r/{code}', '--authorization-type', 'NONE',
    '--target', "integrations/$integrationId"
)
Invoke-Aws -Arguments @(
    'apigatewayv2', 'create-route', '--api-id', $apiId,
    '--route-key', 'POST /urls', '--authorization-type', 'JWT',
    '--authorizer-id', $authorizerId, '--target', "integrations/$integrationId"
)
Invoke-Aws -Arguments @(
    'apigatewayv2', 'create-route', '--api-id', $apiId,
    '--route-key', 'DELETE /urls/{code}', '--authorization-type', 'JWT',
    '--authorizer-id', $authorizerId, '--target', "integrations/$integrationId"
)
Invoke-Aws -Arguments @(
    'apigatewayv2', 'create-stage', '--api-id', $apiId,
    '--stage-name', '$default', '--auto-deploy',
    '--default-route-settings', 'ThrottlingRateLimit=5,ThrottlingBurstLimit=10'
)

# The backtick preserves the literal $default stage name in PowerShell.
$sourceArn = "arn:aws:execute-api:${Region}:${accountId}:${apiId}/`$default/*"
Invoke-Aws -Arguments @(
    'lambda', 'add-permission', '--function-name', $functionName,
    '--statement-id', $permissionStatementId, '--action', 'lambda:InvokeFunction',
    '--principal', 'apigateway.amazonaws.com', '--source-arn', $sourceArn
)

Invoke-Aws -Arguments @(
    'lambda', 'delete-function-concurrency', '--function-name', $functionName
)

Write-Output 'Project 02 HTTP API created. Verify routes and Lambda permission before sending test traffic.'
