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
$policyName = 'Project01ReadDeploymentArtifacts'

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
        Mode                  = 'Dry run - no IAM policy will be changed'
        RoleName              = $roleName
        AllowedObjectPattern  = 'arn:aws:s3:::portfolio-p01-artifacts-<account-id>-<region>/releases/*'
        AllowedActions        = 's3:GetObject only'
    }
    return
}

$accountId = (Invoke-AwsJson -Arguments @('sts', 'get-caller-identity')).Account
$bucketName = "portfolio-p01-artifacts-$accountId-$Region"
$policy = @{
    Version = '2012-10-17'
    Statement = @(
        @{
            Sid = 'ReadOnlyProject01ReleaseArtifacts'
            Effect = 'Allow'
            Action = @('s3:GetObject')
            Resource = "arn:aws:s3:::$bucketName/releases/*"
        }
    )
} | ConvertTo-Json -Compress -Depth 5

$output = & aws iam put-role-policy '--role-name' $roleName '--policy-name' $policyName '--policy-document' $policy '--profile' $ProfileName '--region' $Region '--no-cli-pager' 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "Could not update the application EC2 artifact policy. $($output | Out-String)"
}

[PSCustomObject]@{
    RoleName              = $roleName
    PolicyName            = $policyName
    AllowedObjectPattern  = "s3://$bucketName/releases/*"
    AllowedActions        = 's3:GetObject only'
}
