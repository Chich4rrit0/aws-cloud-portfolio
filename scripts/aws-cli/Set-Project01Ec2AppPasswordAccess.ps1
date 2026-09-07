[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProfileName,

    [string]$Region = 'us-east-1',

    [switch]$Execute
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$roleName = 'portfolio-p01-ec2-role'
$policyName = 'Project01ReadDatabasePassword'
$applicationPasswordPath = '/portfolio/project-01/database/app-password'

function Invoke-AwsJson {
    param([string[]]$Arguments)

    $rawOutput = & aws @Arguments '--profile' $ProfileName '--region' $Region '--no-cli-pager' '--output' 'json'
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI command failed: aws $($Arguments -join ' ')"
    }
    return $rawOutput | ConvertFrom-Json
}

if (-not $Execute) {
    [PSCustomObject]@{
        Mode                    = 'Dry run - no IAM policy will be changed'
        RoleName                = $roleName
        PolicyName              = $policyName
        AllowedParameterPath    = $applicationPasswordPath
        MasterPasswordAccess    = 'Removed when executed'
    }
    return
}

$accountId = (Invoke-AwsJson -Arguments @('sts', 'get-caller-identity')).Account
$policy = @{
    Version = '2012-10-17'
    Statement = @(
        @{
            Sid = 'ReadOnlyProject01ApplicationPassword'
            Effect = 'Allow'
            Action = @('ssm:GetParameter')
            Resource = "arn:aws:ssm:${Region}:${accountId}:parameter$applicationPasswordPath"
        }
    )
} | ConvertTo-Json -Compress -Depth 5

$output = & aws iam put-role-policy '--role-name' $roleName '--policy-name' $policyName '--policy-document' $policy '--profile' $ProfileName '--region' $Region '--no-cli-pager' 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "Could not update the application EC2 role policy. $($output | Out-String)"
}

[PSCustomObject]@{
    RoleName             = $roleName
    PolicyName           = $policyName
    AllowedParameterPath = $applicationPasswordPath
    MasterPasswordAccess = 'Removed'
}
