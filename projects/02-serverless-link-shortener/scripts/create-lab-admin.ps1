[CmdletBinding()]
param(
    [Parameter()]
    [string]$Profile = 'portfolio-root-temp',

    [Parameter()]
    [string]$Region = 'us-east-1'
)

$ErrorActionPreference = 'Stop'

$userPoolName = 'portfolio-p02-admins'
$username = 'portfolio-admin'

$userPoolId = (& aws --profile $Profile --region $Region --no-cli-pager cognito-idp list-user-pools `
    --max-results 60 `
    --query "UserPools[?Name=='$userPoolName'].Id | [0]" `
    --output text)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($userPoolId) -or $userPoolId -eq 'None') {
    throw "Could not resolve Cognito User Pool: $userPoolName"
}

& aws --profile $Profile --region $Region --no-cli-pager cognito-idp admin-create-user `
    --user-pool-id $userPoolId `
    --username $username `
    --message-action 'SUPPRESS' `
    --query 'User.[Username,UserStatus,Enabled]' `
    --output json
if ($LASTEXITCODE -ne 0) {
    throw "Could not create Cognito lab administrator: $username"
}

Write-Output 'Cognito lab administrator created without a delivered password.'
