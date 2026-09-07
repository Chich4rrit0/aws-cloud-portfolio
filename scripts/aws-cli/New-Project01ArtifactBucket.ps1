[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProfileName,

    [string]$Region = 'us-east-1',

    [switch]$Execute
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-AwsJson {
    param([string[]]$Arguments)

    $rawOutput = & aws @Arguments '--profile' $ProfileName '--region' $Region '--no-cli-pager' '--output' 'json'
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI command failed: aws $($Arguments -join ' ')"
    }
    return $rawOutput | ConvertFrom-Json
}

function Invoke-AwsCommand {
    param([string[]]$Arguments)

    $output = & aws @Arguments '--profile' $ProfileName '--region' $Region '--no-cli-pager' 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI command failed: aws $($Arguments -join ' ')`n$($output | Out-String)"
    }
}

if (-not $Execute) {
    [PSCustomObject]@{
        Mode                  = 'Dry run - no S3 bucket will be created'
        BucketNamePattern     = "portfolio-p01-artifacts-<account-id>-$Region"
        PublicAccess          = 'Blocked'
        Encryption            = 'SSE-S3 (AES256)'
        ObjectOwnership       = 'BucketOwnerEnforced'
        Versioning            = 'Disabled initially to minimize retained artifacts'
    }
    return
}

$accountId = (Invoke-AwsJson -Arguments @('sts', 'get-caller-identity')).Account
$bucketName = "portfolio-p01-artifacts-$accountId-$Region"
$buckets = Invoke-AwsJson -Arguments @('s3api', 'list-buckets')
$exists = @($buckets.Buckets | Where-Object { $_.Name -eq $bucketName }).Count -eq 1

if (-not $exists) {
    Invoke-AwsCommand -Arguments @('s3api', 'create-bucket', '--bucket', $bucketName)
    Write-Host "Created private artifact bucket $bucketName."
}
else {
    Write-Host "Reusing artifact bucket $bucketName."
}

Invoke-AwsCommand -Arguments @(
    's3api', 'put-public-access-block',
    '--bucket', $bucketName,
    '--public-access-block-configuration', 'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true'
)
Invoke-AwsCommand -Arguments @(
    's3api', 'put-bucket-ownership-controls',
    '--bucket', $bucketName,
    '--ownership-controls', 'Rules=[{ObjectOwnership=BucketOwnerEnforced}]'
)
Invoke-AwsCommand -Arguments @(
    's3api', 'put-bucket-encryption',
    '--bucket', $bucketName,
    '--server-side-encryption-configuration', 'Rules=[{ApplyServerSideEncryptionByDefault={SSEAlgorithm=AES256}}]'
)
Invoke-AwsCommand -Arguments @(
    's3api', 'put-bucket-tagging',
    '--bucket', $bucketName,
    '--tagging', 'TagSet=[{Key=Name,Value=portfolio-p01-artifacts},{Key=Project,Value=aws-cloud-portfolio},{Key=ProjectNumber,Value=01},{Key=Environment,Value=development},{Key=ManagedBy,Value=aws-cli}]'
)

[PSCustomObject]@{
    BucketName          = $bucketName
    PublicAccessBlocked = $true
    Encryption          = 'AES256'
    ObjectOwnership     = 'BucketOwnerEnforced'
    VersioningEnabled   = $false
}
