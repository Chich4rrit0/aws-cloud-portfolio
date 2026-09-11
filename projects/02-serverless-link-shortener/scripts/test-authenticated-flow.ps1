[CmdletBinding()]
param(
    [Parameter()]
    [string]$Profile = 'portfolio-root-temp',

    [Parameter()]
    [string]$Region = 'us-east-1',

    [Parameter()]
    [string]$Username = 'portfolio-admin',

    [Parameter()]
    [securestring]$Password
)

$ErrorActionPreference = 'Stop'

function Invoke-Aws {
    param([Parameter(Mandatory)][string[]]$Arguments)

    $result = & aws --profile $Profile --region $Region --no-cli-pager @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI failed: aws $($Arguments[0..1] -join ' ')"
    }
    return $result
}

if ($null -eq $Password) {
    $Password = Read-Host 'Cognito password' -AsSecureString
}

$passwordBstr = [IntPtr]::Zero
$plainPassword = $null
$accessToken = $null
$shortCode = $null

try {
    $userPoolId = (Invoke-Aws -Arguments @(
        'cognito-idp', 'list-user-pools', '--max-results', '60',
        '--query', "UserPools[?Name=='portfolio-p02-admins'].Id | [0]", '--output', 'text'
    )).Trim()
    if ([string]::IsNullOrWhiteSpace($userPoolId) -or $userPoolId -eq 'None') {
        throw 'The expected Cognito User Pool was not found.'
    }

    $appClientId = (Invoke-Aws -Arguments @(
        'cognito-idp', 'list-user-pool-clients', '--user-pool-id', $userPoolId, '--max-results', '60',
        '--query', "UserPoolClients[?ClientName=='portfolio-p02-api-client'].ClientId | [0]", '--output', 'text'
    )).Trim()
    if ([string]::IsNullOrWhiteSpace($appClientId) -or $appClientId -eq 'None') {
        throw 'The expected Cognito app client was not found.'
    }

    $apiId = (Invoke-Aws -Arguments @(
        'apigatewayv2', 'get-apis',
        '--query', "Items[?Name=='portfolio-p02-link-shortener-api'].ApiId | [0]", '--output', 'text'
    )).Trim()
    if ([string]::IsNullOrWhiteSpace($apiId) -or $apiId -eq 'None') {
        throw 'The expected HTTP API was not found.'
    }

    $passwordBstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordBstr)
    # PowerShell 5 removes JSON quotes when passing an in-memory JSON string to a native executable.
    # AWS CLI shorthand preserves this single argument without writing the password to disk.
    $authParameters = "USERNAME=$Username,PASSWORD=$plainPassword"
    $authResult = (Invoke-Aws -Arguments @(
        'cognito-idp', 'initiate-auth', '--auth-flow', 'USER_PASSWORD_AUTH',
        '--client-id', $appClientId, '--auth-parameters', $authParameters, '--output', 'json'
    ) | ConvertFrom-Json).AuthenticationResult
    $accessToken = $authResult.AccessToken
    if ([string]::IsNullOrWhiteSpace($accessToken)) {
        throw 'Cognito did not return an access token.'
    }

    $baseUrl = "https://$apiId.execute-api.$Region.amazonaws.com"
    $headers = @{ Authorization = "Bearer $accessToken" }
    $requestBody = @{ url = 'https://example.com/portfolio-validation' } | ConvertTo-Json -Compress
    $createdLink = Invoke-RestMethod -Method Post -Uri "$baseUrl/urls" -Headers $headers `
        -ContentType 'application/json' -Body $requestBody
    $shortCode = $createdLink.shortCode
    if ($createdLink.shortUrlPath -ne "/r/$shortCode" -or $shortCode -notmatch '^[A-Za-z0-9]{8}$') {
        throw 'The API response did not contain a valid short link.'
    }

    $redirectStatus = & curl.exe --silent --output NUL --write-out '%{http_code}' "$baseUrl/r/$shortCode"
    if ($LASTEXITCODE -ne 0 -or $redirectStatus -ne '302') {
        throw 'The public redirect did not return HTTP 302.'
    }

    $deleteStatus = & curl.exe --silent --output NUL --write-out '%{http_code}' --request DELETE `
        --header "Authorization: Bearer $accessToken" "$baseUrl/urls/$shortCode"
    if ($LASTEXITCODE -ne 0 -or $deleteStatus -ne '204') {
        throw 'The authenticated delete did not return HTTP 204.'
    }

    # Avoid inline JSON here: PowerShell 5 removes its quotes before AWS CLI receives it.
    $dynamoDbKey = "shortCode={S=$shortCode}"
    $remainingCode = (Invoke-Aws -Arguments @(
        'dynamodb', 'get-item', '--table-name', 'portfolio-p02-links',
        '--key', $dynamoDbKey,
        '--query', 'Item.shortCode.S', '--output', 'text'
    )).Trim()
    if (-not [string]::IsNullOrWhiteSpace($remainingCode) -and $remainingCode -ne 'None') {
        throw 'The test item still exists in DynamoDB after deletion.'
    }

    Write-Output 'Authenticated validation completed: create (201), redirect (302), delete (204), and DynamoDB cleanup verified.'
}
finally {
    if ($passwordBstr -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordBstr)
    }
    $plainPassword = $null
    $accessToken = $null
    $shortCode = $null
    $Password = $null
}
