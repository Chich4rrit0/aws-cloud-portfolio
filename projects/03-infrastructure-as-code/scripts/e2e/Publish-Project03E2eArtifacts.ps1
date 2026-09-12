[CmdletBinding()]
param(
    [string]$ProfileName,
    [string]$Region = 'us-east-1',
    [string]$ArtifactBucketName,
    [string]$FrontendBucketName,
    [switch]$Execute
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
$projectRoot = Join-Path $repositoryRoot 'projects\01-web-task-manager'
$appSource = Join-Path $projectRoot 'app'
$frontendSource = Join-Path $projectRoot 'frontend'
$commit = (git -C $repositoryRoot rev-parse --short HEAD).Trim()
$objectKey = "releases/task-manager-$commit.zip"

if (-not $Execute) {
    [PSCustomObject]@{
        Mode = 'Dry run - no ZIP, S3 upload or invalidation is performed'
        BackendSource = $appSource
        FrontendSource = $frontendSource
        ObjectKey = $objectKey
        RequiredAtExecute = 'ProfileName, ArtifactBucketName and FrontendBucketName from E2E Foundation outputs'
        Excluded = 'node_modules, .env and .env.local'
    }
    return
}

if ([string]::IsNullOrWhiteSpace($ProfileName) -or [string]::IsNullOrWhiteSpace($ArtifactBucketName) -or [string]::IsNullOrWhiteSpace($FrontendBucketName)) {
    throw 'ProfileName, ArtifactBucketName and FrontendBucketName are required with -Execute.'
}
if (-not (Test-Path -LiteralPath $appSource -PathType Container) -or -not (Test-Path -LiteralPath $frontendSource -PathType Container)) {
    throw 'Expected Project 01 source directories were not found.'
}

$staging = Join-Path ([System.IO.Path]::GetTempPath()) "project-03-e2e-$commit"
$archive = Join-Path $staging "task-manager-$commit.zip"
try {
    New-Item -ItemType Directory -Force -Path (Join-Path $staging 'app') | Out-Null
    Get-ChildItem -LiteralPath $appSource -Force | Where-Object { $_.Name -notin @('node_modules', '.env', '.env.local') } | Copy-Item -Destination (Join-Path $staging 'app') -Recurse -Force
    Compress-Archive -Path (Join-Path $staging 'app') -DestinationPath $archive -Force
    & aws s3api put-object --bucket $ArtifactBucketName --key $objectKey --body $archive --server-side-encryption AES256 --profile $ProfileName --region $Region --no-cli-pager | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Artifact upload failed.' }
    & aws s3 sync $frontendSource "s3://$FrontendBucketName" --cache-control 'no-cache, no-store, must-revalidate' --profile $ProfileName --region $Region --no-cli-pager
    if ($LASTEXITCODE -ne 0) { throw 'Frontend upload failed.' }
    [PSCustomObject]@{ ObjectKey = $objectKey; Sha256 = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash; FrontendBucket = $FrontendBucketName }
}
finally {
    if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }
}
