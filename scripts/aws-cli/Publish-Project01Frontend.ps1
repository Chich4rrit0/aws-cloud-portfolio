[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProfileName,

    [string]$Region = 'us-east-1',

    [switch]$Execute
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$frontendSource = Join-Path $PSScriptRoot '..\..\projects\01-web-task-manager\frontend'
$bucketPrefix = 'portfolio-p01-frontend'
$distributionComment = 'Project 01 Task Manager frontend and API delivery'

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
        Mode = 'Dry run - no frontend files will be uploaded or cache invalidation created'
        Source = $frontendSource
        Destination = 'private Project 01 frontend bucket'
        CacheControl = 'no-cache, no-store, must-revalidate'
        Invalidation = '/* on the Project 01 CloudFront distribution'
    }
    return
}

if (-not (Test-Path -LiteralPath $frontendSource -PathType Container)) {
    throw 'The frontend source directory does not exist.'
}

$accountId = (Invoke-AwsJson -Arguments @('sts', 'get-caller-identity')).Account
$bucketName = "$bucketPrefix-$accountId-$Region"
$distributions = Invoke-AwsJson -Arguments @('cloudfront', 'list-distributions')
$distribution = @($distributions.DistributionList.Items | Where-Object { $_.Comment -eq $distributionComment } | Select-Object -First 1)[0]
if ($null -eq $distribution) { throw 'The Project 01 CloudFront distribution was not found.' }

$syncOutput = & aws s3 sync $frontendSource "s3://$bucketName" '--cache-control' 'no-cache, no-store, must-revalidate' '--profile' $ProfileName '--region' $Region '--no-cli-pager' 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "Could not publish the frontend: $($syncOutput | Out-String)"
}

$invalidation = Invoke-AwsJson -Arguments @('cloudfront', 'create-invalidation', '--distribution-id', $distribution.Id, '--paths', '/*')

[PSCustomObject]@{
    FrontendBucket = $bucketName
    DistributionId = $distribution.Id
    InvalidationId = $invalidation.Invalidation.Id
    InvalidationStatus = $invalidation.Invalidation.Status
    CacheControl = 'no-cache, no-store, must-revalidate'
}
