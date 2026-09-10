[CmdletBinding()]
param(
    [Parameter()]
    [string]$Profile = 'portfolio-root-temp',

    [Parameter()]
    [string]$Region = 'us-east-1'
)

$ErrorActionPreference = 'Stop'

$userPoolName = 'portfolio-p02-admins'
$appClientName = 'portfolio-p02-api-client'
$tags = 'Project=aws-cloud-portfolio,ProjectNumber=02,Environment=lab,ManagedBy=aws-cli'

function Invoke-Aws {
    param([Parameter(Mandatory)][string[]]$Arguments)

    & aws --profile $Profile --region $Region --no-cli-pager @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI failed: aws $($Arguments -join ' ')"
    }
}

$userPoolId = (& aws --profile $Profile --region $Region --no-cli-pager cognito-idp create-user-pool `
    --pool-name $userPoolName `
    --user-pool-tier 'LITE' `
    --admin-create-user-config 'AllowAdminCreateUserOnly=true' `
    --policies 'PasswordPolicy={MinimumLength=14,RequireUppercase=true,RequireLowercase=true,RequireNumbers=true,RequireSymbols=true,TemporaryPasswordValidityDays=1}' `
    --mfa-configuration 'OFF' `
    --username-configuration 'CaseSensitive=false' `
    --deletion-protection 'INACTIVE' `
    --user-pool-tags $tags `
    --query 'UserPool.Id' `
    --output text)
if ($LASTEXITCODE -ne 0) {
    throw "Could not create Cognito User Pool: $userPoolName"
}

$clientId = (& aws --profile $Profile --region $Region --no-cli-pager cognito-idp create-user-pool-client `
    --user-pool-id $userPoolId `
    --client-name $appClientName `
    --no-generate-secret `
    --explicit-auth-flows 'ALLOW_USER_PASSWORD_AUTH' 'ALLOW_REFRESH_TOKEN_AUTH' `
    --prevent-user-existence-errors 'ENABLED' `
    --query 'UserPoolClient.ClientId' `
    --output text)
if ($LASTEXITCODE -ne 0) {
    throw "Could not create Cognito app client: $appClientName"
}

Write-Output 'Project 02 Cognito foundation created successfully without users or passwords.'
